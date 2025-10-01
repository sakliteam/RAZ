# 🍓 Reinier de Graaf Radio Server - Installatie Opties

## ❓ Welke Versie Moet Ik Kiezen?

### 📦 Volledige Versie (`install.sh`)
**Aanbevolen voor: Raspberry Pi 4/5 met voldoende geheugen**

✅ **Voordelen:**
- MongoDB database (professioneel)
- Betere prestaties voor veel data
- Schaalbaar

❌ **Nadelen:**
- Vereist Docker voor MongoDB
- Meer geheugen gebruik (500MB+)
- Iets langere installatietijd

**Installeer:**
```bash
sudo bash install.sh
```

---

### 🚀 LITE Versie (`install_lite.sh`)  
**Aanbevolen voor: Raspberry Pi 3 of als MongoDB problemen geeft**

✅ **Voordelen:**
- ✨ **GEEN MongoDB/Docker nodig!**
- Gebruikt simpel JSON bestand
- Sneller en lichter (~50MB geheugen)
- Perfecte installatie zonder errors
- Alles werkt out-of-the-box

❌ **Nadelen:**
- Geen database (maar dat is niet erg voor deze applicatie)

**Installeer:**
```bash
sudo bash install_lite.sh
```

---

## 🎯 Aanbeveling

### ⚡ **Start met LITE versie!**

De LITE versie is **perfect geschikt** voor dit project omdat:
1. Je hebt maar 1 gebruiker (jijzelf)
2. Instellingen worden lokaal opgeslagen
3. Geen complexe database queries nodig
4. **100% stabiel en snel**
5. **Geen MongoDB errors!**

Je kunt altijd later upgraden naar de volledige versie als dat nodig is.

---

## 📝 Stap-voor-stap Installatie (LITE)

### Stap 1: Bestanden Kopiëren naar Raspberry Pi

**Optie A: Via SCP (vanaf je computer)**
```bash
scp -r /pad/naar/app/* pi@192.168.1.X:/home/pi/reinier-radio-server/
```

**Optie B: Via USB stick**
1. Kopieer alle bestanden naar USB
2. Stop USB in Raspberry Pi
3. Kopieer: `cp -r /media/usb/* ~/reinier-radio-server/`

**Optie C: Via Git (als project online staat)**
```bash
cd ~
git clone https://github.com/jouw-username/reinier-radio-server.git
```

### Stap 2: SSH Verbinding

```bash
ssh pi@192.168.1.X
# Standaard wachtwoord: raspberry
```

### Stap 3: Installatie Uitvoeren

```bash
cd ~/reinier-radio-server
sudo bash install_lite.sh
```

⏱️ **Wacht 10-15 minuten** (gaat snel zonder MongoDB!)

### Stap 4: Web Interface Openen

```
http://192.168.1.X:3000
```

**Klaar!** ✅

---

## 🐛 MongoDB Error Oplossen (als je volledige versie wilt)

Als je `install.sh` gebruikt en MongoDB errors krijgt:

### Oplossing 1: Installeer Docker eerst

```bash
# Docker installeren
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi

# Herstart Raspberry Pi
sudo reboot

# Na reboot, voer install.sh opnieuw uit
cd ~/reinier-radio-server
sudo bash install.sh
```

### Oplossing 2: Gebruik LITE versie (aanbevolen!)

```bash
sudo bash install_lite.sh
```

---

## 🔄 Van LITE naar Volledige Versie Upgraden

Als je later wilt upgraden:

```bash
# Stop LITE services
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend

# Installeer Docker + MongoDB
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

docker run -d --name mongodb --restart always \
  -p 27017:27017 -v mongodb_data:/data/db mongo:4.4

# Hernoem server bestanden
cd ~/reinier-radio-server/backend
mv server.py server_lite_backup.py
mv server_original.py server.py

# Installeer MongoDB dependencies
source venv/bin/activate
pip install pymongo motor
deactivate

# Herstart services
sudo systemctl start reinier-backend
sudo systemctl start reinier-frontend
```

---

## ✅ Verificatie

Na installatie, controleer:

```bash
# Quick check
bash check_status.sh

# Of handmatig:
sudo systemctl status reinier-backend
sudo systemctl status reinier-frontend
```

**Moet alles ✓ groen zijn!**

---

## 📞 Hulp Nodig?

**MongoDB error (`has no installation candidate`):**
→ Gebruik **`install_lite.sh`** - werkt gegarandeerd!

**Docker errors:**
→ Gebruik **`install_lite.sh`** - geen Docker nodig!

**Andere problemen:**
→ Run `bash check_status.sh` voor diagnostics

---

## 💡 Tip

Voor de meeste gebruikers is **LITE versie meer dan genoeg**! 

Het enige verschil is de database, maar voor een radio server die lokaal draait maakt dit geen praktisch verschil. JSON bestand werkt perfect! ✨

---

**Veel succes met de installatie! 🚀📻**
