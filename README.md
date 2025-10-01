# 📻 Radyo Video Yayın Sistemi

Raspberry Pi ve Linux sistemler için FFmpeg tabanlı radyo akışı video yayın dönüştürücüsü.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%20%7C%20Linux-red.svg)

## 🎯 Özellikler

- ✅ Radyo akışını (M3U8, MP3, vb.) canlı video kanalına dönüştürme
- ✅ Saat/tarih overlay görüntüsü ile video oluşturma
- ✅ 540p, 720p, 1080p çözünürlük desteği
- ✅ Unicast ve Multicast yayın seçenekleri
- ✅ Modern web panel ile kolay kontrol
- ✅ Gerçek zamanlı durum takibi
- ✅ Otomatik servis yönetimi (systemd)
- ✅ MongoDB ile ayar saklama
- ✅ FFmpeg ile profesyonel video encoding

## 🖥️ Teknolojiler

**Backend:**
- FastAPI (Python)
- Motor (Async MongoDB)
- FFmpeg subprocess kontrolü
- uvicorn ASGI server

**Frontend:**
- React 19
- Tailwind CSS
- Shadcn/UI components
- Axios
- Sonner (toast bildirimleri)

**Database:**
- MongoDB

**Video Processing:**
- FFmpeg (H.264 + AAC)

## 📋 Gereksinimler

### Donanım
- Raspberry Pi 3/4/5 veya Linux PC
- Minimum 2GB RAM
- İnternet bağlantısı

### Yazılım
- Linux (Raspberry Pi OS önerilir)
- Python 3.8+
- Node.js 16+
- MongoDB
- FFmpeg

## 🚀 Hızlı Başlangıç

### 1. FFmpeg Kurulumu

```bash
sudo apt update
sudo apt install ffmpeg -y
ffmpeg -version
```

### 2. MongoDB Kurulumu

```bash
# MongoDB kurulumu
sudo apt install mongodb-org -y

# Başlat ve etkinleştir
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 3. Python Bağımlılıkları

```bash
cd /app/backend
pip install -r requirements.txt
```

### 4. Frontend Bağımlılıkları

```bash
cd /app/frontend
npm install
# veya
yarn install
```

### 5. Uygulamayı Başlat

**Backend:**
```bash
cd /app/backend
python3 -m uvicorn server:app --host 0.0.0.0 --port 8001
```

**Frontend:**
```bash
cd /app/frontend
npm start
```

**Web Panel:** http://localhost:3000

## 🎮 Kullanım

### Web Panel Üzerinden

1. **Radyo URL'sini girin** - M3U8, MP3 veya desteklenen format
2. **Çözünürlük seçin** - 540p, 720p veya 1080p
3. **Çıkış modu** - Unicast veya Multicast
4. **Multicast adresi** - Multicast modunda (örn: 239.255.0.1:5000)
5. **Tarih/Saat formatı** - strftime formatında (örn: %Y-%m-%d %H:%M:%S)
6. **"Ayarları Kaydet"** - Değişiklikleri uygulayın
7. **"Yayını Başlat"** - Video akışını başlatın

### VLC ile İzleme

**Unicast:**
```bash
vlc udp://@127.0.0.1:5000
```

**Multicast:**
```bash
vlc udp://@239.255.0.1:5000
```

## 🔧 Systemd Servisi (Otomatik Başlatma)

Sistem açılışında otomatik başlatma için:

```bash
# Servis dosyasını kopyala
sudo cp /app/radio-video-stream.service /etc/systemd/system/

# Kullanıcı adını düzenle (opsiyonel)
sudo nano /etc/systemd/system/radio-video-stream.service

# Servisi etkinleştir
sudo systemctl daemon-reload
sudo systemctl enable radio-video-stream
sudo systemctl start radio-video-stream

# Durum kontrolü
sudo systemctl status radio-video-stream
```

**Servis Komutları:**
```bash
sudo systemctl start radio-video-stream    # Başlat
sudo systemctl stop radio-video-stream     # Durdur
sudo systemctl restart radio-video-stream  # Yeniden başlat
sudo journalctl -u radio-video-stream -f   # Log'ları görüntüle
```

## 📁 Proje Yapısı

```
/app/
├── backend/
│   ├── server.py              # FastAPI backend
│   ├── requirements.txt       # Python bağımlılıkları
│   └── .env                   # Ortam değişkenleri
├── frontend/
│   ├── src/
│   │   ├── App.js            # Ana React component
│   │   ├── App.css           # Stil dosyası
│   │   └── components/ui/    # Shadcn UI components
│   ├── package.json          # Node bağımlılıkları
│   └── .env                  # Frontend ortam değişkenleri
├── radio-video-stream.service # Systemd servis dosyası
├── KURULUM.md                # Detaylı kurulum kılavuzu
└── README.md                 # Bu dosya
```

## 🔌 API Endpoints

### GET `/api/settings`
Mevcut yayın ayarlarını getirir.

**Response:**
```json
{
  "id": "uuid",
  "radio_url": "https://...",
  "resolution": "720p",
  "output_mode": "unicast",
  "multicast_address": "239.255.0.1:5000",
  "datetime_format": "%Y-%m-%d %H:%M:%S",
  "is_running": false
}
```

### POST `/api/settings`
Yayın ayarlarını günceller (yayın durdurulmuş olmalı).

### POST `/api/start`
Video yayınını başlatır.

### POST `/api/stop`
Video yayınını durdurur.

### GET `/api/status`
Yayın durumunu kontrol eder.

📚 **Detaylı dokümantasyon için KURULUM.md dosyasına bakın.**

---

**Geliştirici:** Radio Video Stream System
**Versiyon:** 1.0.0

🚀 **Başarılar!**
