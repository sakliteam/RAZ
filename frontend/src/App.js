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
    output_mode: "multicast",
    unicast_ip: "127.0.0.1:5000",
    multicast_address: "239.255.0.1:5000",
    font_size: 72,
    font_color: "white"
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
      toast.error("Kan instellingen niet laden");
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
      toast.error("Stop eerst de stream voordat u instellingen wijzigt!");
      return;
    }

    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/settings`, settings);
      setSettings(response.data);
      toast.success("Instellingen succesvol bijgewerkt!");
    } catch (error) {
      console.error("Failed to update settings:", error);
      toast.error("Kan instellingen niet bijwerken");
    } finally {
      setActionLoading(false);
    }
  };

  const startStream = async () => {
    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/start`);
      setStatus(response.data);
      toast.success("Stream gestart!");
      await fetchStatus();
    } catch (error) {
      console.error("Failed to start stream:", error);
      toast.error(error.response?.data?.detail || "Kan stream niet starten");
    } finally {
      setActionLoading(false);
    }
  };

  const stopStream = async () => {
    setActionLoading(true);
    try {
      const response = await axios.post(`${API}/stop`);
      setStatus(response.data);
      toast.success("Stream gestopt!");
      await fetchStatus();
    } catch (error) {
      console.error("Failed to stop stream:", error);
      toast.error("Kan stream niet stoppen");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-orange-400" />
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
              <Radio className="w-12 h-12 text-orange-400" />
            </div>
            <Video className="w-12 h-12 text-blue-400" />
          </div>
          <h1 className="main-title">
            Reinier de Graaf Radio Server
          </h1>
          <p className="subtitle">
            FFmpeg radio naar live video kanaal converter
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
                    {status.is_running ? "Stream Actief" : "Stream Gestopt"}
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
              {status.is_running ? (
                <div className="on-air-badge">
                  <span className="on-air-text">ON AIR</span>
                </div>
              ) : (
                <Badge variant="secondary" className="badge-inactive">
                  OFF AIR
                </Badge>
              )}
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
                Stream Instellingen
              </CardTitle>
              <CardDescription>
                Configureer FFmpeg en stream parameters
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Radio URL */}
              <div className="space-y-2">
                <Label htmlFor="radio_url">Radio Stream URL</Label>
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
                <Label htmlFor="resolution">Video Resolutie Profiel</Label>
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
                  <Label htmlFor="output_mode">Multicast Modus</Label>
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
                  {settings.output_mode === "multicast" ? "Multicast actief" : "Unicast actief"}
                </p>
              </div>

              {/* Unicast IP */}
              {settings.output_mode === "unicast" && (
                <div className="space-y-2">
                  <Label htmlFor="unicast_ip">Unicast IP:Poort</Label>
                  <Input
                    id="unicast_ip"
                    data-testid="unicast-ip-input"
                    value={settings.unicast_ip}
                    onChange={(e) => setSettings({...settings, unicast_ip: e.target.value})}
                    placeholder="192.168.1.100:5000"
                    disabled={status.is_running}
                  />
                  <p className="text-xs text-gray-400">
                    Voer het IP-adres en poort van de doelmachine in
                  </p>
                </div>
              )}

              {/* Multicast Address */}
              {settings.output_mode === "multicast" && (
                <div className="space-y-2">
                  <Label htmlFor="multicast_address">Multicast Adres</Label>
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

              {/* Font Size */}
              <div className="space-y-2">
                <Label htmlFor="font_size">Lettergrootte (TV overlay)</Label>
                <div className="flex items-center gap-2">
                  <Input
                    id="font_size"
                    data-testid="font-size-input"
                    type="number"
                    min="24"
                    max="200"
                    value={settings.font_size}
                    onChange={(e) => setSettings({...settings, font_size: parseInt(e.target.value)})}
                    disabled={status.is_running}
                    className="w-24"
                  />
                  <span className="text-sm text-gray-400">px</span>
                </div>
              </div>

              {/* Font Color */}
              <div className="space-y-2">
                <Label htmlFor="font_color">Tekstkleur (TV overlay)</Label>
                <div className="flex items-center gap-3">
                  <Select
                    value={settings.font_color}
                    onValueChange={(value) => setSettings({...settings, font_color: value})}
                    disabled={status.is_running}
                  >
                    <SelectTrigger data-testid="font-color-select" className="w-full">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="white">Wit</SelectItem>
                      <SelectItem value="yellow">Geel</SelectItem>
                      <SelectItem value="cyan">Cyaan</SelectItem>
                      <SelectItem value="lime">Lime</SelectItem>
                      <SelectItem value="orange">Oranje</SelectItem>
                      <SelectItem value="red">Rood</SelectItem>
                    </SelectContent>
                  </Select>
                  <div 
                    className="w-12 h-10 rounded border-2 border-gray-600"
                    style={{ backgroundColor: settings.font_color }}
                  ></div>
                </div>
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
                    Bijwerken...
                  </>
                ) : (
                  "Instellingen Opslaan"
                )}
              </Button>
            </CardContent>
          </Card>

          {/* Control Card */}
          <Card className="control-card">
            <CardHeader>
              <CardTitle>Stream Besturing</CardTitle>
              <CardDescription>
                Start of stop de live uitzending
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="control-info">
                <div className="info-item">
                  <span className="info-label">Resolutie:</span>
                  <span className="info-value">{settings.resolution}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Modus:</span>
                  <span className="info-value capitalize">{settings.output_mode}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Adres:</span>
                  <span className="info-value font-mono text-sm">
                    {settings.output_mode === "multicast" ? settings.multicast_address : settings.unicast_ip}
                  </span>
                </div>
                <div className="info-item">
                  <span className="info-label">Lettergrootte:</span>
                  <span className="info-value">{settings.font_size}px</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Kleur:</span>
                  <div className="flex items-center gap-2">
                    <span className="info-value capitalize">{settings.font_color}</span>
                    <div 
                      className="w-6 h-6 rounded border border-gray-600"
                      style={{ backgroundColor: settings.font_color }}
                    ></div>
                  </div>
                </div>
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
                        Starten...
                      </>
                    ) : (
                      <>
                        <Play className="w-5 h-5 mr-2" />
                        Stream Starten
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
                        Stoppen...
                      </>
                    ) : (
                      <>
                        <Square className="w-5 h-5 mr-2" />
                        Stream Stoppen
                      </>
                    )}
                  </Button>
                )}
              </div>

              <div className="warning-box">
                <p className="text-sm">
                  ⚠️ Zorg ervoor dat FFmpeg is geïnstalleerd voordat u de stream start.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Info Panel */}
        <Card className="info-card">
          <CardHeader>
            <CardTitle>Systeeminformatie</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-gray-400 mb-1">Locatie</p>
                <p className="font-semibold">Delft, Nederland</p>
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