#!/bin/bash

###############################################################################
# Simple FFmpeg Stream Test
# Tests basic functionality without complex filters
###############################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   FFmpeg Eenvoudige Test (30 seconden)       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Default radio URL
RADIO_URL="https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8"
OUTPUT_PORT="5000"

echo -e "${YELLOW}Configuratie:${NC}"
echo -e "  Radio URL: $RADIO_URL"
echo -e "  Output:    udp://127.0.0.1:$OUTPUT_PORT"
echo -e "  Duur:      30 seconden"
echo ""

echo -e "${YELLOW}Test 1: Radio stream bereikbaar?${NC}"
if curl -s --max-time 5 "$RADIO_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Radio URL bereikbaar${NC}"
else
    echo -e "${RED}✗ Radio URL niet bereikbaar${NC}"
    echo -e "${RED}  Controleer internetverbinding!${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Test 2: FFmpeg geïnstalleerd?${NC}"
if command -v ffmpeg &> /dev/null; then
    echo -e "${GREEN}✓ FFmpeg gevonden: $(ffmpeg -version | head -n1)${NC}"
else
    echo -e "${RED}✗ FFmpeg niet geïnstalleerd${NC}"
    echo -e "${RED}  Installeer met: sudo apt install ffmpeg${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}Test 3: Audio naar Video Stream (EENVOUDIG)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Start FFmpeg test... (duurt 30 seconden)${NC}"
echo -e "${YELLOW}Open VLC in ander venster:${NC}"
echo -e "  ${GREEN}vlc udp://@127.0.0.1:$OUTPUT_PORT${NC}"
echo ""
echo -e "Druk op ${YELLOW}Ctrl+C${NC} om te stoppen..."
echo ""

# Simple test without complex filters
ffmpeg \
  -re \
  -i "$RADIO_URL" \
  -f lavfi \
  -i "color=c=blue:s=1280x720:r=25" \
  -filter_complex "[1:v]drawtext=text='TEST STREAM':fontsize=96:fontcolor=white:x=(w-tw)/2:y=(h-th)/2[v]" \
  -map '[v]' \
  -map 0:a \
  -c:v libx264 \
  -preset ultrafast \
  -tune zerolatency \
  -b:v 2M \
  -c:a aac \
  -b:a 128k \
  -t 30 \
  -f mpegts \
  "udp://127.0.0.1:$OUTPUT_PORT?pkt_size=1316" \
  2>&1 | grep -E "Stream|Duration|time=|error|Error"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}Test compleet!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Heb je video gezien in VLC?${NC}"
echo ""
echo -e "JA  → FFmpeg werkt! Probleem is in de applicatie configuratie"
echo -e "NEE → FFmpeg of network probleem"
echo ""
echo -e "${YELLOW}Volgende stappen:${NC}"
echo -e "  1. Als test werkte: Check applicatie FFmpeg commando"
echo -e "  2. Als test niet werkte: Check FFmpeg errors hierboven"
echo -e "  3. Bekijk volledige logs: ${GREEN}bash test_stream.sh${NC}"
echo ""
