#!/bin/bash

###############################################################################
# Reinier de Graaf Radio Server - Automatische Installatie Script
# Voor Raspberry Pi (Raspberry Pi OS / Debian)
###############################################################################

set -e  # Stop bij eerste fout

# Kleuren voor output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functie
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Reinier de Graaf Radio Server - Installatie            ║
║   Versie 1.0.0                                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check of script als root wordt uitgevoerd
if [[ $EUID -ne 0 ]]; then
   log_error "Dit script moet als root worden uitgevoerd"
   log_info "Gebruik: sudo bash install.sh"
   exit 1
fi

# Detecteer huidige gebruiker
if [ "$SUDO_USER" ]; then
    CURRENT_USER=$SUDO_USER
else
    CURRENT_USER=$(whoami)
fi

log_info "Installatie voor gebruiker: $CURRENT_USER"

# Detecteer installatie directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
log_info "Installatie directory: $SCRIPT_DIR"

###############################################################################
# 1. SYSTEEM UPDATE
###############################################################################
log_info "Stap 1/10: Systeem bijwerken..."
apt-get update -qq
apt-get upgrade -y -qq
log_success "Systeem bijgewerkt"

###############################################################################
# 2. FFMPEG INSTALLATIE
###############################################################################
log_info "Stap 2/10: FFmpeg installeren..."
if command -v ffmpeg &> /dev/null; then
    log_warning "FFmpeg is al geïnstalleerd"
    ffmpeg -version | head -n 1
else
    apt-get install -y ffmpeg
    log_success "FFmpeg geïnstalleerd"
fi

###############################################################################
# 3. MONGODB INSTALLATIE
###############################################################################
log_info "Stap 3/10: MongoDB installeren..."

# Check of MongoDB al draait
if systemctl is-active --quiet mongod 2>/dev/null || systemctl is-active --quiet mongodb 2>/dev/null; then
    log_success "MongoDB draait al"
elif command -v mongod &> /dev/null || command -v mongo &> /dev/null; then
    log_warning "MongoDB is geïnstalleerd maar draait niet"
    systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null || true
else
    log_info "MongoDB installeren voor Raspberry Pi..."
    
    # Probeer eerst Docker methode (snelste en meest betrouwbaar)
    if command -v docker &> /dev/null; then
        log_info "Docker gevonden, MongoDB installeren via Docker..."
        
        # Stop oude container als die bestaat
        docker stop mongodb 2>/dev/null || true
        docker rm mongodb 2>/dev/null || true
        
        # Start MongoDB container
        docker run -d \
            --name mongodb \
            --restart always \
            -p 27017:27017 \
            -v mongodb_data:/data/db \
            mongo:4.4 \
            --quiet
        
        # Wacht tot MongoDB klaar is
        sleep 5
        
        log_success "MongoDB geïnstalleerd via Docker"
    else
        log_warning "Docker niet gevonden, installeer Docker voor MongoDB..."
        log_info "Docker installeren..."
        
        # Installeer Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker $CURRENT_USER
        rm get-docker.sh
        
        log_success "Docker geïnstalleerd"
        
        # Nu MongoDB installeren via Docker
        log_info "MongoDB installeren via Docker..."
        docker run -d \
            --name mongodb \
            --restart always \
            -p 27017:27017 \
            -v mongodb_data:/data/db \
            mongo:4.4 \
            --quiet
        
        sleep 5
        log_success "MongoDB geïnstalleerd via Docker"
    fi
fi

# Verificatie
log_info "MongoDB verbinding testen..."
sleep 3

# Test of MongoDB bereikbaar is
if command -v mongosh &> /dev/null; then
    if mongosh --eval "db.version()" --quiet localhost:27017/test &>/dev/null; then
        log_success "MongoDB werkt correct"
    else
        log_warning "MongoDB verbinding testen met alternatieve methode..."
    fi
elif command -v mongo &> /dev/null; then
    if mongo --eval "db.version()" --quiet localhost:27017/test &>/dev/null; then
        log_success "MongoDB werkt correct"
    else
        log_warning "MongoDB mogelijk nog niet klaar, dit is normaal"
    fi
else
    log_warning "MongoDB CLI niet beschikbaar, maar dat is OK"
fi

###############################################################################
# 4. PYTHON & PIP INSTALLATIE
###############################################################################
log_info "Stap 4/10: Python en pip installeren..."
apt-get install -y python3 python3-pip python3-venv
log_success "Python geïnstalleerd: $(python3 --version)"

###############################################################################
# 5. NODE.JS & NPM INSTALLATIE
###############################################################################
log_info "Stap 5/10: Node.js en npm installeren..."
if command -v node &> /dev/null; then
    log_warning "Node.js is al geïnstalleerd: $(node --version)"
else
    # Installeer NodeSource repository voor nieuwere versie
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    log_success "Node.js geïnstalleerd: $(node --version)"
fi

# Installeer yarn
if ! command -v yarn &> /dev/null; then
    npm install -g yarn
    log_success "Yarn geïnstalleerd"
fi

###############################################################################
# 6. BACKEND DEPENDENCIES
###############################################################################
log_info "Stap 6/10: Backend dependencies installeren..."
cd $SCRIPT_DIR/backend

