from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import Optional
import uuid
import subprocess
import signal
import asyncio
from datetime import datetime
import pytz

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Global process tracker
ffmpeg_process = None

# Define Models
class StreamSettings(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    radio_url: str = "https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8"
    resolution: str = "720p"  # 540p, 720p, 1080p
    output_mode: str = "multicast"  # unicast, multicast, http
    unicast_ip: str = "127.0.0.1:5000"
    multicast_address: str = "239.255.0.1:5000"
    http_port: int = 8080
    font_size: int = 72
    font_color: str = "white"
    is_running: bool = False

class StreamSettingsUpdate(BaseModel):
    radio_url: Optional[str] = None
    resolution: Optional[str] = None
    output_mode: Optional[str] = None
    unicast_ip: Optional[str] = None
    multicast_address: Optional[str] = None
    http_port: Optional[int] = None
    font_size: Optional[int] = None
    font_color: Optional[str] = None

class StreamStatus(BaseModel):
    is_running: bool
    pid: Optional[int] = None
    message: str
    stream_url: Optional[str] = None

# Helper function to get resolution dimensions
def get_resolution_dimensions(resolution: str) -> str:
    resolutions = {
        "540p": "960x540",
        "720p": "1280x720",
        "1080p": "1920x1080"
    }
    return resolutions.get(resolution, "1280x720")

# Helper function to get server IP
def get_server_ip() -> str:
    import socket
    try:
        # Connect to external host to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

# Helper function to build FFmpeg command
def build_ffmpeg_command(settings: StreamSettings) -> list:
    resolution_dim = get_resolution_dimensions(settings.resolution)
    server_ip = get_server_ip()
    
    # Determine output URL based on mode
    if settings.output_mode == "multicast":
        output_url = f"udp://{settings.multicast_address}?pkt_size=1316"
    elif settings.output_mode == "http":
        output_url = f"http://{server_ip}:{settings.http_port}/stream.ts"
    else:
        # Unicast mode
        output_url = f"udp://{settings.unicast_ip}?pkt_size=1316"
    
    # Get current time for display (will update in real-time via FFmpeg)
    # Simple drawtext - no complex timezone stuff
    cmd = [
        '/usr/bin/ffmpeg',
        '-re',
        '-i', settings.radio_url,
        '-f', 'lavfi',
        '-i', f'color=c=black:s={resolution_dim}:r=25',
        '-filter_complex',
        # Simple 3-layer text overlay
        f"[1:v]drawtext=text='Reinier de Graaf Radio Server':"
        f"fontsize={int(settings.font_size * 0.7)}:"
        f"fontcolor={settings.font_color}:"
        f"x=(w-tw)/2:y=80:"
        f"box=1:boxcolor=black@0.7:boxborderw=10,"
        
        # Current date and time - using gmtime for reliability
        f"drawtext=text='%{{gmtime\\:%d-%m-%Y  %H\\:%M\\:%S}}':"
        f"fontsize={settings.font_size}:"
        f"fontcolor={settings.font_color}:"
        f"x=(w-tw)/2:y=(h-th)/2:"
        f"box=1:boxcolor=black@0.7:boxborderw=12,"
        
        f"drawtext=text='Delft, Nederland':"
        f"fontsize={int(settings.font_size * 0.6)}:"
        f"fontcolor={settings.font_color}:"
        f"x=(w-tw)/2:y=h-120:"
        f"box=1:boxcolor=black@0.7:boxborderw=10[v]",
        
        '-map', '[v]',
        '-map', '0:a',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-tune', 'zerolatency',
        '-b:v', '2M',
        '-maxrate', '2M',
        '-bufsize', '4M',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-f', 'mpegts',
        output_url
    ]
    
    return cmd

# Initialize default settings on startup
@app.on_event("startup")
async def startup_event():
    # Check if settings exist, if not create default
    existing = await db.stream_settings.find_one()
    if not existing:
        default_settings = StreamSettings()
        await db.stream_settings.insert_one(default_settings.dict())
        logger.info("Created default stream settings")

# API Routes
@api_router.get("/")
async def root():
    return {"message": "Reinier de Graaf Radio Server"}

@api_router.get("/settings", response_model=StreamSettings)
async def get_settings():
    settings = await db.stream_settings.find_one()
    if not settings:
        # Create default if not exists
        default_settings = StreamSettings()
        await db.stream_settings.insert_one(default_settings.dict())
        return default_settings
    return StreamSettings(**settings)

@api_router.post("/settings", response_model=StreamSettings)
async def update_settings(update: StreamSettingsUpdate):
    global ffmpeg_process
    
    # Get current settings
    current = await db.stream_settings.find_one()
    if not current:
        current = StreamSettings().dict()
    
    # Update only provided fields
    update_data = update.dict(exclude_unset=True)
    for key, value in update_data.items():
        current[key] = value
    
    # If stream is running, we should not update while running
    if current.get('is_running', False):
        raise HTTPException(
            status_code=400,
            detail="Kan instellingen niet bijwerken terwijl stream actief is. Stop eerst de stream."
        )
    
    # Update in database
    await db.stream_settings.delete_many({})
    updated_settings = StreamSettings(**current)
    await db.stream_settings.insert_one(updated_settings.dict())
    
    return updated_settings

@api_router.post("/start", response_model=StreamStatus)
async def start_stream():
    global ffmpeg_process
    
    # Check if already running
    if ffmpeg_process and ffmpeg_process.poll() is None:
        settings = await db.stream_settings.find_one()
        stream_url = get_stream_url(StreamSettings(**settings))
        return StreamStatus(
            is_running=True,
            pid=ffmpeg_process.pid,
            message="Stream is al actief",
            stream_url=stream_url
        )
    
    # Get settings
    settings_doc = await db.stream_settings.find_one()
    if not settings_doc:
        raise HTTPException(status_code=404, detail="Instellingen niet gevonden")
    
    settings = StreamSettings(**settings_doc)
    
    # Build FFmpeg command
    cmd = build_ffmpeg_command(settings)
    
    try:
        # Start FFmpeg process
        ffmpeg_process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid
        )
        
        # Update running status in database
        await db.stream_settings.update_one(
            {},
            {"$set": {"is_running": True}}
        )
        
        logger.info(f"Started FFmpeg stream with PID: {ffmpeg_process.pid}")
        logger.info(f"Command: {' '.join(cmd)}")
        
        stream_url = get_stream_url(settings)
        
        return StreamStatus(
            is_running=True,
            pid=ffmpeg_process.pid,
            message="Stream succesvol gestart",
            stream_url=stream_url
        )
    
    except Exception as e:
        logger.error(f"Failed to start stream: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Kan stream niet starten: {str(e)}")

