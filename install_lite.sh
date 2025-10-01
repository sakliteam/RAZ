#!/bin/bash

###############################################################################
# Reinier de Graaf Radio Server - LITE Installatie (Zonder Docker/MongoDB)
# Voor Raspberry Pi - SQLite kullanır (hafif alternatif)
###############################################################################

set -e

# Kleuren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Reinier de Graaf Radio Server - LITE Installatie       ║
║   (Zonder MongoDB - Gebruikt JSON bestand)               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
   log_error "Dit script moet als root worden uitgevoerd"
   exit 1
fi

if [ "$SUDO_USER" ]; then
    CURRENT_USER=$SUDO_USER
else
    CURRENT_USER=$(whoami)
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
log_info "Installatie voor gebruiker: $CURRENT_USER"

###############################################################################
# 1. SYSTEEM UPDATE
###############################################################################
log_info "Stap 1/10: Systeem bijwerken..."
apt-get update -qq
log_success "Systeem bijgewerkt"

###############################################################################
# 2. FFMPEG
###############################################################################
log_info "Stap 2/10: FFmpeg installeren..."
if command -v ffmpeg &> /dev/null; then
    log_warning "FFmpeg is al geïnstalleerd"
else
    apt-get install -y ffmpeg
    log_success "FFmpeg geïnstalleerd"
fi

###############################################################################
# 3. PYTHON
###############################################################################
log_info "Stap 3/10: Python installeren..."
apt-get install -y python3 python3-pip python3-venv
log_success "Python geïnstalleerd"

###############################################################################
# 4. NODE.JS
###############################################################################
log_info "Stap 4/10: Node.js installeren..."
if command -v node &> /dev/null; then
    log_warning "Node.js is al geïnstalleerd"
else
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi
npm install -g yarn
log_success "Node.js en Yarn geïnstalleerd"

###############################################################################
# 5. BACKEND - LITE VERSION (Zonder MongoDB)
###############################################################################
log_info "Stap 5/10: Backend dependencies (LITE - zonder MongoDB)..."
cd $SCRIPT_DIR/backend

# Maak een lite requirements.txt zonder MongoDB
cat > requirements_lite.txt << 'EOFREQ'
fastapi==0.110.1
uvicorn==0.25.0
pydantic>=2.6.4
python-jose>=3.3.0
python-multipart>=0.0.9
EOFREQ

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements_lite.txt
deactivate

log_success "Backend dependencies geïnstalleerd (LITE versie)"

###############################################################################
# 6. BACKEND LITE VERSION MAKEN
###############################################################################
log_info "Aanpassen backend voor JSON opslag..."

# Backup origineel
cp server.py server_original.py 2>/dev/null || true

# Maak lite server.py (zonder MongoDB, met JSON file)
cat > server_lite.py << 'EOFSERVER'
from fastapi import FastAPI, APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import uuid
import subprocess
import signal
import os
import json
from pathlib import Path

# Create the main app
app = FastAPI()
api_router = APIRouter(prefix="/api")

# Global process tracker
ffmpeg_process = None

# JSON Settings File
SETTINGS_FILE = Path(__file__).parent / "settings.json"

