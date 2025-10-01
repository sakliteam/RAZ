# 🍓 Reinier de Graaf Radio Server - Raspberry Pi Installatie

## 📋 Vereisten

### Hardware
- Raspberry Pi 3, 4, of 5
- Minimum 2GB RAM (4GB aanbevolen)
- MicroSD kaart (16GB+)
- Internetverbinding

### Software
- Raspberry Pi OS (32-bit of 64-bit)
- SSH toegang of directe toegang via monitor/keyboard

---

## 🚀 Snelle Installatie (Automatisch)

### Stap 1: Download het Project

```bash
# Via git (aanbevolen)
cd ~
git clone https://github.com/jouw-username/reinier-radio-server.git
cd reinier-radio-server

# OF via SCP als je de bestanden al hebt
# scp -r /pad/naar/app pi@192.168.1.X:/home/pi/reinier-radio-server
```

### Stap 2: Maak Script Uitvoerbaar

```bash
chmod +x install.sh
```

### Stap 3: Voer Installatie Script Uit

```bash
sudo bash install.sh
```

**Het script installeert automatisch:**
- ✅ FFmpeg
- ✅ MongoDB
- ✅ Python 3 + Dependencies
- ✅ Node.js + Yarn
- ✅ Backend Dependencies
- ✅ Frontend Dependencies
- ✅ Systemd Services
- ✅ Start alles automatisch op

**Installatie duurt:** 10-20 minuten (afhankelijk van internetsnelheid)

### Stap 4: Open Web Interface

Na succesvolle installatie:

```
http://[RASPBERRY_PI_IP]:3000
```

Bijvoorbeeld: `http://192.168.1.100:3000`

---

## 🔧 Handmatige Installatie

Als automatisch script niet werkt, volg deze stappen:

### 1. Systeem Updaten

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. FFmpeg Installeren

```bash
sudo apt install ffmpeg -y
ffmpeg -version
```

### 3. MongoDB Installeren

```bash
sudo apt install mongodb -y
sudo systemctl start mongodb
sudo systemctl enable mongodb
```

### 4. Python Dependencies

```bash
cd ~/reinier-radio-server/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
```

### 5. Node.js Installeren

```bash
# Installeer NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y nodejs

# Installeer Yarn
sudo npm install -g yarn
```

### 6. Frontend Dependencies

```bash
cd ~/reinier-radio-server/frontend
yarn install
```

### 7. Environment Configureren

**Backend .env:**
```bash
cd ~/reinier-radio-server/backend
nano .env
```

Inhoud:
```
MONGO_URL="mongodb://localhost:27017"
DB_NAME="reinier_radio_server"
CORS_ORIGINS="*"
```

**Frontend .env:**
```bash
cd ~/reinier-radio-server/frontend
nano .env
```

Inhoud (vervang IP):
```
REACT_APP_BACKEND_URL=http://192.168.1.100:8001
WDS_SOCKET_PORT=0
```

### 8. Handmatig Starten (Test)

**Terminal 1 - Backend:**
```bash
cd ~/reinier-radio-server/backend
source venv/bin/activate
python -m uvicorn server:app --host 0.0.0.0 --port 8001
```

**Terminal 2 - Frontend:**
```bash
cd ~/reinier-radio-server/frontend
yarn start
```

Open browser: `http://[RASPBERRY_PI_IP]:3000`

---

## 🔄 Systemd Services (Automatisch Opstarten)

### Services Configureren

Het installatie script heeft deze al voor je gemaakt. Als je handmatig wilt:

**Backend Service:**
```bash
sudo nano /etc/systemd/system/reinier-backend.service
```

Inhoud:
```ini
[Unit]
Description=Reinier de Graaf Radio Server - Backend
After=network.target mongodb.service
Wants=mongodb.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/reinier-radio-server/backend
Environment="PATH=/home/pi/reinier-radio-server/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=/home/pi/reinier-radio-server/backend/venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Frontend Service:**
```bash
sudo nano /etc/systemd/system/reinier-frontend.service
```

Inhoud:
```ini
[Unit]
Description=Reinier de Graaf Radio Server - Frontend
After=network.target reinier-backend.service
Wants=reinier-backend.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/reinier-radio-server/frontend
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/yarn start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Services Activeren

```bash
sudo systemctl daemon-reload
sudo systemctl enable reinier-backend
sudo systemctl enable reinier-frontend
sudo systemctl start reinier-backend
sudo systemctl start reinier-frontend
```

### Services Beheren

```bash
# Status checken
sudo systemctl status reinier-backend
sudo systemctl status reinier-frontend

# Herstarten
sudo systemctl restart reinier-backend
sudo systemctl restart reinier-frontend

# Stoppen
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend

# Logs bekijken
sudo journalctl -u reinier-backend -f
sudo journalctl -u reinier-frontend -f
```

---

## 🐛 Problemen Oplossen

### Probleem: "kan niet starten" / Backend start niet

**Oplossing 1: Check Backend Logs**
```bash
sudo journalctl -u reinier-backend -n 100
```

**Oplossing 2: MongoDB Check**
```bash
sudo systemctl status mongodb
sudo systemctl start mongodb
```

**Oplossing 3: Python Dependencies**
```bash
cd ~/reinier-radio-server/backend
source venv/bin/activate
pip install -r requirements.txt --force-reinstall
deactivate
sudo systemctl restart reinier-backend
```

