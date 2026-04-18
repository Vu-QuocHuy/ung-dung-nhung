import React, { useState, useEffect } from "react";
import {
  Thermometer,
  Droplets,
  Sun,
  Sprout,
  Waves,
  Users,
  Shield,
  AlertTriangle,
  Calendar,
  Activity,
} from "lucide-react";
import { sensorService } from "../../services/sensor.service";
import { deviceService } from "../../services/device.service";
import { alertService } from "../../services/alert.service";
import { scheduleService } from "../../services/schedule.service";
import { userService } from "../../services/user.service";
import { activityLogService } from "../../services/activityLog.service";
import { toast } from "sonner";
import ESP32StatusCard from "../ESP32StatusCard";
import { getSocket } from "../../services/socket.client";

function num(v: unknown): number {
  if (v == null || v === "") return 0;
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

export default function AdminHomeScreen() {
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  type Stats = {
    temperature: number;
    humidity: number;
    soilMoisture: number;
    waterLevel: number;
    light: number;
    totalUsers: number;
    totalAdmins: number;
    activeAlerts: number;
    activeSchedules: number;
    devicesOnline: number;
    lastUpdate: Date;
  };

  const initialStats: Stats = {
    temperature: 0,
    humidity: 0,
    soilMoisture: 0,
    waterLevel: 0,
    light: 0,
    totalUsers: 0,
    totalAdmins: 0,
    activeAlerts: 0,
    activeSchedules: 0,
    devicesOnline: 0,
    lastUpdate: new Date(),
  };

  const [stats, setStats] = useState(initialStats);
  const [recentActivities, setRecentActivities] = useState([] as any[]);

  // Fetch sensor data only (auto refresh)
  const fetchSensorData = async () => {
    try {
      const latestData = await sensorService.getLatest();
      setStats((prev: Stats) => ({
        ...prev,
        temperature: latestData.temperature ?? 0,
        humidity: latestData.humidity ?? 0,
        soilMoisture: latestData.soilMoisture ?? 0,
        waterLevel: latestData.waterLevel ?? 0,
        light: latestData.light ?? 0,
        lastUpdate: new Date(latestData.timestamp || Date.now()),
      }));
    } catch (error: any) {
      toast.error(
        "Không thể tải dữ liệu cảm biến: " +
          (error.response?.data?.message || error.message)
      );
    }
  };

  // Fetch all other data (one time only)
  const fetchOtherData = async () => {
    try {
      // Fetch users
      const usersResponse = await userService.getAll();
      const totalUsers =
        usersResponse.pagination?.totalUsers || usersResponse.data?.length || 0;
      const totalAdmins =
        usersResponse.data?.filter((u) => u.role === "admin").length || 0;

      // Fetch device status
      const deviceStatus = await deviceService.getStatus();
      const onlineDevices = Object.values(deviceStatus).filter(
        (status) => status === "ON" || status === "AUTO"
      ).length;

      // Fetch schedules
      const schedules = await scheduleService.getAll();
      const activeSchedules = schedules.filter((s) => s.enabled).length;

      // Fetch active alerts
      const alertsResponse = await alertService.getAll({
        status: "active",
        limit: 100,
      });
      const activeAlerts = alertsResponse.count || 0;

      // Fetch recent activities
      const activitiesResponse = await activityLogService.getAll({ limit: 5 });
      const activities = activitiesResponse.data || [];

      setStats((prev: Stats) => ({
        ...prev,
        totalUsers,
        totalAdmins,
        activeAlerts,
        activeSchedules,
        devicesOnline: onlineDevices,
      }));

      setRecentActivities(Array.isArray(activities) ? activities : []);
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

  // Fetch all data (for manual refresh)
  const fetchAllData = async () => {
    setRefreshing(true);
    await Promise.all([fetchSensorData(), fetchOtherData()]);
  };

  useEffect(() => {
    let cancelled = false;
    const socket = getSocket();

    const onSensorUpdate = (latestData: any) => {
      setStats((prev: Stats) => ({
        ...prev,
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
      }));
      setLoading(false);
    };

    const onDeviceStatus = (deviceStatus: Record<string, string>) => {
      const onlineDevices = Object.values(deviceStatus || {}).filter(
        (status) => status === "ON" || status === "AUTO"
      ).length;

      setStats((prev: Stats) => ({
        ...prev,
        devicesOnline: onlineDevices,
      }));
    };

    (async () => {
      await Promise.all([fetchSensorData(), fetchOtherData()]);
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
    fetchAllData();
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return "Vừa xong";
    if (diffMins < 60) return `${diffMins} phút trước`;
    if (diffHours < 24) return `${diffHours} giờ trước`;
    return `${diffDays} ngày trước`;
  };
  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
            Quản trị hệ thống
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* System Stats */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-6">
            <Activity className="w-6 h-6 text-purple-600" />
            <h2 className="text-gray-900">Thống kê hệ thống</h2>
          </div>
          <div className="grid grid-cols-5 gap-4">
            <div className="text-center p-6 bg-blue-50 rounded-xl hover:shadow-md transition-shadow">
              <Users className="w-10 h-10 text-blue-600 mx-auto mb-3" />
              <div className="text-3xl font-bold text-blue-600 mb-2">
                {loading ? "..." : stats.totalUsers}
              </div>
              <div className="text-gray-600 font-medium">Người dùng</div>
            </div>
            <div className="text-center p-6 bg-purple-50 rounded-xl hover:shadow-md transition-shadow">
              <Shield className="w-10 h-10 text-purple-600 mx-auto mb-3" />
              <div className="text-3xl font-bold text-purple-600 mb-2">
                {loading ? "..." : stats.totalAdmins}
              </div>
              <div className="text-gray-600 font-medium">Quản trị viên</div>
            </div>
            <div className="text-center p-6 bg-orange-50 rounded-xl hover:shadow-md transition-shadow">
              <AlertTriangle className="w-10 h-10 text-orange-600 mx-auto mb-3" />
              <div className="text-3xl font-bold text-orange-600 mb-2">
                {loading ? "..." : stats.activeAlerts}
              </div>
              <div className="text-gray-600 font-medium">Cảnh báo</div>
            </div>
            <div className="text-center p-6 bg-green-50 rounded-xl hover:shadow-md transition-shadow">
              <Calendar className="w-10 h-10 text-green-600 mx-auto mb-3" />
              <div className="text-3xl font-bold text-green-600 mb-2">
                {loading ? "..." : stats.activeSchedules}
              </div>
              <div className="text-gray-600 font-medium">Lịch trình</div>
            </div>
            <div className="text-center p-6 bg-cyan-50 rounded-xl hover:shadow-md transition-shadow">
              <Activity className="w-10 h-10 text-cyan-600 mx-auto mb-3" />
              <div className="text-3xl font-bold text-cyan-600 mb-2">
                {loading ? "..." : `${stats.devicesOnline}/8`}
              </div>
              <div className="text-gray-600 font-medium">
                Thiết bị đang hoạt động
              </div>
            </div>
          </div>
        </div>

        {/* Environment Data */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-gray-900 mb-6">Thông số môi trường</h2>
          <div className="grid grid-cols-3 gap-6">
            {[
              {
                label: "Nhiệt độ",
                value:
                  loading ||
                  stats.temperature === undefined ||
                  stats.temperature === null
                    ? "..."
                    : `${Number(stats.temperature).toFixed(1)}°C`,
                icon: Thermometer,
                color: "red",
              },
              {
                label: "Độ ẩm không khí",
                value:
                  loading ||
                  stats.humidity === undefined ||
                  stats.humidity === null
                    ? "..."
                    : `${Number(stats.humidity).toFixed(1)}%`,
                icon: Droplets,
                color: "blue",
              },
              {
                label: "Độ ẩm đất",
                value:
                  loading ||
                  stats.soilMoisture === undefined ||
                  stats.soilMoisture === null
                    ? "..."
                    : `${Number(stats.soilMoisture).toFixed(1)}%`,
                icon: Sprout,
                color: "green",
              },
              {
                label: "Mực nước",
                value:
                  loading ||
                  stats.waterLevel === undefined ||
                  stats.waterLevel === null
                    ? "..."
                    : `${Number(stats.waterLevel).toFixed(1)} cm`,
                icon: Waves,
                color: "cyan",
              },
              {
                label: "Ánh sáng",
                value:
                  loading || stats.light === undefined || stats.light === null
                    ? "..."
                    : `${Number(stats.light).toFixed(1)}%`,
                icon: Sun,
                color: "yellow",
              },
            ].map((item, index) => {
              const Icon = item.icon;
              const colorMap: Record<string, { text: string; bg: string }> = {
                red: { text: "text-red-600", bg: "bg-red-50" },
                blue: { text: "text-blue-600", bg: "bg-blue-50" },
                green: { text: "text-green-600", bg: "bg-green-50" },
                cyan: { text: "text-cyan-600", bg: "bg-cyan-50" },
                yellow: { text: "text-yellow-600", bg: "bg-yellow-50" },
              };
              const colors = colorMap[item.color];
              return (
                <div
                  key={index}
                  className="flex items-center gap-4 p-6 border border-gray-200 rounded-xl hover:shadow-md transition-shadow"
                >
                  <div className={`${colors.bg} p-4 rounded-xl`}>
                    <Icon className={`w-8 h-8 ${colors.text}`} />
                  </div>
                  <div>
                    <div className="text-gray-600 mb-1">{item.label}</div>
                    <div className="text-2xl font-bold text-gray-900">
                      {item.value}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <ESP32StatusCard />
      </div>
    </div>
  );
}
