# 📡 Stream Werkt Niet - Troubleshooting

## ❌ Probleem
Stream start maar geen video in VLC (multicast of unicast).

---

## 🔍 Diagnose (Stap voor Stap)

### Stap 1: Voer Test Script Uit

```bash
bash test_stream.sh
```

Dit toont:
- ✅ Of FFmpeg draait
- ✅ Backend logs
- ✅ Huidige instellingen
- ✅ Of radio URL bereikbaar is
- ✅ UDP configuratie
- ✅ Test commando's

---

### Stap 2: Test FFmpeg Direct

```bash
bash ffmpeg_simple_test.sh
```

**Dit test:**
- Radio URL bereikbaarheid
- FFmpeg installatie
- 30 seconden test stream
- Eenvoudige configuratie (zonder complexe filters)

**Open VLC terwijl test loopt:**
```bash
vlc udp://@127.0.0.1:5000
```

**Resultaat:**
- ✅ **Video zichtbaar** → FFmpeg werkt, probleem in applicatie
- ❌ **Geen video** → FFmpeg/network probleem

---

## 🐛 Veelvoorkomende Problemen

### Problem 1: Radio URL Onbereikbaar

**Symptomen:**
- FFmpeg start maar crasht direct
- Logs tonen "Connection refused" of "404"

**Oplossing:**
```bash
# Test radio URL
curl -I "https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8"

# Moet HTTP 200 geven
```

**Als URL niet werkt:**
1. Check internetverbinding
2. Probeer andere radio URL
3. Update in web interface

---

### Problem 2: FFmpeg Filter Complex Error

**Symptomen:**
- FFmpeg start maar stopt direct
- Logs tonen "filter" errors

**Oorzaak:**
- Timezone formatting (`%{localtime}`) niet ondersteund
- Font niet beschikbaar
- Te complexe filter chain

**Oplossing: Gebruik Simpele FFmpeg Versie**

Maak `/tmp/test_ffmpeg.sh`:
```bash
#!/bin/bash
ffmpeg \
  -re \
  -i "https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8" \
  -f lavfi \
  -i "color=c=black:s=1280x720:r=25" \
  -filter_complex "[1:v]drawtext=text='REINIER RADIO':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2[v]" \
  -map '[v]' \
  -map 0:a \
  -c:v libx264 \
  -preset ultrafast \
  -b:v 2M \
  -c:a aac \
  -b:a 128k \
  -f mpegts \
  udp://127.0.0.1:5000?pkt_size=1316
```

```bash
chmod +x /tmp/test_ffmpeg.sh
/tmp/test_ffmpeg.sh &

# Test met VLC
vlc udp://@127.0.0.1:5000
```

---

### Problem 3: VLC Kan Stream Niet Vinden

**Symptomen:**
- FFmpeg draait
- VLC toont "Kan bron niet openen"

**Mogelijke Oorzaken:**

**A. Verkeerde IP/Poort**
```bash
# Check wat FFmpeg gebruikt
ps aux | grep ffmpeg | grep udp

# Moet matchen met VLC commando
```

**B. Firewall Blokkeert**
```bash
# Check firewall
sudo ufw status

# Open UDP poort (als firewall actief)
sudo ufw allow 5000/udp
```

**C. Multicast Routing**

Voor multicast moet network multicast supporten:
```bash
# Check multicast routes
ip route show | grep 224

# Als leeg, multicast werkt mogelijk niet op je network
# Gebruik UNICAST in plaats daarvan
```

---

### Problem 4: Stream Buffert/Stopt

**Symptomen:**
- Video start maar stopt na paar seconden
- Veel buffering

**Oplossingen:**

**A. Verlaag Resolutie**
- 1080p → 720p
- 720p → 540p

**B. Verlaag Bitrate**

Edit server.py, verlaag bitrate:
```python
'-b:v', '1M',      # was 2M
'-maxrate', '1M',  # was 2M
```

