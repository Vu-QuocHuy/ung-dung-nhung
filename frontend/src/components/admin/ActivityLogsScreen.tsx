import React, { useState, useEffect } from 'react';
import { Filter, CheckCircle, XCircle, User, Settings, Zap } from 'lucide-react';
import { activityLogService, ActivityLog } from '../../services/activityLog.service';
import { toast } from 'sonner';

interface ActivityLogsScreenProps {
  onBack: () => void;
}

export default function ActivityLogsScreen({ onBack }: ActivityLogsScreenProps) {
  const [filterType, setFilterType] = useState<'all' | 'user' | 'device' | 'threshold' | 'schedule'>('all');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [logs, setLogs] = useState<ActivityLog[]>([]);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const params: any = { limit: 100 };
      // Note: Backend supports filtering by specific action (e.g., 'register_user', 'control_device')
      // but not by resource type. We'll filter by resourceType on client-side instead.
      const response = await activityLogService.getAll(params);
      // Ensure logs is an array
      setLogs(Array.isArray(response.data) ? response.data : []);
    } catch (error: any) {
      toast.error('Không thể tải lịch sử hoạt động: ' + (error.response?.data?.message || error.message));
      setLogs([]); // Set empty array on error
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [filterType]);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchLogs();
  };

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString('vi-VN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getActionLabel = (action: string): string => {
    const actionMap: Record<string, string> = {
      // User management
      'register_user': 'Đăng ký người dùng',
      'update_user': 'Cập nhật người dùng',
      'delete_user': 'Xóa người dùng',
      'toggle_user_status': 'Thay đổi trạng thái người dùng',
      // Device control
      'control_device': 'Điều khiển thiết bị',
      // Schedule
      'create_schedule': 'Tạo lịch trình',
      'update_schedule': 'Cập nhật lịch trình',
      'delete_schedule': 'Xóa lịch trình',
      // Threshold
      'create_threshold': 'Tạo ngưỡng',
      'update_threshold': 'Cập nhật ngưỡng',
      'delete_threshold': 'Xóa ngưỡng',
    };
    return actionMap[action] || action;
  };

  const getResourceTypeLabel = (resourceType?: string): string => {
    const resourceTypeMap: Record<string, string> = {
      'user': 'Người dùng',
      'device': 'Thiết bị',
      'sensor': 'Cảm biến',
      'alert': 'Cảnh báo',
      'schedule': 'Lịch trình',
      'threshold': 'Ngưỡng',
      'system': 'Hệ thống',
    };
    return resourceType ? (resourceTypeMap[resourceType] || resourceType) : '-';
  };

  // Mapping tên thiết bị sang tiếng Việt
  const deviceNameMap: Record<string, string> = {
    'pump': 'Bơm nước',
    'fan': 'Quạt',
    'light': 'Đèn (Tất cả)',
    'servo_door': 'Cửa ra vào (Servo)',
    'servo_feed': 'Cho ăn (Servo)',
    'led_farm': 'Đèn trồng cây',
    'led_animal': 'Đèn khu vật nuôi',
    'led_hallway': 'Đèn hành lang'
  };

  const getResourceName = (log: ActivityLog): string => {
    // Ưu tiên sử dụng resourceName từ backend
    if (log.resourceName) {
      return log.resourceName;
    }

    // Fallback: lấy từ details
    const details = log.details;
    if (!details) {
      return log.resourceId || '-';
    }

    // Lấy tên từ details dựa trên resourceType
    switch (log.resourceType) {
      case 'user':
        // User có thể có username hoặc email trong details
        if (details.username) return details.username;
        if (details.email) return details.email;
        break;
      case 'schedule':
        // Schedule có name trong details
        if (details.name) return details.name;
        break;
      case 'device':
        // Device có deviceName trong details - map sang tiếng Việt
        if (details.deviceName) {
          return deviceNameMap[details.deviceName] || details.deviceName;
        }
        break;
      case 'threshold':
        // Threshold có sensorType trong details
        if (details.sensorType) {
          const sensorTypeMap: Record<string, string> = {
            'temperature': 'Nhiệt độ',
            'soil_moisture': 'Độ ẩm đất',
            'light': 'Ánh sáng',
          };
          return sensorTypeMap[details.sensorType] || details.sensorType;
        }
        break;
    }

    // Nếu không tìm thấy tên trong details, map resourceId nếu là device
    if (log.resourceType === 'device' && log.resourceId) {
      return deviceNameMap[log.resourceId] || log.resourceId;
    }
    return log.resourceId || '-';
  };

  const getLogType = (action: string): 'user' | 'device' | 'threshold' | 'schedule' => {
    const lowerAction = action.toLowerCase();
    if (lowerAction.includes('user')) return 'user';
    if (lowerAction.includes('device')) return 'device';
    if (lowerAction.includes('threshold')) return 'threshold';
    if (lowerAction.includes('schedule')) return 'schedule';
    return 'user';
  };

  const filteredLogs = logs.filter((log) => {
    if (filterType === 'all') return true;
    // Filter by resourceType if available, otherwise fallback to action-based filtering
    if (log.resourceType) {
      const resourceTypeMap: Record<string, string> = {
        'user': 'user',
        'device': 'device',
        'threshold': 'threshold',
        'schedule': 'schedule',
      };
      return resourceTypeMap[log.resourceType] === filterType;
    }
    // Fallback: filter by action pattern
    const logType = getLogType(log.action);
    return logType === filterType;
  });

  const getTypeIcon = (type: string) => {
    const icons = {
      user: User,
      device: Zap,
      threshold: Settings,
      schedule: Filter,
    };
    return icons[type as keyof typeof icons] || User;
  };

  const getTypeLabel = (type: string) => {
    const labels = {
      user: 'Người dùng',
      device: 'Thiết bị',
      threshold: 'Ngưỡng',
      schedule: 'Lịch trình',
    };
    return labels[type as keyof typeof labels] || type;
  };

  const getTypeColor = (type: string) => {
    const colors = {
      user: 'bg-blue-50 text-blue-600',
      device: 'bg-purple-50 text-purple-600',
      threshold: 'bg-orange-50 text-orange-600',
      schedule: 'bg-green-50 text-green-600',
    };
    return colors[type as keyof typeof colors] || 'bg-gray-50 text-gray-600';
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="flex items-center justify-between">
          <div className="h-[44px] flex items-center">
            <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
              Lịch sử hoạt động
            </h1>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Filters */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-4 flex-wrap">
            <Filter className="w-5 h-5 text-gray-500" />
            <span className="font-medium text-gray-900">Lọc theo:</span>
            <button
              onClick={() => setFilterType('all')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                filterType === 'all'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Tất cả
            </button>
            <button
              onClick={() => setFilterType('user')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                filterType === 'user'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Người dùng
            </button>
            <button
              onClick={() => setFilterType('device')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                filterType === 'device'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Thiết bị
            </button>
            <button
              onClick={() => setFilterType('threshold')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                filterType === 'threshold'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Ngưỡng
            </button>
            <button
              onClick={() => setFilterType('schedule')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                filterType === 'schedule'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Lịch trình
            </button>
          </div>
        </div>

        {/* Activity Logs */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Loại
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Người thực hiện
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Hành động
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Đối tượng
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Thời gian
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Trạng thái
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                      Đang tải...
                    </td>
                  </tr>
                ) : filteredLogs.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                      Không có nhật ký hoạt động nào
                    </td>
                  </tr>
                ) : (
                  filteredLogs.map((log) => {
                    const logType = getLogType(log.action);
                    const TypeIcon = getTypeIcon(logType);
                  return (
                      <tr key={log._id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                          <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium ${getTypeColor(logType)}`}>
                          <TypeIcon className="w-4 h-4" />
                            {getTypeLabel(logType)}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                          <div className="font-medium text-gray-900">
                            {log.userId && typeof log.userId === 'object' && 'username' in log.userId
                              ? (log.userId as any).username
                              : log.username || 'System'}
                          </div>
                      </td>
                      <td className="px-6 py-4">
                          <div className="text-gray-900">{getActionLabel(log.action)}</div>
                      </td>
                      <td className="px-6 py-4">
                          <div className="text-gray-600">
                            <div className="font-medium">{getResourceName(log)}</div>
                            <div className="text-sm text-gray-400 mt-1">
                              {getResourceTypeLabel(log.resourceType)}
                            </div>
                          </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-gray-600">
                            {formatTime(log.createdAt || log.timestamp || new Date().toISOString())}
                          </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {log.status === 'success' ? (
                          <div className="inline-flex items-center gap-1 text-green-600">
                            <CheckCircle className="w-5 h-5" />
                            <span className="font-medium">Thành công</span>
                          </div>
                        ) : (
                          <div className="inline-flex items-center gap-1 text-red-600">
                            <XCircle className="w-5 h-5" />
                            <span className="font-medium">Thất bại</span>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                  })
                )}
              </tbody>
            </table>
          </div>

        </div>
      </div>
    </div>
  );
}