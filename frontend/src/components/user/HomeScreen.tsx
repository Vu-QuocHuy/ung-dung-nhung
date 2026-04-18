import React, { useState, useEffect } from "react";
import {
  Thermometer,
  Droplets,
  Sun,
  Sprout,
  Waves,
  TrendingUp,
  TrendingDown,
  Activity,
  History,
} from "lucide-react";
import { sensorService } from "../../services/sensor.service";
import { deviceService } from "../../services/device.service";
import { alertService } from "../../services/alert.service";
import { scheduleService } from "../../services/schedule.service";
import { toast } from "sonner";
import ESP32StatusCard from "../ESP32StatusCard";
import { getSocket } from "../../services/socket.client";

function num(v: unknown): number {
  if (v == null || v === "") return 0;
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

export default function HomeScreen() {
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [sensorData, setSensorData] = useState({
    temperature: 0,
    humidity: 0,
    soilMoisture: 0,
    waterLevel: 0,
    light: 0,
    lastUpdate: new Date(),
  });
  const [systemStats, setSystemStats] = useState({
    devicesOnline: 0,
    totalDevices: 8,
    activeSchedules: 0,
    activeAlerts: 0,
  });

  const fetchData = async () => {
    try {
      // Fetch sensor data
      const latestData = await sensorService.getLatest();
      setSensorData({
        temperature: latestData.temperature ?? 0,
        humidity: latestData.humidity ?? 0,
        soilMoisture: latestData.soilMoisture ?? 0,
        waterLevel: latestData.waterLevel ?? 0,
        light: latestData.light ?? 0,
        lastUpdate: new Date(latestData.timestamp || Date.now()),
      });

      // Fetch device status
      const deviceStatus = await deviceService.getStatus();
      const onlineDevices = Object.values(deviceStatus).filter(
        (status) => status === "ON" || status === "AUTO"
      ).length;

      // Fetch schedules
      const schedules = await scheduleService.getAll();
      const activeSchedules = schedules.filter((s) => s.enabled).length;

      // Fetch unread alerts
      const unreadAlerts = await alertService.getUnread();

      setSystemStats({
        devicesOnline: onlineDevices,
        totalDevices: Object.keys(deviceStatus).length || 8,
        activeSchedules,
        activeAlerts: unreadAlerts.length,
      });
    } catch (error: any) {
      toast.error(
        "Không thể tải dữ liệu: " +
          (error.response?.data?.message || error.message)
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let cancelled = false;
    const socket = getSocket();

    const onSensorUpdate = (latestData: any) => {
      setSensorData({
        temperature: num(latestData?.temperature?.value),
        humidity: num(latestData?.humidity?.value),
        soilMoisture: num(latestData?.soil_moisture?.value),
        waterLevel: num(latestData?.water_level?.value),
        light: num(latestData?.light?.value),
        lastUpdate: new Date(
          latestData?.temperature?.updatedAt ||
            latestData?.humidity?.updatedAt ||
            latestData?.soil_moisture?.updatedAt ||
            latestData?.water_level?.updatedAt ||
            latestData?.light?.updatedAt ||
            Date.now()
        ),
      });
      setLoading(false);
    };

    const onDeviceStatus = (deviceStatus: Record<string, string>) => {
      const onlineDevices = Object.values(deviceStatus || {}).filter(
        (status) => status === "ON" || status === "AUTO"
      ).length;

      setSystemStats((prev) => ({
        ...prev,
        devicesOnline: onlineDevices,
        totalDevices: Object.keys(deviceStatus || {}).length || prev.totalDevices,
      }));
    };

    (async () => {
      await fetchData();
      if (cancelled) return;
      socket.on("sensor:update", onSensorUpdate);
      socket.on("device:status", onDeviceStatus);
    })();

    return () => {
      cancelled = true;
      socket.off("sensor:update", onSensorUpdate);
      socket.off("device:status", onDeviceStatus);
    };
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const statCards = [
    {
      label: "Nhiệt độ",
      value:
        loading ||
        sensorData.temperature === undefined ||
        sensorData.temperature === null
          ? "..."
          : `${Number(sensorData.temperature).toFixed(1)}°C`,
      icon: Thermometer,
      color: "text-red-600",
      bgColor: "bg-red-50",
    },
    {
      label: "Độ ẩm không khí",
      value:
        loading ||
        sensorData.humidity === undefined ||
        sensorData.humidity === null
          ? "..."
          : `${Number(sensorData.humidity).toFixed(1)}%`,
      icon: Droplets,
      color: "text-blue-600",
      bgColor: "bg-blue-50",
    },
    {
      label: "Độ ẩm đất",
      value:
        loading ||
        sensorData.soilMoisture === undefined ||
        sensorData.soilMoisture === null
          ? "..."
          : `${Number(sensorData.soilMoisture).toFixed(1)}%`,
      icon: Sprout,
      color: "text-green-600",
      bgColor: "bg-green-50",
    },
    {
      label: "Mực nước",
      value:
        loading ||
        sensorData.waterLevel === undefined ||
        sensorData.waterLevel === null
          ? "..."
          : `${Number(sensorData.waterLevel).toFixed(1)} cm`,
      icon: Waves,
      color: "text-cyan-600",
      bgColor: "bg-cyan-50",
    },
    {

      label: 'Ánh sáng',
      value: loading || sensorData.light === undefined || sensorData.light === null
        ? '...'
        : `${Math.round(Number(sensorData.light))}%`,

      icon: Sun,
      color: "text-yellow-600",
      bgColor: "bg-yellow-50",
    },
  ];

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
            Trang chủ
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* System Status */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-2 mb-6">
            <Activity className="w-6 h-6 text-green-600" />
            <h2 className="text-gray-900">Trạng thái hệ thống</h2>
          </div>
          <div className="grid grid-cols-4 gap-6">
            <div className="text-center p-4 bg-green-50 rounded-xl">
              <div className="text-2xl font-bold text-green-600 mb-1">
                Hoạt động
              </div>
              <div className="text-gray-600">Hệ thống</div>
            </div>
            <div className="text-center p-4 bg-blue-50 rounded-xl">
              <div className="text-2xl font-bold text-blue-600 mb-1">
                {loading
                  ? "..."
                  : `${systemStats.devicesOnline}/${systemStats.totalDevices}`}
              </div>
              <div className="text-gray-600">Thiết bị bật</div>
            </div>
            <div className="text-center p-4 bg-purple-50 rounded-xl">
              <div className="text-2xl font-bold text-purple-600 mb-1">
                {loading ? "..." : systemStats.activeSchedules}
              </div>
              <div className="text-gray-600">Lịch trình</div>
            </div>
            <div className="text-center p-4 bg-orange-50 rounded-xl">
              <div className="text-2xl font-bold text-orange-600 mb-1">
                {loading ? "..." : systemStats.activeAlerts}
              </div>
              <div className="text-gray-600">Cảnh báo</div>
            </div>
          </div>
        </div>

        {/* Sensor Cards Grid */}
        <div className="grid grid-cols-3 gap-6">
          {statCards.map((stat, index) => {
            const Icon = stat.icon;
            return (
              <div
                key={index}
                className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className={`${stat.bgColor} p-4 rounded-xl`}>
                    <Icon className={`w-8 h-8 ${stat.color}`} />
                  </div>
                </div>
                <div className="text-gray-600 mb-2">{stat.label}</div>
                <div className="text-2xl font-bold text-gray-900">
                  {stat.value}
                </div>
              </div>
            );
          })}
        </div>

        {/* ESP32 Status */}
        <ESP32StatusCard />
      </div>
    </div>
  );
}
