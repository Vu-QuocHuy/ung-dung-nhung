import React, { useState, useEffect } from "react";
import {
  Wifi,
  WifiOff,
  RefreshCw,
  Activity,
  MapPin,
  Clock,
} from "lucide-react";
import { esp32Service, ESP32StatusResponse } from "../services/esp32.service";
import { toast } from "sonner";
import { getSocket } from "../services/socket.client";

export default function ESP32StatusCard() {
  const [status, setStatus] = useState(null as ESP32StatusResponse | null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchStatus = async (showToast = false) => {
    try {
      if (showToast) setRefreshing(true);
      const data = await esp32Service.getStatus();
      setStatus(data);
      if (showToast) {
        toast.success("Đã cập nhật trạng thái ESP32");
      }
    } catch (error: any) {
      if (showToast) {
        toast.error("Không thể lấy trạng thái ESP32");
      }
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchStatus();
    const socket = getSocket();

    const onESP32Status = (socketStatus: ESP32StatusResponse) => {
      setStatus(socketStatus);
      setLoading(false);
      setRefreshing(false);
    };

    socket.on("esp32:status", onESP32Status);

    return () => {
      socket.off("esp32:status", onESP32Status);
    };
  }, []);

  const handleRefresh = () => {
    fetchStatus(true);
  };

  const formatLastSeen = (seconds: number): string => {
    if (seconds < 60) return `${seconds} giây trước`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)} phút trước`;
    return `${Math.floor(seconds / 3600)} giờ trước`;
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleString("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  };

  if (loading) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-center h-32">
          <RefreshCw className="w-6 h-6 text-gray-400 animate-spin" />
        </div>
      </div>
    );
  }

  if (!status) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="text-center text-gray-500">
          Không thể tải trạng thái ESP32
        </div>
      </div>
    );
  }

  const isOnline = status.isOnline;

  return (
    <div className="bg-white rounded-xl shadow-sm border-2 border-gray-200 p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div
            className={`p-3 rounded-xl ${
              isOnline ? "bg-green-50" : "bg-red-50"
            }`}
          >
            {isOnline ? (
              <Wifi className="w-6 h-6 text-green-600" />
            ) : (
              <WifiOff className="w-6 h-6 text-red-600" />
            )}
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              Trạng thái kết nối với nông trại
            </h3>
            <p className="text-sm text-gray-500">{status.deviceId}</p>
          </div>
        </div>
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="p-2 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-50"
          title="Làm mới"
        >
          <RefreshCw
            className={`w-5 h-5 text-gray-600 ${
              refreshing ? "animate-spin" : ""
            }`}
          />
        </button>
      </div>

      {/* Status Badge */}
      <div className="mb-4">
        <div
          className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium ${
            isOnline ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"
          }`}
        >
          <div
            className={`w-2 h-2 rounded-full ${
              isOnline ? "bg-green-500" : "bg-red-500"
            } animate-pulse`}
          />
          {isOnline ? "Trực tuyến" : "Ngoại tuyến"}
        </div>
      </div>

      {/* Details */}
      <div className="space-y-3">
        <div className="flex items-start gap-3">
          <Activity className="w-5 h-5 text-gray-400 mt-0.5" />
          <div className="flex-1">
            <p className="text-sm text-gray-500">Trạng thái kết nối</p>
            <p className="text-sm font-medium text-gray-900">
              {status.status === "online"
                ? "Hoạt động bình thường"
                : "Mất kết nối"}
            </p>
          </div>
        </div>

        <div className="flex items-start gap-3">
          <Clock className="w-5 h-5 text-gray-400 mt-0.5" />
          <div className="flex-1">
            <p className="text-sm text-gray-500">Lần cuối kết nối</p>
            <p className="text-sm font-medium text-gray-900">
              {formatLastSeen(status.lastSeenSeconds)}
            </p>
            <p className="text-xs text-gray-400 mt-0.5">
              {formatDate(status.lastSeen)}
            </p>
          </div>
        </div>

        {status.ipAddress && (
          <div className="flex items-start gap-3">
            <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm text-gray-500">Địa chỉ IP</p>
              <p className="text-sm font-medium text-gray-900 font-mono">
                {status.ipAddress}
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Warning message when offline */}
      {!isOnline && (
        <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-700">
            ⚠️ ESP32 đang ngoại tuyến. Không thể điều khiển thiết bị.
          </p>
        </div>
      )}
    </div>
  );
}
