# 🔒 Permission Error Fix

## ❌ Hata Mesajı

```
[eslint] EACCES: permission denied, mkdir '/home/RADIOSERVER/frontend/node_modules/.cache'
```

of

```
Error: EACCES: permission denied, open '...'
```

---

## 🎯 Neden Oluyor?

Kurulum `sudo` ile (root olarak) yapıldığında, tüm dosyalar **root kullanıcısına** ait oluyor. 

Services ise **normal kullanıcı** (pi) ile çalıştığı için yazma izni yok.

---

## ✅ Hızlı Çözüm (1 Komut)

```bash
sudo bash fix_permissions.sh
```

**Script otomatik olarak:**
- ✅ Tüm dosyaların sahipliğini düzeltir
- ✅ Cache klasörlerini yeniden oluşturur
- ✅ Doğru permissionları ayarlar
- ✅ Services'i yeniden başlatır
- ✅ 30 saniyede tamamlanır

**Sonra tarayıcıda tekrar dene:**
```
http://[RASPBERRY_PI_IP]:3000
```

---

## 🔧 Manuel Çözüm

Eğer script çalışmazsa:

### Adım 1: Services Durdur
```bash
sudo systemctl stop reinier-backend
sudo systemctl stop reinier-frontend
```

### Adım 2: Sahipliği Değiştir
```bash
# RADIOSERVER kullanıcısı için (kendi kullanıcı adını kullan)
sudo chown -R RADIOSERVER:RADIOSERVER /home/RADIOSERVER/reinier-radio-server

# Veya pi kullanıcısı için:
sudo chown -R pi:pi /home/pi/reinier-radio-server
```

### Adım 3: Cache Klasörünü Düzelt
```bash
cd /home/RADIOSERVER/reinier-radio-server/frontend
sudo rm -rf node_modules/.cache
mkdir -p node_modules/.cache
sudo chown -R RADIOSERVER:RADIOSERVER node_modules/.cache
chmod -R 755 node_modules/.cache
```

### Adım 4: Services Başlat
```bash
sudo systemctl start reinier-backend
sudo systemctl start reinier-frontend
```

### Adım 5: Kontrol Et
```bash
sudo systemctl status reinier-frontend
```

---

## 🔍 Doğrulama

Permission'ların doğru olduğunu kontrol et:

```bash
cd /home/RADIOSERVER/reinier-radio-server

# Dosya sahipliğini kontrol et
ls -la

# RADIOSERVER (veya pi) görmelisin, root DEĞIL:
# drwxr-xr-x  5 RADIOSERVER RADIOSERVER  4096 Jan  1 12:00 backend
# drwxr-xr-x 10 RADIOSERVER RADIOSERVER  4096 Jan  1 12:00 frontend
```

**Eğer "root root" görürsen, fix_permissions.sh'yi çalıştır!**

---

## 🚀 Önlem (Gelecek İçin)

**Yeni kurulum scriptleri artık otomatik fix içeriyor!**

```bash
sudo bash install_lite.sh  # Otomatik permission fix var!
```

Ama eğer **eski script** kullandıysan veya manuel kurulum yaptıysan, `fix_permissions.sh` çalıştırmalısın.

---

## 📋 Checklist

Permission sorunlarını kontrol et:

- [ ] `sudo bash fix_permissions.sh` çalıştırdın
- [ ] Services yeniden başladı
- [ ] Web interface açılıyor
- [ ] Loglar error göstermiyor

**Logları kontrol et:**
```bash
# Frontend logs
sudo journalctl -u reinier-frontend -n 50

# Backend logs
sudo journalctl -u reinier-backend -n 50
```

---

## 💡 İpuçları

**✅ YAPILMASI GEREKENLER:**
- Kurulumu `sudo` ile yap (root yetkisi gerekli)
- Kurulum sonrası `fix_permissions.sh` çalıştır
- Services'i normal kullanıcı ile çalıştır

**❌ YAPILMAMASI GEREKENLER:**
- Services'i root olarak çalıştırma
- Dosyaları root olarak bırakma
- Cache klasörlerini silmeden permission değiştirme

---

## 🎉 Çözüldü mü?

Web interface'i aç:
```
http://[IP]:3000
```

Eğer hala error varsa:

```bash
# Tüm kontrolleri yap
bash check_status.sh

# Service loglarını incele
sudo journalctl -u reinier-frontend -f
```

---

**Not:** Yeni install scriptleri (`install_lite.sh` ve `install.sh`) artık kurulum sırasında permission'ları otomatik düzeltiyor! 🎊