# Define Models
class StreamSettings(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    radio_url: str = "https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8"
    resolution: str = "720p"
    output_mode: str = "multicast"
    unicast_ip: str = "127.0.0.1:5000"
    multicast_address: str = "239.255.0.1:5000"
    font_size: int = 72
    font_color: str = "white"
    is_running: bool = False

class StreamSettingsUpdate(BaseModel):
    radio_url: Optional[str] = None
    resolution: Optional[str] = None
    output_mode: Optional[str] = None
    unicast_ip: Optional[str] = None
    multicast_address: Optional[str] = None
    font_size: Optional[int] = None
    font_color: Optional[str] = None

class StreamStatus(BaseModel):
    is_running: bool
    pid: Optional[int] = None
    message: str

# Helper functions
def load_settings() -> StreamSettings:
    if SETTINGS_FILE.exists():
        with open(SETTINGS_FILE, 'r') as f:
            data = json.load(f)
            return StreamSettings(**data)
    else:
        default = StreamSettings()
        save_settings(default)
        return default

def save_settings(settings: StreamSettings):
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(settings.dict(), f, indent=2)

def get_resolution_dimensions(resolution: str) -> str:
    resolutions = {"540p": "960x540", "720p": "1280x720", "1080p": "1920x1080"}
    return resolutions.get(resolution, "1280x720")

def build_ffmpeg_command(settings: StreamSettings) -> list:
    resolution_dim = get_resolution_dimensions(settings.resolution)
    
    if settings.output_mode == "multicast":
        output_url = f"udp://{settings.multicast_address}?pkt_size=1316"
    else:
        output_url = f"udp://{settings.unicast_ip}?pkt_size=1316"
    
    cmd = [
        'ffmpeg', '-re', '-i', settings.radio_url,
        '-f', 'lavfi', '-i', f'color=c=black:s={resolution_dim}:r=25',
        '-filter_complex',
        f"[1:v]drawtext=text='Reinier de Graaf Radio Server':fontsize={int(settings.font_size * 0.6)}:fontcolor={settings.font_color}:x=(w-tw)/2:y=50:box=1:boxcolor=black@0.6:boxborderw=8,"
        f"drawtext=text='%{{localtime\\:%A %d %B %Y %H\\:%M\\:%S}}':fontsize={settings.font_size}:fontcolor={settings.font_color}:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.6:boxborderw=10,"
        f"drawtext=text='Delft, Nederland':fontsize={int(settings.font_size * 0.5)}:fontcolor={settings.font_color}:x=(w-tw)/2:y=h-80:box=1:boxcolor=black@0.6:boxborderw=8[v]",
        '-map', '[v]', '-map', '0:a',
        '-c:v', 'libx264', '-preset', 'ultrafast', '-tune', 'zerolatency',
        '-b:v', '2M', '-maxrate', '2M', '-bufsize', '4M',
        '-c:a', 'aac', '-b:a', '128k', '-f', 'mpegts', output_url
    ]
    return cmd

# API Routes
@api_router.get("/")
async def root():
    return {"message": "Reinier de Graaf Radio Server (LITE)"}

@api_router.get("/settings", response_model=StreamSettings)
async def get_settings():
    return load_settings()

@api_router.post("/settings", response_model=StreamSettings)
async def update_settings(update: StreamSettingsUpdate):
    global ffmpeg_process
    
    current = load_settings()
    
    if current.is_running:
        raise HTTPException(status_code=400, detail="Kan instellingen niet bijwerken terwijl stream actief is.")
    
    update_data = update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(current, key, value)
    
    save_settings(current)
    return current

@api_router.post("/start", response_model=StreamStatus)
async def start_stream():
    global ffmpeg_process
    
    if ffmpeg_process and ffmpeg_process.poll() is None:
        return StreamStatus(is_running=True, pid=ffmpeg_process.pid, message="Stream is al actief")
    
    settings = load_settings()
    cmd = build_ffmpeg_command(settings)
    
    try:
        env = os.environ.copy()
        env['TZ'] = 'Europe/Amsterdam'
        
        ffmpeg_process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                         preexec_fn=os.setsid, env=env)
        
        settings.is_running = True
        save_settings(settings)
        
        return StreamStatus(is_running=True, pid=ffmpeg_process.pid, message="Stream succesvol gestart")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kan stream niet starten: {str(e)}")

@api_router.post("/stop", response_model=StreamStatus)
async def stop_stream():
    global ffmpeg_process
    
    if not ffmpeg_process or ffmpeg_process.poll() is not None:
        settings = load_settings()
        settings.is_running = False
        save_settings(settings)
        return StreamStatus(is_running=False, pid=None, message="Stream is niet actief")
    
    try:
        os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
        try:
            ffmpeg_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGKILL)
            ffmpeg_process.wait()
        
        ffmpeg_process = None
        settings = load_settings()
        settings.is_running = False
        save_settings(settings)
        
        return StreamStatus(is_running=False, pid=None, message="Stream succesvol gestopt")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kan stream niet stoppen: {str(e)}")

@api_router.get("/status", response_model=StreamStatus)
async def get_status():
    global ffmpeg_process
    
    is_running = ffmpeg_process is not None and ffmpeg_process.poll() is None
    
    settings = load_settings()
    if settings.is_running != is_running:
        settings.is_running = is_running
        save_settings(settings)
    
    return StreamStatus(is_running=is_running, 
                       pid=ffmpeg_process.pid if is_running else None,
                       message="Stream is actief" if is_running else "Stream is gestopt")

app.include_router(api_router)

