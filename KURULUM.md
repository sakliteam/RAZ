# Radyo Video Yayın Sistemi - Kurulum Kılavuzu

## 📋 Gereksinimler

### Donanım
- Raspberry Pi 3/4/5 veya herhangi bir Linux bilgisayar
- En az 2GB RAM
- İnternet bağlantısı

### Yazılım
- Linux işletim sistemi (Raspberry Pi OS önerilir)
- Python 3.8 veya üzeri
- Node.js 16 veya üzeri
- MongoDB
- FFmpeg

---

## 🔧 Adım 1: Sistem Güncellemesi

```bash
sudo apt update
sudo apt upgrade -y
```

---

## 📦 Adım 2: FFmpeg Kurulumu

FFmpeg, radyo akışını video formatına dönüştürmek için kullanılır.

```bash
sudo apt install ffmpeg -y
```

**Kurulum Kontrolü:**
```bash
ffmpeg -version
```

---

## 🗄️ Adım 3: MongoDB Kurulumu

### Raspberry Pi için MongoDB Kurulumu:

```bash
# MongoDB repository ekleyin
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Güncelleyin ve kurun
sudo apt update
sudo apt install mongodb-org -y

# MongoDB'yi başlatın
sudo systemctl start mongod
sudo systemctl enable mongod

# Kontrol edin
sudo systemctl status mongod
```

**Not:** Raspberry Pi için alternatif olarak Docker ile MongoDB da kullanabilirsiniz:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

---

## 🐍 Adım 4: Python Bağımlılıkları

```bash
cd /app/backend

# Virtual environment oluşturun (opsiyonel ama önerilir)
python3 -m venv venv
source venv/bin/activate

# Bağımlılıkları yükleyin
pip install -r requirements.txt
```

---

## 📱 Adım 5: Frontend Kurulumu

```bash
cd /app/frontend

# Node.js bağımlılıklarını yükleyin
npm install
# veya
yarn install
```

---

## ⚙️ Adım 6: Ortam Değişkenleri

### Backend (.env dosyası zaten mevcut)

`/app/backend/.env` dosyası:
```
MONGO_URL="mongodb://localhost:27017"
DB_NAME="radio_video_stream"
CORS_ORIGINS="*"
```

### Frontend (.env dosyası zaten mevcut)

`/app/frontend/.env` dosyası:
```
REACT_APP_BACKEND_URL=http://localhost:8001
WDS_SOCKET_PORT=443
```

**Önemli:** Eğer sistemi Raspberry Pi'nin IP'si üzerinden erişmek istiyorsanız, `REACT_APP_BACKEND_URL` değerini değiştirin:
```
REACT_APP_BACKEND_URL=http://192.168.1.100:8001
```

---

## 🚀 Adım 7: Manuel Başlatma (Test için)

### Terminal 1 - Backend:
```bash
cd /app/backend
python3 -m uvicorn server:app --host 0.0.0.0 --port 8001 --reload
```

### Terminal 2 - Frontend:
```bash
cd /app/frontend
npm start
# veya
yarn start
```

**Web panele erişim:** 
- Frontend: http://localhost:3000
- Backend API: http://localhost:8001/api

---

## 🔄 Adım 8: Systemd Servisi Kurulumu (Otomatik Başlatma)

Backend'in her sistem açılışında otomatik başlaması için:

```bash
# Servis dosyasını kopyalayın
sudo cp /app/radio-video-stream.service /etc/systemd/system/

# Kullanıcı adını düzenleyin (gerekirse)
sudo nano /etc/systemd/system/radio-video-stream.service
# "User=pi" satırını kendi kullanıcı adınızla değiştirin

# Servisi etkinleştirin
sudo systemctl daemon-reload
sudo systemctl enable radio-video-stream.service
sudo systemctl start radio-video-stream.service

# Durumu kontrol edin
sudo systemctl status radio-video-stream.service
```

### Servis Komutları:
```bash
# Servisi başlat
sudo systemctl start radio-video-stream

# Servisi durdur
sudo systemctl stop radio-video-stream

# Servisi yeniden başlat
sudo systemctl restart radio-video-stream

# Servis loglarını görüntüle
sudo journalctl -u radio-video-stream -f
```