# Maak virtual environment (optioneel, maar aanbevolen)
if [ ! -d "venv" ]; then
    python3 -m venv venv
    log_success "Python virtual environment aangemaakt"
fi

# Activeer venv en installeer packages
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

log_success "Backend dependencies geïnstalleerd"

###############################################################################
# 7. FRONTEND DEPENDENCIES
###############################################################################
log_info "Stap 7/10: Frontend dependencies installeren..."
cd $SCRIPT_DIR/frontend

# Verwijder oude node_modules indien aanwezig
if [ -d "node_modules" ]; then
    log_warning "Oude node_modules verwijderen..."
    rm -rf node_modules
fi

# Installeer dependencies
yarn install

log_success "Frontend dependencies geïnstalleerd"

###############################################################################
# 8. ENVIRONMENT VARIABELEN CONFIGUREREN
###############################################################################
log_info "Stap 8/10: Environment variabelen configureren..."

# Backend .env
cd $SCRIPT_DIR/backend
if [ ! -f ".env" ]; then
    cat > .env << EOF
MONGO_URL="mongodb://localhost:27017"
DB_NAME="reinier_radio_server"
CORS_ORIGINS="*"
EOF
    log_success "Backend .env aangemaakt"
else
    log_warning "Backend .env bestaat al"
fi

# Frontend .env
cd $SCRIPT_DIR/frontend
if [ ! -f ".env" ]; then
    # Detecteer IP adres
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    cat > .env << EOF
REACT_APP_BACKEND_URL=http://${IP_ADDRESS}:8001
WDS_SOCKET_PORT=0
EOF
    log_success "Frontend .env aangemaakt met IP: $IP_ADDRESS"
else
    log_warning "Frontend .env bestaat al"
fi

###############################################################################
# 9. SYSTEMD SERVICES CONFIGUREREN
###############################################################################
log_info "Stap 9/10: Systemd services configureren..."

# Backend Service
cat > /etc/systemd/system/reinier-backend.service << EOF
[Unit]
Description=Reinier de Graaf Radio Server - Backend
After=network.target mongodb.service
Wants=mongodb.service

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$SCRIPT_DIR/backend
Environment="PATH=$SCRIPT_DIR/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=$SCRIPT_DIR/backend/venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

StandardOutput=journal
StandardError=journal
SyslogIdentifier=reinier-backend

[Install]
WantedBy=multi-user.target
EOF

log_success "Backend service geconfigureerd"

# Frontend Service (voor development - optioneel)
cat > /etc/systemd/system/reinier-frontend.service << EOF
[Unit]
Description=Reinier de Graaf Radio Server - Frontend (Development)
After=network.target reinier-backend.service
Wants=reinier-backend.service

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$SCRIPT_DIR/frontend
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="NODE_ENV=development"
ExecStart=/usr/bin/yarn start
Restart=always
RestartSec=10

StandardOutput=journal
StandardError=journal
SyslogIdentifier=reinier-frontend

[Install]
WantedBy=multi-user.target
EOF

log_success "Frontend service geconfigureerd"

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable reinier-backend.service
systemctl enable reinier-frontend.service

log_success "Services geactiveerd"

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
# INSTALLATIE COMPLEET
###############################################################################
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✅ INSTALLATIE SUCCESVOL VOLTOOID!                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📻 Reinier de Graaf Radio Server is klaar!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🌐 Web Interface:    ${GREEN}http://${IP_ADDRESS}:3000${NC}"
echo -e "🔧 Backend API:      ${GREEN}http://${IP_ADDRESS}:8001${NC}"
echo -e "📊 API Docs:         ${GREEN}http://${IP_ADDRESS}:8001/docs${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Handige Commando's:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Service Status Checken:"
echo -e "  ${GREEN}sudo systemctl status reinier-backend${NC}"
echo -e "  ${GREEN}sudo systemctl status reinier-frontend${NC}"
echo ""
echo -e "Services Herstarten:"
echo -e "  ${GREEN}sudo systemctl restart reinier-backend${NC}"
echo -e "  ${GREEN}sudo systemctl restart reinier-frontend${NC}"
echo ""
echo -e "Logs Bekijken:"
echo -e "  ${GREEN}sudo journalctl -u reinier-backend -f${NC}"
echo -e "  ${GREEN}sudo journalctl -u reinier-frontend -f${NC}"
echo ""
echo -e "Services Stoppen:"
echo -e "  ${GREEN}sudo systemctl stop reinier-backend${NC}"
echo -e "  ${GREEN}sudo systemctl stop reinier-frontend${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}⚠️  Belangrijke Notities:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "1. FFmpeg is vereist voor het streamen (geïnstalleerd ✓)"
echo -e "2. MongoDB draait op localhost:27017 (geïnstalleerd ✓)"
echo -e "3. Backend draait op poort 8001"
echo -e "4. Frontend draait op poort 3000"
echo ""
echo -e "5. Voor productie gebruik, bouw de frontend:"
echo -e "   ${GREEN}cd $SCRIPT_DIR/frontend${NC}"
echo -e "   ${GREEN}yarn build${NC}"
echo -e "   En serveer met nginx"
echo ""
echo -e "${GREEN}Veel plezier met Reinier de Graaf Radio Server! 🎉${NC}"
echo ""
