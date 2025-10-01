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
    output_mode: str = "unicast"  # unicast or multicast
    multicast_address: str = "239.255.0.1:5000"
    datetime_format: str = "%Y-%m-%d %H:%M:%S"
    is_running: bool = False

class StreamSettingsUpdate(BaseModel):
    radio_url: Optional[str] = None
    resolution: Optional[str] = None
    output_mode: Optional[str] = None
    multicast_address: Optional[str] = None
    datetime_format: Optional[str] = None

class StreamStatus(BaseModel):
    is_running: bool
    pid: Optional[int] = None
    message: str

# Helper function to get resolution dimensions
def get_resolution_dimensions(resolution: str) -> str:
    resolutions = {
        "540p": "960x540",
        "720p": "1280x720",
        "1080p": "1920x1080"
    }
    return resolutions.get(resolution, "1280x720")

# Helper function to build FFmpeg command
def build_ffmpeg_command(settings: StreamSettings) -> list:
    resolution_dim = get_resolution_dimensions(settings.resolution)
    
    # Output URL based on mode
    if settings.output_mode == "multicast":
        output_url = f"udp://{settings.multicast_address}?pkt_size=1316"
    else:
        # For unicast, we'll use a local file or stream
        output_url = f"udp://127.0.0.1:5000?pkt_size=1316"
    
    # Build FFmpeg command
    cmd = [
        'ffmpeg',
        '-re',  # Read input at native frame rate
        '-i', settings.radio_url,  # Input radio stream
        '-f', 'lavfi',
        '-i', f'color=c=black:s={resolution_dim}:r=25',  # Black background video
        '-filter_complex',
        f"[1:v]drawtext=text='%{{localtime\\:{settings.datetime_format}}}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=10[v]",
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
    return {"message": "Radio to Video Stream System"}

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
            detail="Cannot update settings while stream is running. Please stop the stream first."
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
        return StreamStatus(
            is_running=True,
            pid=ffmpeg_process.pid,
            message="Stream is already running"
        )
    
    # Get settings
    settings_doc = await db.stream_settings.find_one()
    if not settings_doc:
        raise HTTPException(status_code=404, detail="Settings not found")
    
    settings = StreamSettings(**settings_doc)
    
    # Build FFmpeg command
    cmd = build_ffmpeg_command(settings)
    
    try:
        # Start FFmpeg process
        ffmpeg_process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid  # Create new process group
        )
        
        # Update running status in database
        await db.stream_settings.update_one(
            {},
            {"$set": {"is_running": True}}
        )
        
        logger.info(f"Started FFmpeg stream with PID: {ffmpeg_process.pid}")
        logger.info(f"Command: {' '.join(cmd)}")
        
        return StreamStatus(
            is_running=True,
            pid=ffmpeg_process.pid,
            message="Stream started successfully"
        )
    
    except Exception as e:
        logger.error(f"Failed to start stream: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to start stream: {str(e)}")

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
            message="Stream is not running"
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
            message="Stream stopped successfully"
        )
    
    except Exception as e:
        logger.error(f"Error stopping stream: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to stop stream: {str(e)}")

@api_router.get("/status", response_model=StreamStatus)
async def get_status():
    global ffmpeg_process
    
    # Check if process is still running
    is_running = ffmpeg_process is not None and ffmpeg_process.poll() is None
    
    # Get database status
    settings = await db.stream_settings.find_one()
    if settings:
        db_running = settings.get('is_running', False)
        
        # Sync database with actual process state
        if db_running != is_running:
            await db.stream_settings.update_one(
                {},
                {"$set": {"is_running": is_running}}
            )
    
    return StreamStatus(
        is_running=is_running,
        pid=ffmpeg_process.pid if is_running else None,
        message="Stream is running" if is_running else "Stream is stopped"
    )

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