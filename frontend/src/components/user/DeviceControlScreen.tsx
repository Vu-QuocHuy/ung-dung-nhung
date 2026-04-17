import React, { useState, useEffect } from "react";
import { Droplets, Fan, Lightbulb, RotateCcw, Zap } from "lucide-react";
import { deviceService } from "../../services/device.service";
import { toast } from "sonner";
import { getSocket } from "../../services/socket.client";

type DeviceStatus = "ON" | "OFF" | "AUTO";

interface Device {
  id: string;
  name: string;
  displayName: string;
  icon: any;
  status: DeviceStatus;
  color: string;
}

type DeviceConfigEntry = {
  id: string;
  name: string;
  displayName: string;
  icon: any;
  color: string;
};

const DEVICE_CONFIG: Record<string, DeviceConfigEntry> = {
  pump: {
    id: "pump",
    name: "pump",
    displayName: "Bơm nước",
    icon: Droplets,
    color: "blue",
  },
  fan: {
    id: "fan",
    name: "fan",
    displayName: "Quạt",
    icon: Fan,
    color: "cyan",
  },
  light: {
    id: "light",
    name: "light",
    displayName: "Đèn (Tất cả)",
    icon: Lightbulb,
    color: "yellow",
  },
  servo_door: {
    id: "servo_door",
    name: "servo_door",
    displayName: "Cửa ra vào (Servo)",
    icon: RotateCcw,
    color: "purple",
  },
  servo_feed: {
    id: "servo_feed",
    name: "servo_feed",
    displayName: "Cho ăn (Servo)",
    icon: RotateCcw,
    color: "purple",
  },
  led_farm: {
    id: "led_farm",
    name: "led_farm",
    displayName: "Đèn trồng cây",
    icon: Zap,
    color: "green",
  },
  led_animal: {
    id: "led_animal",
    name: "led_animal",
    displayName: "Đèn khu vật nuôi",
    icon: Zap,
    color: "orange",
  },
  led_hallway: {
    id: "led_hallway",
    name: "led_hallway",
    displayName: "Đèn hành lang",
    icon: Zap,
    color: "pink",
  },
};

