#!/bin/bash

###############################################################################
# Fix Node.js Version Compatibility
# React Router 7 downgrade to v6 for Node 18
###############################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Node.js Compatibiliteit Fix ===${NC}"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR/frontend

echo -e "${YELLOW}Huidige Node.js versie:${NC}"
node --version
echo ""

echo -e "${YELLOW}React Router versie aanpassen...${NC}"
# Fix package.json
sed -i 's/"react-router-dom": "\^7[^"]*"/"react-router-dom": "^6.28.0"/g' package.json

echo -e "${GREEN}✓ package.json aangepast${NC}"
echo ""

echo -e "${YELLOW}node_modules en yarn.lock verwijderen...${NC}"
rm -rf node_modules
rm -rf yarn.lock

echo -e "${GREEN}✓ Opgeschoond${NC}"
echo ""

echo -e "${YELLOW}Dependencies opnieuw installeren...${NC}"
yarn install

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Fix compleet!                            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "React Router gedowngrade naar v6.28.0"
echo -e "Compatibel met Node.js 18+"
echo ""
echo -e "${YELLOW}Nu kun je de installatie opnieuw proberen:${NC}"
echo -e "  sudo bash install_lite.sh"
echo ""
