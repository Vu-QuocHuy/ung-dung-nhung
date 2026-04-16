import React, { useState, useEffect } from "react";
import {
  Plus,
  Edit,
  Trash2,
  Clock,
  Calendar,
  X,
  RefreshCw,
} from "lucide-react";
import { scheduleService, Schedule } from "../../services/schedule.service";
import { toast } from "sonner";

const DEVICE_NAMES: Record<string, string> = {
  pump: "Bơm nước",
  fan: "Quạt",
  servo_door: "Cửa ra vào (servo)",
  servo_feed: "Cho ăn (servo)",
  led_farm: "Đèn khu trồng trọt",
  led_animal: "Đèn khu vật nuôi",
  led_hallway: "Đèn hành lang",
};

const DAY_LABELS: Record<number, string> = {
  0: "CN",
  1: "T2",
  2: "T3",
  3: "T4",
  4: "T5",
  5: "T6",
  6: "T7",
};

export default function SchedulesScreen() {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [selectedSchedule, setSelectedSchedule] = useState<Schedule | null>(
    null,
  );
  const [newSchedule, setNewSchedule] = useState({
    name: "",
    deviceName: "pump",
    action: "ON" as "ON" | "OFF" | "RUN" | "AUTO",
    startTime: "",
    endTime: "",
    daysOfWeek: [] as number[],
    executionCount: 1,
  });
  const [schedules, setSchedules] = useState<Schedule[]>([]);

  const fetchSchedules = async () => {
    try {
      setLoading(true);
      const data = await scheduleService.getAll();
      setSchedules(data);
    } catch (error: any) {
      toast.error(
        "Không thể tải lịch trình: " +
          (error.response?.data?.message || error.message),
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchSchedules();
  }, []);

  const devices = [
    { id: "pump", name: "Bơm nước" },
    { id: "fan", name: "Quạt" },
    { id: "servo_door", name: "Cửa ra vào (servo)" },
    { id: "servo_feed", name: "Cho ăn (servo)" },
    { id: "led_farm", name: "Đèn khu trồng trọt" },
    { id: "led_animal", name: "Đèn khu vật nuôi" },
    { id: "led_hallway", name: "Đèn hành lang" },
  ];

  const isServoFeed = (deviceName: string) => deviceName === "servo_feed";

  useEffect(() => {
    // servo_feed: chỉ có 1 hành động: RUN (Thực hiện)
    if (isServoFeed(newSchedule.deviceName)) {
      if (newSchedule.action !== "RUN") {
        setNewSchedule((prev) => ({ ...prev, action: "RUN" }));
      }
      if (
        !Number.isInteger(newSchedule.executionCount) ||
        newSchedule.executionCount < 1
      ) {
        setNewSchedule((prev) => ({ ...prev, executionCount: 1 }));
      }
      return;
    }

    // Thiết bị thường: chỉ ON/OFF (không còn AUTO trong UI)
    if (newSchedule.action === "RUN") {
      setNewSchedule((prev) => ({ ...prev, action: "ON" }));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [newSchedule.deviceName]);

  const daysOfWeek = [
    { id: 0, label: "CN" },
    { id: 1, label: "T2" },
    { id: 2, label: "T3" },
    { id: 3, label: "T4" },
    { id: 4, label: "T5" },
    { id: 5, label: "T6" },
    { id: 6, label: "T7" },
  ];

  const handleAddSchedule = async () => {
    if (
      !newSchedule.name ||
      !newSchedule.deviceName ||
      !newSchedule.startTime ||
      !newSchedule.endTime
    ) {
      toast.error("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newSchedule.daysOfWeek.length === 0) {
      toast.error("Vui lòng chọn ít nhất một ngày");
      return;
    }

    if (newSchedule.startTime >= newSchedule.endTime) {
      toast.error("Thời gian bắt đầu phải nhỏ hơn thời gian kết thúc");
      return;
    }

    if (isServoFeed(newSchedule.deviceName)) {
      if (
        !Number.isInteger(newSchedule.executionCount) ||
        newSchedule.executionCount < 1
      ) {
        toast.error("Lịch cho ăn cần số lần thực hiện >= 1");
        return;
      }
    }

    try {
      await scheduleService.create({
        name: newSchedule.name,
        deviceName: newSchedule.deviceName,
        action: newSchedule.action,
        startTime: newSchedule.startTime,
        endTime: newSchedule.endTime,
        daysOfWeek: newSchedule.daysOfWeek,
        enabled: true,
        executionCount: isServoFeed(newSchedule.deviceName)
          ? newSchedule.executionCount
          : null,
      });
      toast.success("Thêm lịch trình thành công");
      setShowAddDialog(false);
      setNewSchedule({
        name: "",
        deviceName: "pump",
        action: "ON",
        startTime: "",
        endTime: "",
        daysOfWeek: [],
        executionCount: 1,
      });
      fetchSchedules();
    } catch (error: any) {
      toast.error(
        "Không thể thêm lịch trình: " +
          (error.response?.data?.message || error.message),
      );
    }
  };

  const handleEditSchedule = async () => {
    if (!selectedSchedule) return;

    if (isServoFeed(selectedSchedule.deviceName)) {
      if (
        !Number.isInteger(selectedSchedule.executionCount) ||
        (selectedSchedule.executionCount ?? 0) < 1
      ) {
        toast.error("Lịch cho ăn cần số lần thực hiện >= 1");
        return;
      }
    }

    try {
      await scheduleService.update(selectedSchedule._id, {
        name: selectedSchedule.name,
        deviceName: selectedSchedule.deviceName,
        action: selectedSchedule.action,
        startTime: selectedSchedule.startTime,
        endTime: selectedSchedule.endTime,
        daysOfWeek: selectedSchedule.daysOfWeek,
        enabled: selectedSchedule.enabled,
        executionCount: isServoFeed(selectedSchedule.deviceName)
          ? (selectedSchedule.executionCount ?? 1)
          : null,
      });
      toast.success("Cập nhật lịch trình thành công");
      setShowEditDialog(false);
      setSelectedSchedule(null);
      fetchSchedules();
    } catch (error: any) {
      toast.error(
        "Không thể cập nhật lịch trình: " +
          (error.response?.data?.message || error.message),
      );
    }
  };

  useEffect(() => {
    // Khi mở dialog edit: servo_feed ép action về RUN để UI đúng yêu cầu
    if (!showEditDialog || !selectedSchedule) return;
    if (!isServoFeed(selectedSchedule.deviceName)) return;

    if (
      selectedSchedule.action !== "RUN" ||
      !Number.isInteger(selectedSchedule.executionCount) ||
      (selectedSchedule.executionCount ?? 0) < 1
    ) {
      setSelectedSchedule({
        ...selectedSchedule,
        action: "RUN" as any,
        executionCount: selectedSchedule.executionCount ?? 1,
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [showEditDialog]);

  const deleteSchedule = async (id: string) => {
    if (window.confirm("Bạn có chắc chắn muốn xóa lịch trình này?")) {
      try {
        await scheduleService.delete(id);
        toast.success("Đã xóa lịch trình");
        fetchSchedules();
      } catch (error: any) {
        toast.error(
          "Không thể xóa lịch trình: " +
            (error.response?.data?.message || error.message),
        );
      }
    }
  };

  const toggleSchedule = async (id: string) => {
    try {
      await scheduleService.toggle(id);
      toast.success("Đã cập nhật trạng thái lịch trình");
      fetchSchedules();
    } catch (error: any) {
      toast.error(
        "Không thể cập nhật trạng thái: " +
          (error.response?.data?.message || error.message),
      );
    }
  };

  const toggleDay = (dayId: number, isNew: boolean) => {
    if (isNew) {
      setNewSchedule({
        ...newSchedule,
        daysOfWeek: newSchedule.daysOfWeek.includes(dayId)
          ? newSchedule.daysOfWeek.filter((d) => d !== dayId)
          : [...newSchedule.daysOfWeek, dayId],
      });
    } else if (selectedSchedule) {
      setSelectedSchedule({
        ...selectedSchedule,
        daysOfWeek: selectedSchedule.daysOfWeek.includes(dayId)
          ? selectedSchedule.daysOfWeek.filter((d) => d !== dayId)
          : [...selectedSchedule.daysOfWeek, dayId],
      });
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    fetchSchedules();
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-6">
        <div className="flex items-center justify-between">
          <div className="h-[44px] flex items-center">
            <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
              Quản lý lịch trình
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowAddDialog(true)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
            >
              <Plus className="w-5 h-5" />
              <span>Thêm lịch trình</span>
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-8">
        {loading ? (
          <div className="text-center py-12">
            <div className="text-gray-600">Đang tải...</div>
          </div>
        ) : schedules.length === 0 ? (
          <div className="text-center py-16">
            <Calendar className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500 text-lg">Chưa có lịch trình nào</p>
            <button
              onClick={() => setShowAddDialog(true)}
              className="mt-4 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
            >
              Tạo lịch trình đầu tiên
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {schedules.map((schedule) => (
              <div
                key={schedule._id}
                className={`bg-white rounded-xl shadow-sm border-2 p-6 ${
                  schedule.enabled ? "border-purple-200" : "border-gray-200"
                }`}
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-gray-900 font-medium mb-1">
                      {schedule.name}
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {DEVICE_NAMES[schedule.deviceName] || schedule.deviceName}
                    </p>
                  </div>
                  <div
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      schedule.enabled
                        ? "bg-green-100 text-green-700"
                        : "bg-gray-100 text-gray-600"
                    }`}
                  >
                    {schedule.enabled ? "Hoạt động" : "Tắt"}
                  </div>
                </div>

                <div className="space-y-3 mb-4">
                  <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                    <Clock className="w-5 h-5 text-purple-600" />
                    <div>
                      <div className="text-xs text-gray-500">Thời gian</div>
                      <div className="text-gray-900 font-medium">
                        {schedule.startTime} - {schedule.endTime}
                      </div>
                    </div>
                  </div>

                  {isServoFeed(schedule.deviceName) && (
                    <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                      <RefreshCw className="w-5 h-5 text-purple-600" />
                      <div>
                        <div className="text-xs text-gray-500">
                          Số lần thực hiện
                        </div>
                        <div className="text-gray-900 font-medium">
                          {Number.isInteger(schedule.executionCount) &&
                          (schedule.executionCount ?? 0) > 0
                            ? `${schedule.executionCount} lần`
                            : "Chưa cấu hình"}
                        </div>
                      </div>
                    </div>
                  )}

                  <div className="p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Calendar className="w-5 h-5 text-purple-600" />
                      <div className="text-xs text-gray-500">
                        Ngày trong tuần
                      </div>
                    </div>
                    <div className="flex gap-1 flex-wrap">
                      {daysOfWeek.map((day) => (
                        <span
                          key={day.id}
                          className={`px-2 py-1 rounded text-xs font-medium ${
                            schedule.daysOfWeek.includes(day.id)
                              ? "bg-purple-100 text-purple-700"
                              : "bg-gray-200 text-gray-500"
                          }`}
                        >
                          {day.label}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={() => toggleSchedule(schedule._id)}
                    className={`flex-1 py-2 px-3 rounded-lg font-medium transition-colors ${
                      schedule.enabled
                        ? "bg-orange-50 text-orange-600 hover:bg-orange-100"
                        : "bg-green-50 text-green-600 hover:bg-green-100"
                    }`}
                  >
                    {schedule.enabled ? "Tắt" : "Bật"}
                  </button>
                  <button
                    onClick={() => {
                      setSelectedSchedule(schedule);
                      setShowEditDialog(true);
                    }}
                    className="flex items-center justify-center gap-1 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                  >
                    <Edit className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => deleteSchedule(schedule._id)}
                    className="flex items-center justify-center gap-1 px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Dialog */}
      {showAddDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-gray-900">Thêm lịch trình mới</h2>
              <button
                onClick={() => setShowAddDialog(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Tên lịch trình
                </label>
                <input
                  type="text"
                  value={newSchedule.name}
                  onChange={(e) =>
                    setNewSchedule({ ...newSchedule, name: e.target.value })
                  }
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Ví dụ: Tưới sáng"
                />
              </div>

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Thiết bị
                </label>
                <select
                  value={newSchedule.deviceName}
                  onChange={(e) =>
                    setNewSchedule({
                      ...newSchedule,
                      deviceName: e.target.value,
                    })
                  }
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  <option value="">Chọn thiết bị</option>
                  {devices.map((device) => (
                    <option key={device.id} value={device.id}>
                      {device.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Hành động
                </label>
                <select
                  value={newSchedule.action}
                  onChange={(e) =>
                    setNewSchedule({
                      ...newSchedule,
                      action: e.target.value as any,
                    })
                  }
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  {isServoFeed(newSchedule.deviceName) ? (
                    <option value="RUN">Thực hiện</option>
                  ) : (
                    <>
                      <option value="ON">Bật</option>
                      <option value="OFF">Tắt</option>
                    </>
                  )}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Thời gian bắt đầu
                  </label>
                  <input
                    type="time"
                    value={newSchedule.startTime}
                    onChange={(e) =>
                      setNewSchedule({
                        ...newSchedule,
                        startTime: e.target.value,
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Thời gian kết thúc
                  </label>
                  <input
                    type="time"
                    value={newSchedule.endTime}
                    onChange={(e) =>
                      setNewSchedule({
                        ...newSchedule,
                        endTime: e.target.value,
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              </div>

              {isServoFeed(newSchedule.deviceName) && (
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Số lần thực hiện
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={1440}
                    step={1}
                    value={newSchedule.executionCount}
                    onChange={(e) =>
                      setNewSchedule({
                        ...newSchedule,
                        executionCount: Math.min(
                          1440,
                          Math.max(1, parseInt(e.target.value || "1", 10)),
                        ),
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                  <p className="text-sm text-gray-500 mt-2">
                    Ví dụ: 5 phút và 10 lần - hệ thống sẽ phân bố đều 10 lần
                    trong 5 phút.
                  </p>
                </div>
              )}

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Ngày trong tuần
                </label>
                <div className="flex gap-2 flex-wrap">
                  {daysOfWeek.map((day) => (
                    <button
                      key={day.id}
                      type="button"
                      onClick={() => toggleDay(day.id, true)}
                      className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                        newSchedule.daysOfWeek.includes(day.id)
                          ? "bg-purple-600 text-white"
                          : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                      }`}
                    >
                      {day.label}
                    </button>
                  ))}
                </div>
                <p className="text-sm text-gray-500 mt-2">
                  Vui lòng chọn ít nhất một ngày
                </p>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => setShowAddDialog(false)}
                  className="flex-1 px-6 py-3 border-2 border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
                >
                  Hủy
                </button>
                <button
                  onClick={handleAddSchedule}
                  className="flex-1 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
                >
                  Thêm
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Dialog */}
      {showEditDialog && selectedSchedule && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-gray-900">Chỉnh sửa lịch trình</h2>
              <button
                onClick={() => setShowEditDialog(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Tên lịch trình
                </label>
                <input
                  type="text"
                  value={selectedSchedule.name}
                  onChange={(e) =>
                    setSelectedSchedule({
                      ...selectedSchedule,
                      name: e.target.value,
                    })
                  }
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Thời gian bắt đầu
                  </label>
                  <input
                    type="time"
                    value={selectedSchedule.startTime}
                    onChange={(e) =>
                      setSelectedSchedule({
                        ...selectedSchedule,
                        startTime: e.target.value,
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Thời gian kết thúc
                  </label>
                  <input
                    type="time"
                    value={selectedSchedule.endTime}
                    onChange={(e) =>
                      setSelectedSchedule({
                        ...selectedSchedule,
                        endTime: e.target.value,
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              </div>

              {isServoFeed(selectedSchedule.deviceName) && (
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Số lần thực hiện
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={1440}
                    step={1}
                    value={selectedSchedule.executionCount ?? 1}
                    onChange={(e) =>
                      setSelectedSchedule({
                        ...selectedSchedule,
                        executionCount: Math.min(
                          1440,
                          Math.max(1, parseInt(e.target.value || "1", 10)),
                        ),
                      })
                    }
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              )}

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Hành động
                </label>
                <select
                  value={selectedSchedule.action}
                  onChange={(e) =>
                    setSelectedSchedule({
                      ...selectedSchedule,
                      action: e.target.value as any,
                    })
                  }
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  {isServoFeed(selectedSchedule.deviceName) ? (
                    <option value="RUN">Thực hiện</option>
                  ) : (
                    <>
                      {selectedSchedule.action === "AUTO" && (
                        <option value="AUTO" disabled>
                          Tự động (không còn hỗ trợ)
                        </option>
                      )}
                      <option value="ON">Bật</option>
                      <option value="OFF">Tắt</option>
                    </>
                  )}
                </select>
              </div>

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Ngày trong tuần
                </label>
                <div className="flex gap-2 flex-wrap">
                  {daysOfWeek.map((day) => (
                    <button
                      key={day.id}
                      type="button"
                      onClick={() => toggleDay(day.id, false)}
                      className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                        selectedSchedule.daysOfWeek.includes(day.id)
                          ? "bg-purple-600 text-white"
                          : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                      }`}
                    >
                      {day.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center gap-3 p-4 bg-gray-50 rounded-lg">
                <input
                  type="checkbox"
                  id="enabled"
                  checked={selectedSchedule.enabled}
                  onChange={(e) =>
                    setSelectedSchedule({
                      ...selectedSchedule,
                      enabled: e.target.checked,
                    })
                  }
                  className="w-5 h-5"
                />
                <label htmlFor="enabled" className="text-gray-700 font-medium">
                  Kích hoạt lịch trình
                </label>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => setShowEditDialog(false)}
                  className="flex-1 px-6 py-3 border-2 border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
                >
                  Hủy
                </button>
                <button
                  onClick={handleEditSchedule}
                  className="flex-1 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
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
