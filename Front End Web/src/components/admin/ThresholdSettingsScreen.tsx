import React, { useState, useEffect } from "react";
import {
  Thermometer,
  Droplets,
  Sun,
  Sprout,
  Waves,
  Edit,
  Trash2,
  X,
} from "lucide-react";
import { thresholdService, Threshold } from "../../services/threshold.service";
import { toast } from "sonner";

const SENSOR_CONFIG: Record<
  string,
  { displayName: string; icon: any; unit: string }
> = {
  temperature: { displayName: "Nhiệt độ", icon: Thermometer, unit: "°C" },
  soil_moisture: { displayName: "Độ ẩm đất", icon: Sprout, unit: "%" },
  light: { displayName: "Ánh sáng", icon: Sun, unit: "%" },
};

interface ThresholdSettingsScreenProps {
  onBack: () => void;
}

export default function ThresholdSettingsScreen({
  onBack,
}: ThresholdSettingsScreenProps) {
  const [loading, setLoading] = useState(true);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [selectedThreshold, setSelectedThreshold] = useState<Threshold | null>(
    null
  );
  const [thresholds, setThresholds] = useState<Threshold[]>([]);

  const fetchThresholds = async () => {
    try {
      setLoading(true);
      const data = await thresholdService.getAll();
      setThresholds(data);
    } catch (error: any) {
      toast.error(
        "Không thể tải cài đặt ngưỡng: " +
          (error.response?.data?.message || error.message)
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchThresholds();
  }, []);

  const handleEditThreshold = async () => {
    if (!selectedThreshold) return;

    try {
      await thresholdService.update(selectedThreshold.sensorType, {
        sensorType: selectedThreshold.sensorType,
        thresholdValue: selectedThreshold.thresholdValue,
        severity: selectedThreshold.severity,
        isActive: selectedThreshold.isActive,
      });
      toast.success("Cập nhật ngưỡng thành công");
      setShowEditDialog(false);
      setSelectedThreshold(null);
      fetchThresholds();
    } catch (error: any) {
      toast.error(
        "Không thể cập nhật ngưỡng: " +
          (error.response?.data?.message || error.message)
      );
    }
  };

  const deleteThreshold = async (sensorType: string) => {
    if (window.confirm("Bạn có chắc chắn muốn xóa cài đặt ngưỡng này?")) {
      try {
        await thresholdService.delete(sensorType);
        toast.success("Đã xóa ngưỡng");
        fetchThresholds();
      } catch (error: any) {
        toast.error(
          "Không thể xóa ngưỡng: " +
            (error.response?.data?.message || error.message)
        );
      }
    }
  };

  const toggleThreshold = async (
    sensorType: string,
    currentStatus: boolean
  ) => {
    try {
      await thresholdService.toggle(sensorType, !currentStatus);
      toast.success("Đã cập nhật trạng thái ngưỡng");
      fetchThresholds();
    } catch (error: any) {
      toast.error(
        "Không thể cập nhật trạng thái: " +
          (error.response?.data?.message || error.message)
      );
    }
  };

  const getSeverityColor = (severity: string) => {
    const colors = {
      info: "bg-blue-100 text-blue-700",
      warning: "bg-orange-100 text-orange-700",
      critical: "bg-red-100 text-red-700",
    };
    return colors[severity as keyof typeof colors];
  };

  const getSeverityLabel = (severity: string) => {
    const labels = {
      info: "Thông tin",
      warning: "Cảnh báo",
      critical: "Nghiêm trọng",
    };
    return labels[severity as keyof typeof labels];
  };

  const getAlertTypeLabel = (alertType: string) => {
    const labels = {
      low: "Thấp",
      high: "Cao",
      both: "Cả hai",
    };
    return labels[alertType as keyof typeof labels];
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
            Cài đặt ngưỡng
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {loading ? (
          <div className="text-center py-12">
            <div className="text-gray-600">Đang tải...</div>
          </div>
        ) : thresholds.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">Chưa có cài đặt ngưỡng nào</p>
          </div>
        ) : (
          thresholds.map((threshold) => {
            const config = SENSOR_CONFIG[threshold.sensorType];
            if (!config) return null;
            const Icon = config.icon;
            return (
              <div
                key={threshold.sensorType}
                className={`bg-white rounded-xl shadow-sm border-2 ${
                  threshold.isActive ? "border-green-200" : "border-gray-200"
                } p-6`}
              >
                <div className="flex items-start justify-between mb-6">
                  <div className="flex items-center gap-4">
                    <div
                      className={`p-4 rounded-xl ${
                        threshold.isActive ? "bg-green-50" : "bg-gray-50"
                      }`}
                    >
                      <Icon
                        className={`w-8 h-8 ${
                          threshold.isActive
                            ? "text-green-600"
                            : "text-gray-400"
                        }`}
                      />
                    </div>
                    <div>
                      <h3 className="text-gray-900 font-medium text-lg mb-2">
                        {config.displayName}
                      </h3>
                      <div className="flex items-center gap-2">
                        <span
                          className={`text-xs px-3 py-1 rounded-full font-medium ${getSeverityColor(
                            threshold.severity
                          )}`}
                        >
                          {getSeverityLabel(threshold.severity)}
                        </span>
                        <span
                          className={`text-xs px-3 py-1 rounded-full font-medium ${
                            threshold.isActive
                              ? "bg-green-100 text-green-700"
                              : "bg-gray-100 text-gray-600"
                          }`}
                        >
                          {threshold.isActive ? "Đang bật" : "Tắt"}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-6 mb-6 p-4 bg-gray-50 rounded-xl">
                  <div>
                    <div className="text-sm text-gray-500 mb-1">Ngưỡng</div>
                    <div className="text-gray-900 font-bold text-lg">
                      {threshold.thresholdValue} {config.unit}
                    </div>
                  </div>
                  <div>
                    <div className="text-sm text-gray-500 mb-1">Mức độ</div>
                    <div className="text-gray-900 font-medium">
                      {getSeverityLabel(threshold.severity)}
                    </div>
                  </div>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() =>
                      toggleThreshold(threshold.sensorType, threshold.isActive)
                    }
                    className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                      threshold.isActive
                        ? "bg-orange-50 text-orange-600 hover:bg-orange-100"
                        : "bg-green-50 text-green-600 hover:bg-green-100"
                    }`}
                  >
                    {threshold.isActive ? "Tắt" : "Bật"}
                  </button>
                  <button
                    onClick={() => {
                      setSelectedThreshold(threshold);
                      setShowEditDialog(true);
                    }}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors font-medium"
                  >
                    <Edit className="w-5 h-5" />
                    <span>Chỉnh sửa</span>
                  </button>
                  <button
                    onClick={() => deleteThreshold(threshold.sensorType)}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors font-medium"
                  >
                    <Trash2 className="w-5 h-5" />
                    <span>Xóa</span>
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Edit Dialog */}
      {showEditDialog && selectedThreshold && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6">
            <div className="flex items-center justify-between mb-4">
              <h2>Chỉnh sửa ngưỡng</h2>
              <button
                onClick={() => setShowEditDialog(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2">
                  Giá trị ngưỡng
                </label>
                <input
                  type="number"
                  value={
                    Number.isFinite(selectedThreshold.thresholdValue)
                      ? selectedThreshold.thresholdValue
                      : ""
                  }
                  onChange={(e) =>
                    setSelectedThreshold({
                      ...selectedThreshold,
                      thresholdValue:
                        e.target.value === ""
                          ? 0
                          : Number.isFinite(parseFloat(e.target.value))
                          ? parseFloat(e.target.value)
                          : 0,
                    })
                  }
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div>
                <label className="block text-gray-700 mb-2">
                  Mức độ cảnh báo
                </label>
                <select
                  value={selectedThreshold.severity}
                  onChange={(e) =>
                    setSelectedThreshold({
                      ...selectedThreshold,
                      severity: e.target.value as any,
                    })
                  }
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  <option value="info">Thông tin</option>
                  <option value="warning">Cảnh báo</option>
                  <option value="critical">Nghiêm trọng</option>
                </select>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="enabled"
                  checked={selectedThreshold.isActive}
                  onChange={(e) =>
                    setSelectedThreshold({
                      ...selectedThreshold,
                      isActive: e.target.checked,
                    })
                  }
                  className="w-4 h-4"
                />
                <label htmlFor="enabled" className="text-gray-700">
                  Kích hoạt cảnh báo
                </label>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setShowEditDialog(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Hủy
                </button>
                <button
                  onClick={handleEditThreshold}
                  className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                >
                  Lưu
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