### Probleem: Frontend laadt niet

**Oplossing 1: Check Frontend Logs**
```bash
sudo journalctl -u reinier-frontend -n 100
```

**Oplossing 2: Node Modules Opnieuw Installeren**
```bash
cd ~/reinier-radio-server/frontend
rm -rf node_modules
yarn install
sudo systemctl restart reinier-frontend
```

**Oplossing 3: Port Check**
```bash
sudo netstat -tulpn | grep :3000
# Als poort in gebruik, kill het proces:
sudo kill -9 [PID]
```

### Probleem: FFmpeg Error

**Test FFmpeg:**
```bash
ffmpeg -version
```

**Heinstalleer indien nodig:**
```bash
sudo apt remove ffmpeg
sudo apt install ffmpeg -y
```

### Probleem: MongoDB Connection Error

**Check Status:**
```bash
sudo systemctl status mongodb
```

**Herstart MongoDB:**
```bash
sudo systemctl restart mongodb
```

**Check Logs:**
```bash
sudo journalctl -u mongodb -n 50
```

### Probleem: Poorten Geblokkeerd

**Check Firewall:**
```bash
sudo ufw status
```

**Open Poorten (indien nodig):**
```bash
sudo ufw allow 3000/tcp
sudo ufw allow 8001/tcp
```

### Probleem: Kan Web Interface Niet Bereiken

**Check IP Adres:**
```bash
hostname -I
```

**Check Services:**
```bash
sudo systemctl status reinier-backend
sudo systemctl status reinier-frontend
```

**Test Backend Direct:**
```bash
curl http://localhost:8001/api/
# Moet "Reinier de Graaf Radio Server" teruggeven
```

---

## 📊 Prestatie Optimalisatie

### Raspberry Pi 3
- **Aanbevolen Resolutie:** 540p of 720p
- **CPU Gebruik:** ~70% bij 720p
- **Tip:** Gebruik `540p` voor lagere CPU load

### Raspberry Pi 4
- **Aanbevolen Resolutie:** 720p of 1080p
- **CPU Gebruik:** ~50% bij 1080p
- **Tip:** 1080p werkt zonder problemen

### Raspberry Pi 5
- **Aanbevolen Resolutie:** 1080p
- **CPU Gebruik:** ~30% bij 1080p
- **Tip:** Alle resoluties werken soepel

### CPU Monitoren tijdens Stream

```bash
htop
# OF
top
```

---

## 🔐 Productie Deployment (Optioneel)

### Nginx Installeren voor Frontend

```bash
sudo apt install nginx -y
```

### Frontend Bouwen

```bash
cd ~/reinier-radio-server/frontend
yarn build
```

### Nginx Configureren

```bash
sudo nano /etc/nginx/sites-available/reinier-radio
```

Inhoud:
```nginx
server {
    listen 80;
    server_name _;

    root /home/pi/reinier-radio-server/frontend/build;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Activeer:**
```bash
sudo ln -s /etc/nginx/sites-available/reinier-radio /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Disable Frontend Service (niet meer nodig):**
```bash
sudo systemctl stop reinier-frontend
sudo systemctl disable reinier-frontend
```

Nu bereikbaar op: `http://[RASPBERRY_PI_IP]` (poort 80)

---

## 📝 Update Instructies

### Update Code

```bash
cd ~/reinier-radio-server
git pull

# Update backend
cd backend
source venv/bin/activate
pip install -r requirements.txt --upgrade
deactivate

# Update frontend
cd ../frontend
yarn install

# Herstart services
sudo systemctl restart reinier-backend
sudo systemctl restart reinier-frontend
```

---

## 🆘 Ondersteuning

### Quick Diagnostic Script

Maak `check_status.sh`:
```bash
#!/bin/bash
echo "=== System Status ==="
echo "FFmpeg: $(ffmpeg -version | head -n1)"
echo "MongoDB: $(systemctl is-active mongodb)"
echo "Backend: $(systemctl is-active reinier-backend)"
echo "Frontend: $(systemctl is-active reinier-frontend)"
echo ""
echo "=== Poorten ==="
sudo netstat -tulpn | grep -E ':(3000|8001|27017)'
```

Voer uit:
```bash
chmod +x check_status.sh
./check_status.sh
```

### Volledige Reset

```bash
# Stop alles
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend
sudo systemctl stop mongodb

# Verwijder database (optioneel)
sudo rm -rf /var/lib/mongodb/*

# Start opnieuw
sudo systemctl start mongodb
sudo systemctl start reinier-backend
sudo systemctl start reinier-frontend
```

---

## ✅ Checklist na Installatie

- [ ] FFmpeg geïnstalleerd en werkend
- [ ] MongoDB draait
- [ ] Backend service actief (poort 8001)
- [ ] Frontend service actief (poort 3000)
- [ ] Web interface bereikbaar via browser
- [ ] Stream kan starten (test met "Stream Starten")
- [ ] VLC kan stream ontvangen

---

## 🎉 Klaar!

Je Reinier de Graaf Radio Server is nu geïnstalleerd en klaar voor gebruik!

**Web Interface:** `http://[RASPBERRY_PI_IP]:3000`

Veel plezier! 🎧📻
