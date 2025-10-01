#!/bin/bash

###############################################################################
# Status Check Script - Reinier de Graaf Radio Server
###############################################################################

# Kleuren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Reinier de Graaf Radio Server - Status Check          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# SYSTEEM INFO
###############################################################################
echo -e "${BLUE}=== Systeem Informatie ===${NC}"
echo -e "Hostname:    $(hostname)"
echo -e "IP Adres:    $(hostname -I | awk '{print $1}')"
echo -e "OS:          $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "Uptime:      $(uptime -p)"
echo ""

###############################################################################
# VEREISTE SOFTWARE
###############################################################################
echo -e "${BLUE}=== Geïnstalleerde Software ===${NC}"

# FFmpeg
if command -v ffmpeg &> /dev/null; then
    echo -e "FFmpeg:      ${GREEN}✓ Geïnstalleerd${NC} ($(ffmpeg -version | head -n1 | awk '{print $3}'))"
else
    echo -e "FFmpeg:      ${RED}✗ Niet gevonden${NC}"
fi

# MongoDB
if command -v mongod &> /dev/null; then
    echo -e "MongoDB:     ${GREEN}✓ Geïnstalleerd${NC}"
else
    echo -e "MongoDB:     ${RED}✗ Niet gevonden${NC}"
fi

# Python
if command -v python3 &> /dev/null; then
    echo -e "Python:      ${GREEN}✓ Geïnstalleerd${NC} ($(python3 --version | awk '{print $2}'))"
else
    echo -e "Python:      ${RED}✗ Niet gevonden${NC}"
fi

# Node.js
if command -v node &> /dev/null; then
    echo -e "Node.js:     ${GREEN}✓ Geïnstalleerd${NC} ($(node --version))"
else
    echo -e "Node.js:     ${RED}✗ Niet gevonden${NC}"
fi

# Yarn
if command -v yarn &> /dev/null; then
    echo -e "Yarn:        ${GREEN}✓ Geïnstalleerd${NC} ($(yarn --version))"
else
    echo -e "Yarn:        ${RED}✗ Niet gevonden${NC}"
fi

echo ""

###############################################################################
# SERVICES STATUS
###############################################################################
echo -e "${BLUE}=== Services Status ===${NC}"

# MongoDB Service
if systemctl is-active --quiet mongodb; then
    echo -e "MongoDB:     ${GREEN}✓ Actief${NC}"
else
    echo -e "MongoDB:     ${RED}✗ Niet actief${NC}"
fi

# Backend Service
if systemctl list-unit-files | grep -q "reinier-backend.service"; then
    if systemctl is-active --quiet reinier-backend; then
        echo -e "Backend:     ${GREEN}✓ Actief${NC}"
    else
        echo -e "Backend:     ${RED}✗ Niet actief${NC}"
    fi
else
    echo -e "Backend:     ${YELLOW}⚠ Service niet geconfigureerd${NC}"
fi

# Frontend Service
if systemctl list-unit-files | grep -q "reinier-frontend.service"; then
    if systemctl is-active --quiet reinier-frontend; then
        echo -e "Frontend:    ${GREEN}✓ Actief${NC}"
    else
        echo -e "Frontend:    ${RED}✗ Niet actief${NC}"
    fi
else
    echo -e "Frontend:    ${YELLOW}⚠ Service niet geconfigureerd${NC}"
fi

echo ""

###############################################################################
# POORT STATUS
###############################################################################
echo -e "${BLUE}=== Poorten Status ===${NC}"

# Check als netstat beschikbaar is
if ! command -v netstat &> /dev/null; then
    echo -e "${YELLOW}netstat niet gevonden, installeer met: sudo apt install net-tools${NC}"