export default function DeviceControlScreen() {
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [devices, setDevices] = useState([] as Device[]);
  const [pendingIds, setPendingIds] = useState<Record<string, boolean>>({});

  const applyDeviceStatus = (statusData: Record<string, DeviceStatus>) => {
    const entries = Object.entries(statusData ?? {}) as [string, DeviceStatus][];
    const devicesWithStatus: Device[] = entries.map(([deviceName, status]) => {
      const config = DEVICE_CONFIG[deviceName as keyof typeof DEVICE_CONFIG];
      if (config) {
        return {
          ...config,
          status,
        } as Device;
      }
      return {
        id: deviceName,
        name: deviceName,
        displayName: deviceName,
        icon: Zap,
        status,
        color: "gray",
      };
    });
    setDevices(devicesWithStatus);
  };

  const fetchDeviceStatus = async () => {
    try {
      const statusData = await deviceService.getStatus();
      applyDeviceStatus(statusData);
    } catch (error: any) {
      toast.error(
        "Không thể tải trạng thái thiết bị: " +
          (error.response?.data?.message || error.message)
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDeviceStatus();
    const socket = getSocket();

    const onDeviceStatus = (statusData: Record<string, DeviceStatus>) => {
      applyDeviceStatus(statusData);
      setLoading(false);
      setRefreshing(false);
    };

    socket.on("device:status", onDeviceStatus);

    return () => {
      socket.off("device:status", onDeviceStatus);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchDeviceStatus();
  };

  const setDeviceStatus = async (
    device: Device,
    targetStatus: DeviceStatus
  ) => {
    try {
      setPendingIds((prev) => ({ ...prev, [device.id]: true }));

      // "Đèn (Tất cả)" phải điều khiển từng đèn thành phần.
      if (device.name === "light") {
        const targets: Array<DeviceConfigEntry["name"]> = [
          "led_farm",
          "led_animal",
          "led_hallway",
        ];

        await Promise.all(
          targets.map((deviceName) =>
            deviceService.controlDevice({
              deviceName: deviceName as any,
              action: targetStatus,
              value: 0,
            })
          )
        );
      } else {
        await deviceService.controlDevice({
          deviceName: device.name as any,
          action: targetStatus,
          value: 0,
        });
      }

      // Luôn lấy lại trạng thái thật từ backend để hiển thị đúng.
      await fetchDeviceStatus();

      const actionLabel =
        targetStatus === "ON"
          ? "bật"
          : targetStatus === "OFF"
          ? "tắt"
          : "chuyển sang tự động";

      toast.success(`${device.displayName} đã được ${actionLabel}`);
    } catch (error: any) {
      toast.error(
        "Không thể điều khiển thiết bị: " +
          (error.response?.data?.message || error.message)
      );
    } finally {
      setPendingIds((prev) => {
        const next = { ...prev };
        delete next[device.id];
        return next;
      });
    }
  };

  const runServoAction = async (device: Device) => {
    try {
      setPendingIds((prev) => ({ ...prev, [device.id]: true }));

      // Servo là "action": chỉ cần gửi lệnh để chạy 1 chu kỳ.
      await deviceService.controlDevice({
        deviceName: device.name as any,
        action: "ON",
        value: 0,
      });

      // Thời gian chu kỳ (ước lượng theo firmware):
      // - Mở cửa: ~1s + 2s + 1s + 2s = ~6s
      // - Cho ăn: ~1s + 2s + 1s = ~4s
      const waitMs = device.name === "servo_door" ? 6500 : 4500;
      await new Promise((r) => setTimeout(r, waitMs));

      await fetchDeviceStatus();

      toast.success(
        device.name === "servo_door" ? "Đã mở cửa xong" : "Đã cho ăn xong"
      );
    } catch (error: any) {
      toast.error(
        "Không thể thực hiện: " +
          (error.response?.data?.message || error.message)
      );
    } finally {
      setPendingIds((prev) => {
        const next = { ...prev };
        delete next[device.id];
        return next;
      });
    }
  };

  const getColorClasses = (color: string, isActive: boolean) => {
    const colorMap: Record<
      string,
      { icon: string; bg: string; border: string }
    > = {
      blue: {
        icon: "text-blue-600",
        bg: "bg-blue-50",
        border: "border-blue-200",
      },
      cyan: {
        icon: "text-cyan-600",
        bg: "bg-cyan-50",
        border: "border-cyan-200",
      },
      yellow: {
        icon: "text-yellow-600",
        bg: "bg-yellow-50",
        border: "border-yellow-200",
      },
      red: { icon: "text-red-600", bg: "bg-red-50", border: "border-red-200" },
      green: {
        icon: "text-green-600",
        bg: "bg-green-50",
        border: "border-green-200",
      },
      purple: {
        icon: "text-purple-600",
        bg: "bg-purple-50",
        border: "border-purple-200",
      },
      orange: {
        icon: "text-orange-600",
        bg: "bg-orange-50",
        border: "border-orange-200",
      },
      pink: {
        icon: "text-pink-600",
        bg: "bg-pink-50",
        border: "border-pink-200",
      },
      gray: {
        icon: "text-gray-600",
        bg: "bg-gray-50",
        border: "border-gray-200",
      },
    };

    return isActive
      ? colorMap[color] || colorMap.gray
      : { icon: "text-gray-400", bg: "bg-gray-50", border: "border-gray-200" };
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
            Điều khiển thiết bị
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-gray-600">Đang tải...</div>
          </div>
        ) : (
          <div className="grid grid-cols-4 gap-6">
            {devices.map((device: Device) => {
              const Icon = device.icon;
              const isServo =
                device.name === "servo_door" || device.name === "servo_feed";
              const isRunning = isServo && !!pendingIds[device.id];
              const effectiveStatus: DeviceStatus = device.status;

              const isActive =
                effectiveStatus === "ON" || effectiveStatus === "AUTO";
              const colors = getColorClasses(device.color, isActive);
              const statusClasses = isRunning
                ? "bg-yellow-100 text-gray-800 border border-yellow-300"
                : effectiveStatus === "AUTO"
                ? "bg-yellow-100 text-gray-800 border border-yellow-300"
                : effectiveStatus === "ON"
                ? "bg-green-100 text-green-700"
                : "bg-gray-100 text-gray-600";
              return (
                <div
                  key={device.id}
                  className={`bg-white rounded-xl shadow-sm border-2 ${colors.border} p-6 hover:shadow-md transition-all`}
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className={`${colors.bg} p-4 rounded-xl`}>
                      <Icon className={`w-8 h-8 ${colors.icon}`} />
                    </div>
                    <div
                      className={`px-3 py-1 rounded-full text-xs font-medium ${statusClasses}`}
                    >
                      {isServo
                        ? isRunning
                          ? "Đang thực hiện"
                          : effectiveStatus === "AUTO"
                          ? "Tự động"
                          : "Sẵn sàng"
                        : effectiveStatus === "AUTO"
                        ? "Tự động"
                        : effectiveStatus === "ON"
                        ? "Hoạt động"
                        : "Tắt"}
                    </div>
                  </div>

                  <div className="mb-4">
                    <div className="text-gray-900 font-medium">
                      {device.displayName}
                    </div>
                  </div>

                  {isServo ? (
                    <div className="grid grid-cols-3 gap-2">
                      <button
                        onClick={() => runServoAction(device)}
                        disabled={!!pendingIds[device.id]}
                        className="col-span-3 py-2 rounded-lg font-medium transition-colors bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {isRunning ? "Đang thực hiện..." : "Thực hiện"}
                      </button>

                      <button
                        onClick={() =>
                          setDeviceStatus(
                            device,
                            effectiveStatus === "AUTO" ? "OFF" : "AUTO"
                          )
                        }
                        disabled={!!pendingIds[device.id]}
                        className={`col-span-3 py-2 rounded-lg font-medium transition-colors ${
                          effectiveStatus === "AUTO"
                            ? "bg-white border border-yellow-400 text-yellow-700"
                            : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        } disabled:opacity-50 disabled:cursor-not-allowed`}
                      >
                        {effectiveStatus === "AUTO"
                          ? "Tắt tự động"
                          : "Bật tự động"}
                      </button>
                    </div>
                  ) : (
                    <div className="grid grid-cols-3 gap-2">
                      <button
                        onClick={() => setDeviceStatus(device, "ON")}
                        disabled={
                          !!pendingIds[device.id] || effectiveStatus === "ON"
                        }
                        className={`py-2 rounded-lg font-medium transition-colors ${
                          effectiveStatus === "ON"
                            ? "bg-green-600 text-white"
                            : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        } disabled:opacity-50 disabled:cursor-not-allowed`}
                      >
                        Bật
                      </button>
                      <button
                        onClick={() => setDeviceStatus(device, "OFF")}
                        disabled={
                          !!pendingIds[device.id] || effectiveStatus === "OFF"
                        }
                        className={`py-2 rounded-lg font-medium transition-colors ${
                          effectiveStatus === "OFF"
                            ? "bg-red-600 text-white"
                            : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        } disabled:opacity-50 disabled:cursor-not-allowed`}
                      >
                        Tắt
                      </button>
                      <button
                        onClick={() => setDeviceStatus(device, "AUTO")}
                        disabled={
                          !!pendingIds[device.id] || effectiveStatus === "AUTO"
                        }
                        className={`py-2 rounded-lg font-medium transition-colors ${
                          effectiveStatus === "AUTO"
                            ? "bg-white border border-yellow-400 text-yellow-700"
                            : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                        } disabled:opacity-50 disabled:cursor-not-allowed`}
                      >
                        Tự động
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