---

## 🌐 Adım 9: Frontend Production Build (Opsiyonel)

Production ortamı için frontend'i build edip nginx ile servis edebilirsiniz:

```bash
cd /app/frontend
npm run build
# veya
yarn build
```

### Nginx Kurulumu ve Yapılandırması:
```bash
sudo apt install nginx -y

# Nginx config
sudo nano /etc/nginx/sites-available/radio-video-stream
```

**Nginx config içeriği:**
```nginx
server {
    listen 80;
    server_name localhost;

    root /app/frontend/build;
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

```bash
# Config'i etkinleştir
sudo ln -s /etc/nginx/sites-available/radio-video-stream /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🎬 Kullanım

1. **Web paneli açın:** http://localhost:3000 (veya Raspberry Pi IP'si)

2. **Radyo URL'sini girin:** Varsayılan olarak bir URL zaten girilmiştir, değiştirebilirsiniz

3. **Çözünürlük seçin:** 540p, 720p veya 1080p

4. **Çıkış modunu belirleyin:** 
   - **Unicast:** Yerel ağda tek bir alıcıya
   - **Multicast:** Birden fazla alıcıya aynı anda

5. **Multicast adresi ayarlayın** (Multicast seçildiyse)

6. **Tarih/Saat formatı:** İsterseniz değiştirin (strftime formatı)

7. **"Yayını Başlat"** butonuna tıklayın

8. **Video akışını izleyin:**
   - Unicast: `udp://127.0.0.1:5000`
   - Multicast: `udp://239.255.0.1:5000` (veya belirlediğiniz adres)

### VLC ile İzleme:

```bash
# Unicast için
vlc udp://@127.0.0.1:5000

# Multicast için
vlc udp://@239.255.0.1:5000
```

---

## 🐛 Sorun Giderme

### FFmpeg Bulunamadı Hatası:
```bash
which ffmpeg
# Eğer boş dönerse FFmpeg kurulu değildir
sudo apt install ffmpeg -y
```

### Port Kullanımda Hatası:
```bash
# Port 8001'i kullanan işlemi bulun
sudo lsof -i :8001

# İşlemi sonlandırın
sudo kill -9 <PID>
```

### MongoDB Bağlantı Hatası:
```bash
# MongoDB durumunu kontrol edin
sudo systemctl status mongod

# Başlatın
sudo systemctl start mongod
```

### Backend Logları:
```bash
# Eğer systemd servisi kullanıyorsanız
sudo journalctl -u radio-video-stream -f

# Manuel başlatma ile çalıştırıyorsanız terminal çıktısını kontrol edin
```

### FFmpeg Process Durmuyor:
```bash
# Tüm FFmpeg işlemlerini sonlandır
sudo pkill -9 ffmpeg
```

---

## 📝 Notlar

- **FFmpeg kaynak kullanımı:** 1080p yayın CPU yoğun olabilir, Raspberry Pi 3'te 720p önerilir
- **Ağ bant genişliği:** Multicast için ağınızın multicast desteklemesi gerekir
- **Güvenlik:** Production ortamında CORS ayarlarını ve firewall kurallarını yapılandırın
- **Yeniden başlatma:** Sistem yeniden başladığında systemd servisi otomatik çalışır

---

## 🎯 Varsayılan Ayarlar

- **Video Çözünürlük:** 720p (1280x720)
- **Ses Codec:** AAC @ 128kbps
- **Video Codec:** H.264 (libx264, ultrafast preset)
- **Video Bitrate:** 2 Mbps
- **Multicast Adres:** 239.255.0.1:5000
- **Tarih/Saat Format:** %Y-%m-%d %H:%M:%S

---

## 📞 Destek

Herhangi bir sorun yaşarsanız:
1. Backend loglarını kontrol edin
2. FFmpeg komutunun çalışıp çalışmadığını test edin
3. MongoDB bağlantısını doğrulayın
4. Port erişimlerini kontrol edin

**Başarılar! 🚀**
