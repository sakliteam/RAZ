# FFmpeg Test Komutları

Bu dosya, sistemi test etmek için kullanabileceğiniz FFmpeg komutlarını içerir.

## 🧪 Manuel FFmpeg Testi

Raspberry Pi'nizde FFmpeg'in doğru çalıştığını test etmek için:

### Test 1: Temel Audio → Video Dönüşümü

```bash
ffmpeg -re \
  -i https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8 \
  -f lavfi -i color=c=black:s=1280x720:r=25 \
  -filter_complex "[1:v]drawtext=text='%{localtime\:%Y-%m-%d %H\:%M\:%S}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=10[v]" \
  -map '[v]' -map 0:a \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -b:v 2M -maxrate 2M -bufsize 4M \
  -c:a aac -b:a 128k \
  -t 30 \
  -f mpegts test_output.ts
```

**Açıklama:** 30 saniyelik test videosu oluşturur (test_output.ts)

**Test etmek için:**
```bash
vlc test_output.ts
```

### Test 2: UDP Unicast Çıkış

```bash
ffmpeg -re \
  -i https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8 \
  -f lavfi -i color=c=black:s=1280x720:r=25 \
  -filter_complex "[1:v]drawtext=text='%{localtime\:%Y-%m-%d %H\:%M\:%S}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=10[v]" \
  -map '[v]' -map 0:a \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -b:v 2M -maxrate 2M -bufsize 4M \
  -c:a aac -b:a 128k \
  -f mpegts udp://127.0.0.1:5000?pkt_size=1316
```

**İzlemek için (başka terminal):**
```bash
vlc udp://@127.0.0.1:5000
```

### Test 3: UDP Multicast Çıkış

```bash
ffmpeg -re \
  -i https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8 \
  -f lavfi -i color=c=black:s=1280x720:r=25 \
  -filter_complex "[1:v]drawtext=text='%{localtime\:%Y-%m-%d %H\:%M\:%S}':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=10[v]" \
  -map '[v]' -map 0:a \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -b:v 2M -maxrate 2M -bufsize 4M \
  -c:a aac -b:a 128k \
  -f mpegts udp://239.255.0.1:5000?pkt_size=1316
```

**İzlemek için:**
```bash
vlc udp://@239.255.0.1:5000
```

### Test 4: 1080p Yüksek Çözünürlük

```bash
ffmpeg -re \
  -i https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8 \
  -f lavfi -i color=c=black:s=1920x1080:r=25 \
  -filter_complex "[1:v]drawtext=text='%{localtime\:%Y-%m-%d %H\:%M\:%S}':fontsize=96:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=15[v]" \
  -map '[v]' -map 0:a \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -b:v 3M -maxrate 3M -bufsize 6M \
  -c:a aac -b:a 128k \
  -f mpegts udp://127.0.0.1:5000?pkt_size=1316
```

### Test 5: 540p Düşük Çözünürlük (Raspberry Pi 3 için)

```bash
ffmpeg -re \
  -i https://op25-par.streamabc.net/hls/d3ep2fcbnhfc72r905fg/redbm-razo-mp3-192-3960759.m3u8 \
  -f lavfi -i color=c=black:s=960x540:r=25 \
  -filter_complex "[1:v]drawtext=text='%{localtime\:%Y-%m-%d %H\:%M\:%S}':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=black@0.5:boxborderw=8[v]" \
  -map '[v]' -map 0:a \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -b:v 1500k -maxrate 1500k -bufsize 3M \
  -c:a aac -b:a 128k \
  -f mpegts udp://127.0.0.1:5000?pkt_size=1316
```

## 🔍 FFmpeg Durumunu Kontrol Etme

### Çalışan FFmpeg process'lerini görüntüle:
```bash
ps aux | grep ffmpeg
```

### CPU kullanımını monitör et:
```bash
htop
# veya
top
```

