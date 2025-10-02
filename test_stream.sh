#!/bin/bash

###############################################################################
# Stream Test & Debug Script
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Stream Test & Debug                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# 1. CHECK IF STREAM IS RUNNING
###############################################################################
echo -e "${BLUE}[1] FFmpeg Process Controle${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

FFMPEG_PIDS=$(pgrep -f "ffmpeg.*reinier")

if [ -z "$FFMPEG_PIDS" ]; then
    echo -e "${RED}✗ Geen FFmpeg process gevonden${NC}"
    echo -e "${YELLOW}  → Start de stream vanuit de web interface${NC}"
    echo ""
else
    echo -e "${GREEN}✓ FFmpeg draait${NC}"
    echo -e "  PID: ${GREEN}$FFMPEG_PIDS${NC}"
    echo ""
    
    # Show full command
    echo -e "${YELLOW}Actieve FFmpeg commando:${NC}"
    ps aux | grep -E "ffmpeg.*reinier" | grep -v grep | head -1
    echo ""
fi

###############################################################################
# 2. CHECK BACKEND LOGS
###############################################################################
echo -e "${BLUE}[2] Backend Logs (laatste 20 regels)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
journalctl -u reinier-backend -n 20 --no-pager 2>/dev/null || echo "Geen backend logs beschikbaar"
echo ""

###############################################################################
# 3. CHECK SETTINGS
###############################################################################
echo -e "${BLUE}[3] Huidige Instellingen${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

# Try to get settings from API
SETTINGS=$(curl -s http://localhost:8001/api/settings 2>/dev/null)

if [ ! -z "$SETTINGS" ]; then
    echo "$SETTINGS" | python3 -m json.tool 2>/dev/null || echo "$SETTINGS"
else
    echo -e "${RED}Kan instellingen niet ophalen van API${NC}"
fi
echo ""

###############################################################################
# 4. TEST RADIO URL
###############################################################################
echo -e "${BLUE}[4] Radio URL Test${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

RADIO_URL=$(echo "$SETTINGS" | python3 -c "import sys, json; print(json.load(sys.stdin)['radio_url'])" 2>/dev/null)

if [ ! -z "$RADIO_URL" ]; then
    echo -e "Radio URL: ${YELLOW}$RADIO_URL${NC}"
    echo -e "Testen..."
    
    # Test if URL is reachable
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$RADIO_URL" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Radio URL bereikbaar (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ Radio URL niet bereikbaar (HTTP $HTTP_CODE)${NC}"
        echo -e "${YELLOW}  → Controleer de radio URL in de web interface${NC}"
    fi
else
    echo -e "${RED}Kan radio URL niet vinden${NC}"
fi
echo ""

###############################################################################
# 5. CHECK UDP PORTS
###############################################################################
echo -e "${BLUE}[5] UDP Poort Check${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

OUTPUT_MODE=$(echo "$SETTINGS" | python3 -c "import sys, json; print(json.load(sys.stdin)['output_mode'])" 2>/dev/null)

if [ "$OUTPUT_MODE" = "multicast" ]; then
    MULTICAST_ADDR=$(echo "$SETTINGS" | python3 -c "import sys, json; print(json.load(sys.stdin)['multicast_address'])" 2>/dev/null)
    echo -e "Modus: ${YELLOW}Multicast${NC}"
    echo -e "Adres: ${YELLOW}$MULTICAST_ADDR${NC}"
    echo ""
    echo -e "${YELLOW}Test met VLC:${NC}"
    echo -e "  ${GREEN}vlc udp://@$MULTICAST_ADDR${NC}"
else
    UNICAST_IP=$(echo "$SETTINGS" | python3 -c "import sys, json; print(json.load(sys.stdin)['unicast_ip'])" 2>/dev/null)
    echo -e "Modus: ${YELLOW}Unicast${NC}"
    echo -e "IP: ${YELLOW}$UNICAST_IP${NC}"
    echo ""
    echo -e "${YELLOW}Test met VLC:${NC}"
    echo -e "  ${GREEN}vlc udp://@$UNICAST_IP${NC}"
fi
echo ""

###############################################################################
# 6. MANUAL TEST COMMAND
###############################################################################
echo -e "${BLUE}[6] Handmatige Test${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "Om handmatig te testen, stop eerst de stream en voer uit:"
echo ""
echo -e "${GREEN}# Test commando (30 seconden):${NC}"
echo -e "${YELLOW}ffmpeg -re -i \"$RADIO_URL\" \\"
echo -e "  -f lavfi -i color=c=black:s=1280x720:r=25 \\"
echo -e "  -filter_complex \"[1:v]drawtext=text='TEST %{localtime}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2[v]\" \\"
echo -e "  -map '[v]' -map 0:a \\"
echo -e "  -c:v libx264 -preset ultrafast -b:v 2M \\"
echo -e "  -c:a aac -b:a 128k \\"
echo -e "  -t 30 \\"
echo -e "  -f mpegts udp://127.0.0.1:5000${NC}"
echo ""
echo -e "${GREEN}# Bekijk met VLC:${NC}"
echo -e "${YELLOW}vlc udp://@127.0.0.1:5000${NC}"
echo ""

###############################################################################
# 7. COMMON ISSUES
###############################################################################
echo -e "${BLUE}[7] Veelvoorkomende Problemen${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Problem 1:${NC} Stream start maar geen video"
echo -e "  ${GREEN}→${NC} Check FFmpeg logs: ${GREEN}journalctl -u reinier-backend -f${NC}"
echo -e "  ${GREEN}→${NC} Radio URL kan onbereikbaar zijn"
echo -e "  ${GREEN}→${NC} FFmpeg kan crashen door filter complexiteit"
echo ""

echo -e "${YELLOW}Problem 2:${NC} VLC kan stream niet vinden"
echo -e "  ${GREEN}→${NC} Check firewall: ${GREEN}sudo ufw status${NC}"
echo -e "  ${GREEN}→${NC} Open UDP poort als nodig"
echo -e "  ${GREEN}→${NC} Gebruik juist IP adres voor unicast"
echo ""

echo -e "${YELLOW}Problem 3:${NC} Stream buffert of stopt"
echo -e "  ${GREEN}→${NC} Internetverbinding te traag"
echo -e "  ${GREEN}→${NC} Gebruik lagere resolutie (540p)"
echo -e "  ${GREEN}→${NC} Verlaag bitrate in FFmpeg commando"
echo ""

###############################################################################
# 8. LIVE FFMPEG LOGS
###############################################################################
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Om live FFmpeg output te zien:${NC}"
echo -e "  ${GREEN}sudo journalctl -u reinier-backend -f${NC}"
echo ""
echo -e "${YELLOW}Om FFmpeg process te stoppen:${NC}"
echo -e "  ${GREEN}sudo pkill -9 ffmpeg${NC}"
echo -e "  Of via web interface: 'Stream Stoppen'"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