@api_router.post("/stop", response_model=StreamStatus)
async def stop_stream():
    global ffmpeg_process
    
    if not ffmpeg_process or ffmpeg_process.poll() is not None:
        # Update database status
        await db.stream_settings.update_one(
            {},
            {"$set": {"is_running": False}}
        )
        return StreamStatus(
            is_running=False,
            pid=None,
            message="Stream is niet actief",
            stream_url=None
        )
    
    try:
        # Send SIGTERM to process group
        os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
        
        # Wait for process to terminate (with timeout)
        try:
            ffmpeg_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            # Force kill if not terminated
            os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGKILL)
            ffmpeg_process.wait()
        
        ffmpeg_process = None
        
        # Update database status
        await db.stream_settings.update_one(
            {},
            {"$set": {"is_running": False}}
        )
        
        logger.info("Stopped FFmpeg stream")
        
        return StreamStatus(
            is_running=False,
            pid=None,
            message="Stream succesvol gestopt",
            stream_url=None
        )
    
    except Exception as e:
        logger.error(f"Error stopping stream: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Kan stream niet stoppen: {str(e)}")

@api_router.get("/status", response_model=StreamStatus)
async def get_status():
    global ffmpeg_process
    
    # Check if process is still running
    is_running = ffmpeg_process is not None and ffmpeg_process.poll() is None
    
    # Get database status
    settings = await db.stream_settings.find_one()
    stream_url = None
    
    if settings:
        db_running = settings.get('is_running', False)
        
        # Sync database with actual process state
        if db_running != is_running:
            await db.stream_settings.update_one(
                {},
                {"$set": {"is_running": is_running}}
            )
        
        if is_running:
            stream_url = get_stream_url(StreamSettings(**settings))
    
    return StreamStatus(
        is_running=is_running,
        pid=ffmpeg_process.pid if is_running else None,
        message="Stream is actief" if is_running else "Stream is gestopt",
        stream_url=stream_url
    )

def get_stream_url(settings: StreamSettings) -> str:
    """Generate stream URL based on settings"""
    server_ip = get_server_ip()
    
    if settings.output_mode == "multicast":
        return f"udp://@{settings.multicast_address}"
    elif settings.output_mode == "http":
        return f"http://{server_ip}:{settings.http_port}/stream.ts"
    else:  # unicast
        return f"udp://@{settings.unicast_ip}"

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    global ffmpeg_process
    
    # Stop FFmpeg if running
    if ffmpeg_process and ffmpeg_process.poll() is None:
        try:
            os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
            ffmpeg_process.wait(timeout=5)
        except:
            pass
    
    client.close()