# 🚨 LEES DIT EERST! 🚨

## ⚡ Veelvoorkomende Errors & Snelle Fixes

### 1️⃣ MongoDB Error
```
E: Package 'mongodb' has no installation candidate
```
**✅ Oplossing: Gebruik LITE versie**
```bash
sudo bash install_lite.sh
```

### 2️⃣ Node.js Version Error
```
error react-router-dom@7.9.3: The engine "node" is incompatible
Expected version ">=20.0.0". Got "18.20.8"
```
**✅ Oplossing: Fix script uitvoeren**
```bash
bash fix_node_version.sh
sudo bash install_lite.sh
```

*(Scripts zijn automatisch geüpdatet, maar als je oude versie hebt, gebruik de fix)*

---

## 🎯 Waarom LITE Versie?

### ✨ Perfect voor Raspberry Pi!

- ✅ **GEEN MongoDB nodig** - gebruikt simpel JSON bestand
- ✅ **GEEN Docker nodig** - alles werkt direct
- ✅ **Sneller** - 50% minder geheugen gebruik
- ✅ **Stabiel** - geen complexe database issues
- ✅ **Zelfde features** - alles werkt exact hetzelfde!

---

## ⚡ Snelle Start (3 Stappen)

### Stap 1: Kopieer bestanden naar Raspberry Pi
```bash
# Via SCP vanaf je computer:
scp -r /app/* pi@[PI_IP]:/home/pi/reinier-radio-server/
```

### Stap 2: SSH naar Raspberry Pi
```bash
ssh pi@[PI_IP]
cd ~/reinier-radio-server
```

### Stap 3: Installeer (LITE versie)
```bash
sudo bash install_lite.sh
```

**⏱️ Wacht 10-15 minuten, klaar!**

---

## 🌐 Na Installatie

Open in je browser:
```
http://[RASPBERRY_PI_IP]:3000
```

**Bijvoorbeeld:** `http://192.168.1.100:3000`

---

## 📚 Meer Info

- **Installatie opties:** Lees `INSTALLATIE_KEUZE.md`
- **Volledige gids:** Lees `RASPBERRY_PI_INSTALLATIE.md`
- **Snelstart:** Lees `SNELSTART.md`

---

## 🐛 Problemen?

```bash
# Status checken
bash check_status.sh

# Services herstarten
sudo systemctl restart reinier-backend
sudo systemctl restart reinier-frontend
```

---

## 💡 Pro Tip

**LITE versie is aanbevolen voor ALLE Raspberry Pi gebruikers!**

Je hebt geen MongoDB nodig voor deze applicatie. JSON bestand werkt perfect en is veel betrouwbaarder op Raspberry Pi.

---

**Klaar om te beginnen? →** `sudo bash install_lite.sh`

🚀 Veel succes!
