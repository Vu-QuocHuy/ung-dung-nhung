import React, { useState, useEffect } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import {
  Thermometer,
  Droplets,
  Sprout,
  Waves,
  Sun,
  TrendingUp,
  TrendingDown,
  BarChart3,
} from "lucide-react";
import { sensorService } from "../../services/sensor.service";
import { toast } from "sonner";

type SensorType =
  | "temperature"
  | "humidity"
  | "soil_moisture"
  | "water_level"
  | "light";

const SENSOR_TYPE_MAP: Record<string, SensorType> = {
  temperature: "temperature",
  humidity: "humidity",
  soilMoisture: "soil_moisture",
  waterLevel: "water_level",
  light: "light",
};

export default function HistoryScreen() {
  const [selectedSensor, setSelectedSensor] =
    useState<SensorType>("temperature");
  const [timeRange, setTimeRange] = useState<"today" | "7days" | "30days">(
    "today"
  );
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [chartData, setChartData] = useState<{ time: string; value: number }[]>(
    []
  );
  const [stats, setStats] = useState<{
    min: number | null;
    max: number | null;
    avg: number | null;
  }>({
    min: null,
    max: null,
    avg: null,
  });

  const sensors = [

    { id: 'temperature', label: 'Nhiệt độ', icon: Thermometer, unit: '°C', color: '#ef4444' },
    { id: 'humidity', label: 'Độ ẩm KK', icon: Droplets, unit: '%', color: '#3b82f6' },
    { id: 'soilMoisture', label: 'Độ ẩm đất', icon: Sprout, unit: '%', color: '#22c55e' },
    { id: 'waterLevel', label: 'Mực nước', icon: Waves, unit: 'cm', color: '#06b6d4' },
    { id: 'light', label: 'Ánh sáng', icon: Sun, unit: '%', color: '#eab308' },

  ];

  const fetchHistory = async () => {
    try {
      setLoading(true);
      const hours =
        timeRange === "today" ? 24 : timeRange === "7days" ? 168 : 720;
      const response = await sensorService.getHistory({
        type: selectedSensor,
        hours,
      });

      // Format data for chart
      const formattedData = response.data.map((point) => {
        const date = new Date(point.createdAt || point.updatedAt);
        let timeLabel = "";

        if (timeRange === "today") {
          timeLabel = `${date.getHours()}:${String(date.getMinutes()).padStart(
            2,
            "0"
          )}`;
        } else if (timeRange === "7days") {
          timeLabel = `${date.getDate()}/${date.getMonth() + 1}`;
        } else {
          timeLabel = `${date.getDate()}/${date.getMonth() + 1}`;
      }
      
        return {
          time: timeLabel,
          value:
            typeof point.value === "number"
              ? parseFloat(point.value.toFixed(1))
              : parseFloat(Number(point.value).toFixed(1)),
        };
      });

      setChartData(formattedData);
      setStats(response.stats || { min: null, max: null, avg: null });
    } catch (error: any) {
      toast.error(
        "Không thể tải lịch sử: " +
          (error.response?.data?.message || error.message)
      );
      setChartData([]);
      setStats({ min: null, max: null, avg: null });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, [selectedSensor, timeRange]);

  const currentSensor = sensors.find((s) => {
    const mappedType = SENSOR_TYPE_MAP[s.id] || s.id;
    return mappedType === selectedSensor;
  })!;

  const handleRefresh = () => {
    setRefreshing(true);
    fetchHistory();
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">Lịch sử dữ liệu</h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Sensor Selection */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="text-gray-900 font-medium mb-4">
            Chọn loại cảm biến
          </div>
          <div className="grid grid-cols-5 gap-3">
            {sensors.map((sensor) => {
              const Icon = sensor.icon;
              const mappedType = SENSOR_TYPE_MAP[sensor.id] || sensor.id;
              const isActive = selectedSensor === mappedType;
              return (
                <button
                  key={sensor.id}
                  onClick={() => setSelectedSensor(mappedType as SensorType)}
                  className={`flex flex-col items-center gap-3 p-4 rounded-xl border-2 transition-all ${
                    isActive
                      ? "border-green-500 bg-green-50"
                      : "border-gray-200 hover:border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  <div
                    className={`p-3 rounded-xl ${
                      isActive ? "bg-green-100" : "bg-gray-100"
                    }`}
                  >
                    <Icon
                      className={`w-6 h-6 ${
                        isActive ? "text-green-600" : "text-gray-500"
                      }`}
                    />
                  </div>
                  <span
                    className={`text-sm font-medium ${
                      isActive ? "text-green-700" : "text-gray-700"
                    }`}
                  >
                    {sensor.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Time Range Selection */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="text-gray-900 font-medium mb-4">Khoảng thời gian</div>
          <div className="flex gap-3">
            {[
              { id: "today", label: "Hôm nay" },
              { id: "7days", label: "7 ngày" },
              { id: "30days", label: "30 ngày" },
            ].map((range) => (
              <button
                key={range.id}
                onClick={() => setTimeRange(range.id as any)}
                className={`px-6 py-3 rounded-lg font-medium transition-colors ${
                  timeRange === range.id
                    ? "bg-green-600 text-white"
                    : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                }`}
              >
                {range.label}
              </button>
            ))}
          </div>
        </div>

        {/* Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-6">
            {React.createElement(currentSensor.icon, {
              className: "w-7 h-7",
              style: { color: currentSensor.color },
            })}
            <h2 className="text-gray-900">{currentSensor.label}</h2>
          </div>
          {loading ? (
            <div className="flex items-center justify-center h-400">
              <div className="text-gray-600">Đang tải dữ liệu...</div>
            </div>
          ) : chartData.length === 0 ? (
            <div className="flex items-center justify-center h-400">
              <div className="text-gray-500">Không có dữ liệu</div>
            </div>
          ) : (

          <ResponsiveContainer width="100%" height={400}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip
                formatter={(value: number) => [`${value} ${currentSensor.unit}`, currentSensor.label]}
              />
              <Line
                type="monotone"
                dataKey="value"
                stroke={currentSensor.color}
                strokeWidth={3}
                dot={{ fill: currentSensor.color, r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>

          )}
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-3 gap-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-red-100 p-3 rounded-lg">
                <TrendingUp className="w-6 h-6 text-red-600" />
              </div>
              <div>
                <div className="text-sm text-gray-500">Giá trị cao nhất</div>
                <div className="text-2xl font-bold text-gray-900">
                  {loading
                    ? "..."
                    : stats.max !== null
                    ? `${stats.max.toFixed(1)} ${currentSensor.unit}`
                    : "-"}
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-blue-100 p-3 rounded-lg">
                <TrendingDown className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <div className="text-sm text-gray-500">Giá trị thấp nhất</div>
                <div className="text-2xl font-bold text-gray-900">
                  {loading
                    ? "..."
                    : stats.min !== null
                    ? `${stats.min.toFixed(1)} ${currentSensor.unit}`
                    : "-"}
                </div>
              </div>
            </div>
          </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-green-100 p-3 rounded-lg">
                <BarChart3 className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <div className="text-sm text-gray-500">Giá trị trung bình</div>
                <div className="text-2xl font-bold text-gray-900">
                  {loading
                    ? "..."
                    : stats.avg !== null
                    ? `${stats.avg.toFixed(1)} ${currentSensor.unit}`
                    : "-"}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
