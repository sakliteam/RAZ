# 🚀 Reinier de Graaf Radio Server - Snelstart Gids

## Voor Raspberry Pi Gebruikers

### ⚡ Supersnel Installeren (3 commando's)

```bash
# 1. Download/kopieer alle bestanden naar Raspberry Pi
cd ~
# (gebruik git clone of scp om bestanden over te zetten)

# 2. Ga naar project directory
cd reinier-radio-server

# 3. Voer installatie script uit
sudo bash install.sh
```

**Klaar!** ✅ Na 10-20 minuten is alles geïnstalleerd en draait.

---

## 📱 Web Interface Openen

```
http://[JOUW_RASPBERRY_PI_IP]:3000
```

**Voorbeeld:** `http://192.168.1.100:3000`

*Weet je het IP niet? Typ op Raspberry Pi:*
```bash
hostname -I
```

---

## ✅ Status Controleren

```bash
# Quick check of alles draait
bash check_status.sh

# Of handmatig:
sudo systemctl status reinier-backend
sudo systemctl status reinier-frontend
```

---

## 🎮 Gebruik

1. **Open web interface** in je browser
2. **Configureer** je radio URL, resolutie, font, etc.
3. **Klik "Stream Starten"**
4. **Bekijk met VLC:**
   ```bash
   vlc udp://@239.255.0.1:5000
   ```

---

## 🔧 Handige Commando's

### Services Herstarten
```bash
sudo systemctl restart reinier-backend
sudo systemctl restart reinier-frontend
```

### Logs Bekijken
```bash
# Backend logs
sudo journalctl -u reinier-backend -f

# Frontend logs
sudo journalctl -u reinier-frontend -f
```

### Services Stoppen
```bash
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend
```

---

## 🐛 Hulp Nodig?

### Probleem: "kan niet starten"

```bash
# Check logs
sudo journalctl -u reinier-backend -n 50

# Herstart MongoDB
sudo systemctl restart mongodb

# Herstart backend
sudo systemctl restart reinier-backend
```

### Probleem: Web interface laadt niet

```bash
# Check status
bash check_status.sh

# Herstart frontend
sudo systemctl restart reinier-frontend
```

### Volledige Reset

```bash
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend
sudo systemctl restart mongodb
sleep 3
sudo systemctl start reinier-backend
sudo systemctl start reinier-frontend
```

---

## 📖 Meer Informatie

- **Volledige installatie gids:** `RASPBERRY_PI_INSTALLATIE.md`
- **Problemen oplossen:** Zie sectie "Problemen Oplossen" in `RASPBERRY_PI_INSTALLATIE.md`
- **FFmpeg test commando's:** `TEST_KOMUTLARI.md`

---

## 🎯 Aanbevolen Settings

### Raspberry Pi 3
- Resolutie: **540p** of **720p**
- Gebruik lagere lettergrootte voor betere performance

### Raspberry Pi 4/5
- Resolutie: **720p** of **1080p**
- Alle settings werken soepel

---

## 💡 Tips

1. **Test eerst met 720p** voordat je 1080p probeert
2. **Monitor CPU gebruik** met `htop` tijdens streaming
3. **Gebruik multicast** voor meerdere ontvangers
4. **Unicast** voor specifieke machine (vul IP in)

---

## ✨ Features Snel Overzicht

- ✅ **Hollandse interface** - alles in het Nederlands
- ✅ **Multicast default** - broadcast naar meerdere ontvangers
- ✅ **Unicast optie** - stream naar specifiek IP
- ✅ **Font aanpassing** - grootte en kleur voor TV overlay
- ✅ **ON AIR badge** - knippert tijdens actieve stream
- ✅ **Delft tijd** - automatisch lokale tijd
- ✅ **3 resolutie profielen** - 540p, 720p, 1080p

---

**Veel plezier met Reinier de Graaf Radio Server! 🎉📻**
