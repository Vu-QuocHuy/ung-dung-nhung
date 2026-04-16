import React, { useState, useEffect } from "react";
import { Wifi, WifiOff, RefreshCw } from "lucide-react";
import { esp32Service, ESP32StatusResponse } from "../services/esp32.service";

export default function ESP32StatusIndicator() {
  const [status, setStatus] = useState(null as ESP32StatusResponse | null);
  const [loading, setLoading] = useState(true);

  const fetchStatus = async () => {
    try {
      const data = await esp32Service.getStatus();
      setStatus(data);
    } catch (error) {
      // Error handled silently
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStatus();
    // Refresh mỗi 10 giây
    const interval = setInterval(fetchStatus, 10000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-100 rounded-lg">
        <RefreshCw className="w-4 h-4 text-gray-400 animate-spin" />
        <span className="text-sm text-gray-600">Đang tải...</span>
      </div>
    );
  }

  if (!status) return null;

  const isOnline = status.isOnline;
  const lastSeenText =
    status.lastSeenSeconds < 60
      ? `${status.lastSeenSeconds}s trước`
      : `${Math.floor(status.lastSeenSeconds / 60)}m trước`;

  return (
    <div
      className={`flex items-center gap-2 px-3 py-1.5 rounded-lg transition-colors ${
        isOnline
          ? "bg-green-50 border border-green-200"
          : "bg-red-50 border border-red-200"
      }`}
      title={`IP: ${status.ipAddress || "N/A"}\nLần cuối: ${lastSeenText}`}
    >
      {isOnline ? (
        <Wifi className="w-4 h-4 text-green-600" />
      ) : (
        <WifiOff className="w-4 h-4 text-red-600" />
      )}
      <div className="flex flex-col">
        <span
          className={`text-xs font-medium ${
            isOnline ? "text-green-700" : "text-red-700"
          }`}
        >
          ESP32
        </span>
        <span
          className={`text-[10px] ${
            isOnline ? "text-green-600" : "text-red-600"
          }`}
        >
          {isOnline ? "Trực tuyến" : "Ngoại tuyến"}
        </span>
      </div>
    </div>
  );
}