else
    # MongoDB (27017)
    if netstat -tuln | grep -q ":27017"; then
        echo -e "MongoDB:     ${GREEN}✓ Poort 27017 actief${NC}"
    else
        echo -e "MongoDB:     ${RED}✗ Poort 27017 niet actief${NC}"
    fi
    
    # Backend (8001)
    if netstat -tuln | grep -q ":8001"; then
        echo -e "Backend:     ${GREEN}✓ Poort 8001 actief${NC}"
    else
        echo -e "Backend:     ${RED}✗ Poort 8001 niet actief${NC}"
    fi
    
    # Frontend (3000)
    if netstat -tuln | grep -q ":3000"; then
        echo -e "Frontend:    ${GREEN}✓ Poort 3000 actief${NC}"
    else
        echo -e "Frontend:    ${RED}✗ Poort 3000 niet actief${NC}"
    fi
fi

echo ""

###############################################################################
# API STATUS
###############################################################################
echo -e "${BLUE}=== API Status Check ===${NC}"

# Test Backend API
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/ 2>/dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo -e "Backend API: ${GREEN}✓ Bereikbaar (HTTP 200)${NC}"
    else
        echo -e "Backend API: ${RED}✗ Niet bereikbaar (HTTP $RESPONSE)${NC}"
    fi
else
    echo -e "${YELLOW}curl niet gevonden om API te testen${NC}"
fi

echo ""

###############################################################################
# DISK RUIMTE
###############################################################################
echo -e "${BLUE}=== Disk Ruimte ===${NC}"
df -h / | awk 'NR==2 {print "Gebruikt:    "$3" / "$2" ("$5")"}'
echo ""

###############################################################################
# GEHEUGEN
###############################################################################
echo -e "${BLUE}=== Geheugen Gebruik ===${NC}"
free -h | awk 'NR==2 {print "RAM:         "$3" / "$2}'
echo ""

###############################################################################
# RECENTE LOGS
###############################################################################
echo -e "${BLUE}=== Recente Logs (laatste 5 regels) ===${NC}"

if systemctl list-unit-files | grep -q "reinier-backend.service"; then
    echo -e "${YELLOW}Backend:${NC}"
    journalctl -u reinier-backend -n 5 --no-pager 2>/dev/null || echo "Geen logs beschikbaar"
    echo ""
fi

if systemctl list-unit-files | grep -q "reinier-frontend.service"; then
    echo -e "${YELLOW}Frontend:${NC}"
    journalctl -u reinier-frontend -n 5 --no-pager 2>/dev/null || echo "Geen logs beschikbaar"
    echo ""
fi

###############################################################################
# URLS
###############################################################################
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo -e "${BLUE}=== Toegang URLs ===${NC}"
echo -e "Web Interface:  ${GREEN}http://${IP_ADDRESS}:3000${NC}"
echo -e "Backend API:    ${GREEN}http://${IP_ADDRESS}:8001${NC}"
echo -e "API Docs:       ${GREEN}http://${IP_ADDRESS}:8001/docs${NC}"
echo ""

###############################################################################
# AANBEVELINGEN
###############################################################################
echo -e "${BLUE}=== Aanbevelingen ===${NC}"

ISSUES=0

# Check FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Installeer FFmpeg: ${GREEN}sudo apt install ffmpeg${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check MongoDB
if ! systemctl is-active --quiet mongodb 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Start MongoDB: ${GREEN}sudo systemctl start mongodb${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check Backend
if systemctl list-unit-files | grep -q "reinier-backend.service"; then
    if ! systemctl is-active --quiet reinier-backend; then
        echo -e "${YELLOW}⚠${NC} Start Backend: ${GREEN}sudo systemctl start reinier-backend${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Check Frontend
if systemctl list-unit-files | grep -q "reinier-frontend.service"; then
    if ! systemctl is-active --quiet reinier-frontend; then
        echo -e "${YELLOW}⚠${NC} Start Frontend: ${GREEN}sudo systemctl start reinier-frontend${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Alles ziet er goed uit!${NC}"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Status check compleet                                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
