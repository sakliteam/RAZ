# 🔧 Node.js Version Error - Hızlı Çözüm

## ❌ Hata Mesajı

```
error react-router-dom@7.9.3: The engine "node" is incompatible with this module. 
Expected version ">=20.0.0". Got "18.20.8"
```

---

## ✅ Hızlı Çözüm (1 Komut)

```bash
bash fix_node_version.sh
```

**Bu script:**
- ✅ React Router'ı v6'ya düşürür (Node 18 uyumlu)
- ✅ node_modules ve yarn.lock temizler
- ✅ Dependencies'i yeniden yükler
- ✅ 2 dakikada tamamlanır

**Sonra tekrar dene:**
```bash
sudo bash install_lite.sh
```

---

## 🔍 Ne Oldu?

- React Router **v7** çok yeni (Node.js 20+ gerektirir)
- Raspberry Pi'de genellikle **Node 18** yüklü
- **Çözüm:** React Router v6 kullan (aynı özellikler, uyumlu)

---

## 🛠️ Manuel Çözüm

Eğer script çalışmazsa:

### Adım 1: package.json Düzenle
```bash
cd ~/reinier-radio-server/frontend
nano package.json
```

**Şunu bul:**
```json
"react-router-dom": "^7.5.1",
```

**Şununla değiştir:**
```json
"react-router-dom": "^6.28.0",
```

**Kaydet:** `Ctrl+X`, `Y`, `Enter`

### Adım 2: Temizle ve Yeniden Yükle
```bash
rm -rf node_modules
rm -rf yarn.lock
yarn install
```

### Adım 3: Kurulumu Tekrar Dene
```bash
cd ~/reinier-radio-server
sudo bash install_lite.sh
```

---

## 🚀 Alternatif: Node.js 20 Yükselt (İsteğe Bağlı)

Eğer Node.js 20 kullanmak istersen:

```bash
# Eski Node'u kaldır
sudo apt remove nodejs npm -y

# NodeSource repo ekle (Node 20)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -

# Node 20 kur
sudo apt install -y nodejs

# Kontrol et
node --version  # v20.x.x olmalı

# Yarn yeniden kur
sudo npm install -g yarn

# Şimdi normal kurulumu dene
sudo bash install_lite.sh
```

---

## ✅ Doğrulama

Kurulum başarılı olduğunda:

```bash
# Services çalışıyor mu?
sudo systemctl status reinier-backend
sudo systemctl status reinier-frontend

# Web interface çalışıyor mu?
curl http://localhost:3000
```

---

## 📝 Özet

**En Kolay Yol:**
```bash
bash fix_node_version.sh
sudo bash install_lite.sh
```

**Artık çalışmalı!** ✅

---

## 💡 Not

Bu fix otomatik olarak **yeni install_lite.sh** ve **install.sh** scriptlerine eklendi.

Eğer yeni dosyaları indirirsen, bu hatayı hiç görmeyeceksin! 🎉