### FFmpeg çıktısını log dosyasına kaydet:
```bash
ffmpeg [komutlar...] > ffmpeg_output.log 2>&1 &
tail -f ffmpeg_output.log
```

## 🛑 FFmpeg Process'ini Durdurma

### Graceful stop:
```bash
pkill -TERM ffmpeg
```

### Force kill:
```bash
pkill -9 ffmpeg
```

### Belirli PID'yi durdur:
```bash
kill -TERM <PID>
# veya force
kill -9 <PID>
```

## 📊 Performans İzleme

### Gerçek zamanlı bandwidth izleme:
```bash
iftop
# veya
nload
```

### Video stream kalitesini kontrol:
```bash
ffprobe udp://127.0.0.1:5000
```

## 🎨 Farklı Tarih/Saat Formatları

### Format 1: DD/MM/YYYY HH:MM
```bash
drawtext=text='%{localtime\:%d/%m/%Y %H\:%M}'
```

### Format 2: Tam Tarih
```bash
drawtext=text='%{localtime\:%A, %d %B %Y - %H\:%M\:%S}'
```

### Format 3: ISO 8601
```bash
drawtext=text='%{localtime\:%Y-%m-%dT%H\:%M\:%S}'
```

### Format 4: Sadece Saat
```bash
drawtext=text='%{localtime\:%H\:%M\:%S}'
```

## 🎯 Test Senaryoları

### Senaryo 1: Hızlı Test (30 saniye)
```bash
# 30 saniyelik test yayını
ffmpeg -re -i [RADIO_URL] ... -t 30 -f mpegts test.ts
vlc test.ts
```

### Senaryo 2: Uzun Süreli Stabilite Testi
```bash
# 1 saatlik test (CPU ve RAM kullanımını izleyin)
ffmpeg -re -i [RADIO_URL] ... -t 3600 -f mpegts udp://127.0.0.1:5000
```

### Senaryo 3: Çoklu Alıcı Testi (Multicast)
```bash
# Terminal 1: Yayını başlat
ffmpeg -re -i [RADIO_URL] ... -f mpegts udp://239.255.0.1:5000

# Terminal 2: İlk alıcı
vlc udp://@239.255.0.1:5000

# Terminal 3: İkinci alıcı
vlc udp://@239.255.0.1:5000
```

## 📈 Başarı Kriterleri

✅ **Başarılı Test:**
- FFmpeg process başladı
- CPU kullanımı kabul edilebilir seviyede (<%80)
- Video ve audio senkronize
- Donma veya kesinti yok
- VLC ile sorunsuz izlenebiliyor

❌ **Başarısız Test:**
- FFmpeg hata veriyor
- CPU %100 kullanım
- Video/audio desenkronize
- Sık kesintiler
- Buffer overflow hataları

## 🔧 Sorun Giderme Komutları

### Codec desteğini kontrol et:
```bash
ffmpeg -codecs | grep -i h264
ffmpeg -codecs | grep -i aac
```

### Kullanılabilir audio/video cihazları:
```bash
ffmpeg -devices
```

### FFmpeg sürüm ve build bilgisi:
```bash
ffmpeg -version
ffmpeg -buildconf
```

## 💡 İpuçları

1. **Düşük gecikme için:** `-preset ultrafast -tune zerolatency` kullanın
2. **Raspberry Pi 3 için:** 540p veya 720p tercih edin
3. **Network sorunlarında:** packet size'ı azaltın (`pkt_size=1316`)
4. **Audio desync'te:** `-async 1` parametresini ekleyin
5. **Buffer sorunlarında:** `-bufsize` değerini artırın

## 🎓 Öğrenme Kaynakları

- FFmpeg Official Docs: https://ffmpeg.org/documentation.html
- FFmpeg Wiki: https://trac.ffmpeg.org/wiki
- Streaming Guide: https://trac.ffmpeg.org/wiki/StreamingGuide

---

Bu komutları Raspberry Pi'nizde test ederek sisteminizin performansını değerlendirebilirsiniz!