**C. Check CPU**
```bash
htop
# Als CPU 100%, gebruik lagere preset:
# -preset veryfast (ipv ultrafast)
```

---

## 🔧 Backend FFmpeg Command Repareren

Als filter_complex problemen geeft, vervang in `server.py`:

**VIND (regel 87-89):**
```python
'-filter_complex',
f"[1:v]drawtext=text='Reinier de Graaf Radio Server':fontsize={int(settings.font_size * 0.6)}:fontcolor={settings.font_color}:x=(w-tw)/2:y=50:box=1:boxcolor=black@0.6:boxborderw=8,"
f"drawtext=text='%{{localtime\\:%A %d %B %Y %H\\:%M\\:%S}}':fontsize={settings.font_size}:fontcolor={settings.font_color}:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.6:boxborderw=10,"
f"drawtext=text='Delft, Nederland':fontsize={int(settings.font_size * 0.5)}:fontcolor={settings.font_color}:x=(w-tw)/2:y=h-80:box=1:boxcolor=black@0.6:boxborderw=8[v]",
```

**VERVANG MET (simpel):**
```python
'-filter_complex',
f"[1:v]drawtext=text='Reinier de Graaf Radio Server':fontsize={settings.font_size}:fontcolor={settings.font_color}:x=(w-tw)/2:y=(h-th)/2[v]",
```

**Herstart backend:**
```bash
sudo systemctl restart reinier-backend
```

---

## 📊 Debug Checklist

- [ ] FFmpeg geïnstalleerd: `ffmpeg -version`
- [ ] FFmpeg process draait: `pgrep ffmpeg`
- [ ] Radio URL bereikbaar: `curl -I [URL]`
- [ ] Backend logs checken: `journalctl -u reinier-backend -n 50`
- [ ] Simpele test werkt: `bash ffmpeg_simple_test.sh`
- [ ] VLC test lokaal: `vlc udp://@127.0.0.1:5000`
- [ ] Firewall gecheckt: `sudo ufw status`
- [ ] CPU gebruik OK: `htop`

---

## 🎯 Quick Fix Scenarios

### Scenario A: "Alles lijkt goed maar geen video"

```bash
# 1. Stop stream via web interface
# 2. Test simpel:
bash ffmpeg_simple_test.sh

# 3. Open VLC:
vlc udp://@127.0.0.1:5000

# 4. Zie je video? 
#    JA  → Backend FFmpeg command is probleem
#    NEE → FFmpeg/network probleem
```

### Scenario B: "FFmpeg start niet"

```bash
# Check logs
sudo journalctl -u reinier-backend -n 100 | grep -i error

# Meest waarschijnlijk:
# - Radio URL fout
# - FFmpeg niet geïnstalleerd
# - Permissions probleem
```

### Scenario C: "VLC vindt stream niet"

```bash
# Check of FFmpeg écht UDP output maakt
sudo netstat -ulnp | grep 5000

# Moet proces tonen op poort 5000
# Zo niet: FFmpeg output URL is fout
```

---

## 💡 Pro Tips

1. **Test altijd eerst lokaal (127.0.0.1)** voordat je multicast/unicast probeert
2. **Check logs realtime:** `sudo journalctl -u reinier-backend -f`
3. **Gebruik simpele FFmpeg eerst**, dan complexe filters toevoegen
4. **VLC heeft 3-5 seconden nodig** om stream te starten, wees geduldig
5. **Raspberry Pi 3: gebruik 540p**, CPU is limiting factor

---

## 🆘 Laatste Redmiddel

Als niets werkt:

```bash
# Stop alles
sudo pkill -9 ffmpeg
sudo systemctl stop reinier-backend

# Start backend handmatig met debug
cd /home/RADIOSERVER/reinier-radio-server/backend
source venv/bin/activate
python -m uvicorn server:app --host 0.0.0.0 --port 8001

# Bekijk output, start stream via web interface
# Errors komen direct in terminal
```

---

**Hulp nodig? Run:** `bash test_stream.sh` voor volledige diagnose!