from starlette.middleware.cors import CORSMiddleware
app.add_middleware(CORSMiddleware, allow_credentials=True, allow_origins=["*"],
                  allow_methods=["*"], allow_headers=["*"])

@app.on_event("shutdown")
async def shutdown():
    global ffmpeg_process
    if ffmpeg_process and ffmpeg_process.poll() is None:
        try:
            os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
            ffmpeg_process.wait(timeout=5)
        except:
            pass
EOFSERVER

log_success "Lite backend server aangemaakt (zonder MongoDB)"

###############################################################################
# 7. FRONTEND
###############################################################################
log_info "Stap 6/10: Frontend dependencies..."
cd $SCRIPT_DIR/frontend

# Fix React Router version for Node 18 compatibility
log_info "React Router versie aanpassen voor Node 18 compatibiliteit..."
if grep -q '"react-router-dom": "\^7' package.json; then
    sed -i 's/"react-router-dom": "\^7[^"]*"/"react-router-dom": "^6.28.0"/g' package.json
    log_success "React Router versie aangepast naar v6 (Node 18 compatibel)"
fi

rm -rf node_modules 2>/dev/null || true
rm -rf yarn.lock 2>/dev/null || true
yarn install
log_success "Frontend dependencies geïnstalleerd"

###############################################################################
# 8. ENVIRONMENT
###############################################################################
log_info "Stap 7/10: Environment configureren..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')

cd $SCRIPT_DIR/frontend
cat > .env << EOF
REACT_APP_BACKEND_URL=http://${IP_ADDRESS}:8001
WDS_SOCKET_PORT=0
EOF

log_success "Environment geconfigureerd"

###############################################################################
# 9. SYSTEMD SERVICES
###############################################################################
log_info "Stap 8/10: Systemd services..."

cat > /etc/systemd/system/reinier-backend.service << EOF
[Unit]
Description=Reinier de Graaf Radio Server - Backend (LITE)
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$SCRIPT_DIR/backend
Environment="PATH=$SCRIPT_DIR/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=$SCRIPT_DIR/backend/venv/bin/python -m uvicorn server_lite:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/reinier-frontend.service << EOF
[Unit]
Description=Reinier de Graaf Radio Server - Frontend
After=network.target reinier-backend.service

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$SCRIPT_DIR/frontend
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/yarn start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable reinier-backend.service
systemctl enable reinier-frontend.service

###############################################################################
# 9. FIX PERMISSIONS
###############################################################################
log_info "Stap 9/10: Bestandspermissies aanpassen..."

# Change ownership to current user
chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR

# Ensure cache directory exists with correct permissions
mkdir -p $SCRIPT_DIR/frontend/node_modules/.cache 2>/dev/null || true
chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/frontend/node_modules/.cache 2>/dev/null || true
chmod -R 755 $SCRIPT_DIR/frontend/node_modules/.cache 2>/dev/null || true

log_success "Permissies aangepast"

###############################################################################
# 10. SERVICES STARTEN
###############################################################################
log_info "Stap 10/10: Services starten..."

# Start backend
systemctl start reinier-backend.service
sleep 3

if systemctl is-active --quiet reinier-backend.service; then
    log_success "Backend service draait"
else
    log_error "Backend service kon niet starten. Check logs met: journalctl -u reinier-backend -n 50"
fi

# Start frontend
systemctl start reinier-frontend.service
sleep 3

if systemctl is-active --quiet reinier-frontend.service; then
    log_success "Frontend service draait"
else
    log_error "Frontend service kon niet starten. Check logs met: journalctl -u reinier-frontend -n 50"
fi

###############################################################################
# KLAAR
###############################################################################
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ LITE INSTALLATIE SUCCESVOL!                         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📻 Reinier de Graaf Radio Server (LITE versie)${NC}"
echo -e "${GREEN}   Gebruikt JSON bestand ipv MongoDB - lichter en sneller!${NC}"
echo ""
echo -e "🌐 Web Interface: ${GREEN}http://${IP_ADDRESS}:3000${NC}"
echo -e "🔧 Backend API:   ${GREEN}http://${IP_ADDRESS}:8001${NC}"
echo ""
echo -e "${YELLOW}Services beheren:${NC}"
echo -e "  sudo systemctl status reinier-backend"
echo -e "  sudo systemctl restart reinier-backend"
echo ""
echo -e "${GREEN}Veel plezier! 🎉${NC}"
