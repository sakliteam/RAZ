#!/bin/bash

###############################################################################
# Permission Fix Script
# Fixes file ownership and permissions after root installation
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Permission Fix - Reinier Radio Server      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} Dit script moet als root worden uitgevoerd"
   echo -e "Gebruik: ${GREEN}sudo bash fix_permissions.sh${NC}"
   exit 1
fi

# Detect current user
if [ "$SUDO_USER" ]; then
    CURRENT_USER=$SUDO_USER
else
    echo -e "${YELLOW}Geef gebruikersnaam op (bijv. 'pi'):${NC}"
    read CURRENT_USER
fi

# Detect script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}[INFO]${NC} Gebruiker: ${GREEN}$CURRENT_USER${NC}"
echo -e "${BLUE}[INFO]${NC} Directory: ${GREEN}$SCRIPT_DIR${NC}"
echo ""

###############################################################################
# 1. STOP SERVICES
###############################################################################
echo -e "${YELLOW}[1/5]${NC} Services stoppen..."
systemctl stop reinier-backend 2>/dev/null || true
systemctl stop reinier-frontend 2>/dev/null || true
echo -e "${GREEN}✓${NC} Services gestopt"
echo ""

###############################################################################
# 2. FIX OWNERSHIP
###############################################################################
echo -e "${YELLOW}[2/5]${NC} Bestandseigendom aanpassen..."

# Entire project directory
echo -e "  → Project directory..."
chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR

# Backend specifics
if [ -d "$SCRIPT_DIR/backend" ]; then
    echo -e "  → Backend directory..."
    chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/backend
    
    # Python venv
    if [ -d "$SCRIPT_DIR/backend/venv" ]; then
        echo -e "  → Python virtual environment..."
        chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/backend/venv
    fi
fi

# Frontend specifics
if [ -d "$SCRIPT_DIR/frontend" ]; then
    echo -e "  → Frontend directory..."
    chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/frontend
    
    # node_modules
    if [ -d "$SCRIPT_DIR/frontend/node_modules" ]; then
        echo -e "  → node_modules..."
        chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/frontend/node_modules
    fi
    
    # Cache directories
    if [ -d "$SCRIPT_DIR/frontend/node_modules/.cache" ]; then
        echo -e "  → Cache directory..."
        chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/frontend/node_modules/.cache
    fi
fi

echo -e "${GREEN}✓${NC} Eigendom aangepast naar: ${GREEN}$CURRENT_USER${NC}"
echo ""

###############################################################################
# 3. FIX PERMISSIONS
###############################################################################
echo -e "${YELLOW}[3/5]${NC} Permissies aanpassen..."

# Make directories writable
if [ -d "$SCRIPT_DIR/backend" ]; then
    chmod -R 755 $SCRIPT_DIR/backend
fi

if [ -d "$SCRIPT_DIR/frontend" ]; then
    chmod -R 755 $SCRIPT_DIR/frontend
fi

# Ensure scripts are executable
chmod +x $SCRIPT_DIR/*.sh 2>/dev/null || true

echo -e "${GREEN}✓${NC} Permissies aangepast"
echo ""

###############################################################################
# 4. RECREATE CACHE DIRECTORIES
###############################################################################
echo -e "${YELLOW}[4/5]${NC} Cache directories opnieuw aanmaken..."

# Frontend cache
if [ -d "$SCRIPT_DIR/frontend" ]; then
    # Remove old cache if exists
    rm -rf $SCRIPT_DIR/frontend/node_modules/.cache 2>/dev/null || true
    
    # Create new cache directory
    mkdir -p $SCRIPT_DIR/frontend/node_modules/.cache
    chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/frontend/node_modules/.cache
    chmod -R 755 $SCRIPT_DIR/frontend/node_modules/.cache
    
    echo -e "${GREEN}✓${NC} Frontend cache directory aangemaakt"
fi

# Backend cache/logs
if [ -d "$SCRIPT_DIR/backend" ]; then
    mkdir -p $SCRIPT_DIR/backend/__pycache__ 2>/dev/null || true
    chown -R $CURRENT_USER:$CURRENT_USER $SCRIPT_DIR/backend/__pycache__ 2>/dev/null || true
fi

echo ""

###############################################################################
# 5. START SERVICES
###############################################################################
echo -e "${YELLOW}[5/5]${NC} Services herstarten..."

systemctl start reinier-backend
sleep 2
systemctl start reinier-frontend
sleep 3

echo -e "${GREEN}✓${NC} Services gestart"
echo ""

###############################################################################
# VERIFY
###############################################################################
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}Service Status:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Backend status
if systemctl is-active --quiet reinier-backend; then
    echo -e "Backend:  ${GREEN}✓ Actief${NC}"
else
    echo -e "Backend:  ${RED}✗ Niet actief${NC}"
fi

# Frontend status
if systemctl is-active --quiet reinier-frontend; then
    echo -e "Frontend: ${GREEN}✓ Actief${NC}"
else
    echo -e "Frontend: ${RED}✗ Niet actief${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

###############################################################################
# SUCCESS
###############################################################################
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Permission Fix Compleet!                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo -e "Web Interface: ${GREEN}http://${IP_ADDRESS}:3000${NC}"
echo ""
echo -e "${YELLOW}Als er nog steeds problemen zijn:${NC}"
echo -e "  1. Check logs: ${GREEN}sudo journalctl -u reinier-frontend -n 50${NC}"
echo -e "  2. Herstart services: ${GREEN}sudo systemctl restart reinier-frontend${NC}"
echo -e "  3. Status check: ${GREEN}bash check_status.sh${NC}"
echo ""
