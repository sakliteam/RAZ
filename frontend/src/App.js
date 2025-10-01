import { useState, useEffect } from "react";
import "@/App.css";
import axios from "axios";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Loader2, Radio, Video, Settings, Play, Square } from "lucide-react";
import { toast } from "sonner";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

function App() {
  const [settings, setSettings] = useState({
    radio_url: "",
    resolution: "720p",
    output_mode: "unicast",
    multicast_address: "239.255.0.1:5000",
    datetime_format: "%Y-%m-%d %H:%M:%S"
  });
  
  const [status, setStatus] = useState({
    is_running: false,
    pid: null,
    message: ""
  });
  
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);

  // Fetch settings and status on mount
  useEffect(() => {
    fetchSettings();
    fetchStatus();
    
    // Poll status every 3 seconds
    const interval = setInterval(fetchStatus, 3000);
    return () => clearInterval(interval);
  }, []);

  const fetchSettings = async () => {
    try {
      const response = await axios.get(`${API}/settings`);
      setSettings(response.data);
      setLoading(false);
    } catch (error) {
      console.error("Failed to fetch settings:", error);
      toast.error("Ayarlar yüklenemedi");
      setLoading(false);
    }
  };

  const fetchStatus = async () => {
    try {
      const response = await axios.get(`${API}/status`);
      setStatus(response.data);
    } catch (error) {
      console.error("Failed to fetch status:", error);
    }
  };

  const updateSettings = async () => {
    if (status.is_running) {
      toast.error("Yayın durdurulmadan ayarlar değiştirilemez!");
      return;
    }

    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/settings`, settings);
      setSettings(response.data);
      toast.success("Ayarlar başarıyla güncellendi!");
    } catch (error) {
      console.error("Failed to update settings:", error);
      toast.error("Ayarlar güncellenemedi");
    } finally {
      setActionLoading(false);
    }
  };

  const startStream = async () => {
    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/start`);
      setStatus(response.data);
      toast.success("Yayın başlatıldı!");
      await fetchStatus();
    } catch (error) {
      console.error("Failed to start stream:", error);
      toast.error(error.response?.data?.detail || "Yayın başlatılamadı");
    } finally {
      setActionLoading(false);
    }
  };

  const stopStream = async () => {
    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/stop`);
      setStatus(response.data);
      toast.success("Yayın durduruldu!");
      await fetchStatus();
    } catch (error) {
      console.error("Failed to stop stream:", error);
      toast.error("Yayın durdurulamadı");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-cyan-400" />
      </div>
    );
  }

  return (
    <div className="App min-h-screen p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="text-center space-y-4 py-8">
          <div className="flex items-center justify-center gap-3">
            <div className="icon-wrapper">
              <Radio className="w-12 h-12 text-cyan-400" />
            </div>
            <Video className="w-12 h-12 text-emerald-400" />
          </div>
          <h1 className="main-title">
            Radyo Video Yayın Sistemi
          </h1>
          <p className="subtitle">
            FFmpeg ile radyo akışını canlı video kanalına dönüştürün
          </p>
        </div>

        {/* Status Card */}
        <Card className="status-card">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className={`status-indicator ${status.is_running ? 'active' : ''}`}>
                  <div className="status-dot"></div>
                </div>
                <div>
                  <h3 className="text-xl font-semibold">
                    {status.is_running ? "Yayın Aktif" : "Yayın Durdu"}
                  </h3>
                  <p className="text-sm text-gray-400 mt-1">
                    {status.message}
                  </p>
                  {status.pid && (
                    <p className="text-xs text-gray-500 mt-1">
                      Process ID: {status.pid}
                    </p>
                  )}
                </div>
              </div>
              <Badge 
                variant={status.is_running ? "default" : "secondary"}
                className={status.is_running ? "badge-active" : "badge-inactive"}
              >
                {status.is_running ? "LIVE" : "OFF"}
              </Badge>
            </div>
          </CardContent>
        </Card>

        {/* Control Panel */}
        <div className="grid md:grid-cols-2 gap-6">
          {/* Settings Card */}
          <Card className="settings-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="w-5 h-5" />
                Yayın Ayarları
              </CardTitle>
              <CardDescription>
                FFmpeg ve yayın parametrelerini yapılandırın
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Radio URL */}
              <div className="space-y-2">
                <Label htmlFor="radio_url">Radyo Akış URL'si</Label>
                <Input
                  id="radio_url"
                  data-testid="radio-url-input"
                  value={settings.radio_url}
                  onChange={(e) => setSettings({...settings, radio_url: e.target.value})}
                  placeholder="https://example.com/stream.m3u8"
                  disabled={status.is_running}
                />
              </div>

              {/* Resolution */}
              <div className="space-y-2">
                <Label htmlFor="resolution">Video Çözünürlüğü</Label>
                <Select
                  value={settings.resolution}
                  onValueChange={(value) => setSettings({...settings, resolution: value})}
                  disabled={status.is_running}
                >
                  <SelectTrigger data-testid="resolution-select">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="540p">540p (960x540)</SelectItem>
                    <SelectItem value="720p">720p (1280x720)</SelectItem>
                    <SelectItem value="1080p">1080p (1920x1080)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Output Mode */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label htmlFor="output_mode">Multicast Modu</Label>
                  <Switch
                    id="output_mode"
                    data-testid="output-mode-switch"
                    checked={settings.output_mode === "multicast"}
                    onCheckedChange={(checked) => 
                      setSettings({...settings, output_mode: checked ? "multicast" : "unicast"})
                    }
                    disabled={status.is_running}
                  />
                </div>
                <p className="text-xs text-gray-400">
                  {settings.output_mode === "multicast" ? "Multicast aktif" : "Unicast aktif"}
                </p>
              </div>

              {/* Multicast Address */}
              {settings.output_mode === "multicast" && (
                <div className="space-y-2">
                  <Label htmlFor="multicast_address">Multicast Adresi</Label>
                  <Input
                    id="multicast_address"
                    data-testid="multicast-address-input"
                    value={settings.multicast_address}
                    onChange={(e) => setSettings({...settings, multicast_address: e.target.value})}
                    placeholder="239.255.0.1:5000"
                    disabled={status.is_running}
                  />
                </div>
              )}

              {/* DateTime Format */}
              <div className="space-y-2">
                <Label htmlFor="datetime_format">Tarih/Saat Formatı</Label>
                <Input
                  id="datetime_format"
                  data-testid="datetime-format-input"
                  value={settings.datetime_format}
                  onChange={(e) => setSettings({...settings, datetime_format: e.target.value})}
                  placeholder="%Y-%m-%d %H:%M:%S"
                  disabled={status.is_running}
                />
                <p className="text-xs text-gray-400">
                  strftime formatı kullanın
                </p>
              </div>

              {/* Update Button */}
              <Button
                onClick={updateSettings}
                disabled={status.is_running || actionLoading}
                className="w-full update-button"
                data-testid="update-settings-button"
              >
                {actionLoading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Güncelleniyor...
                  </>
                ) : (
                  "Ayarları Kaydet"
                )}
              </Button>
            </CardContent>
          </Card>

          {/* Control Card */}
          <Card className="control-card">
            <CardHeader>
              <CardTitle>Yayın Kontrolü</CardTitle>
              <CardDescription>
                Canlı yayını başlatın veya durdurun
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="control-info">
                <div className="info-item">
                  <span className="info-label">Çözünürlük:</span>
                  <span className="info-value">{settings.resolution}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Mod:</span>
                  <span className="info-value capitalize">{settings.output_mode}</span>
                </div>
                {settings.output_mode === "multicast" && (
                  <div className="info-item">
                    <span className="info-label">Adres:</span>
                    <span className="info-value font-mono text-sm">{settings.multicast_address}</span>
                  </div>
                )}
              </div>

              <div className="space-y-3">
                {!status.is_running ? (
                  <Button
                    onClick={startStream}
                    disabled={actionLoading}
                    className="w-full start-button"
                    size="lg"
                    data-testid="start-button"
                  >
                    {actionLoading ? (
                      <>
                        <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                        Başlatılıyor...
                      </>
                    ) : (
                      <>
                        <Play className="w-5 h-5 mr-2" />
                        Yayını Başlat
                      </>
                    )}
                  </Button>
                ) : (
                  <Button
                    onClick={stopStream}
                    disabled={actionLoading}
                    className="w-full stop-button"
                    size="lg"
                    data-testid="stop-button"
                  >
                    {actionLoading ? (
                      <>
                        <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                        Durduruluyor...
                      </>
                    ) : (
                      <>
                        <Square className="w-5 h-5 mr-2" />
                        Yayını Durdur
                      </>
                    )}
                  </Button>
                )}
              </div>

              <div className="warning-box">
                <p className="text-sm">
                  ⚠️ Yayın başlatılmadan önce FFmpeg'in sisteminizde kurulu olduğundan emin olun.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Info Panel */}
        <Card className="info-card">
          <CardHeader>
            <CardTitle>Sistem Bilgileri</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-gray-400 mb-1">Platform</p>
                <p className="font-semibold">Raspberry Pi / Linux</p>
              </div>
              <div>
                <p className="text-gray-400 mb-1">Video Codec</p>
                <p className="font-semibold">H.264 (libx264)</p>
              </div>
              <div>
                <p className="text-gray-400 mb-1">Audio Codec</p>
                <p className="font-semibold">AAC (128kbps)</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

export default App;