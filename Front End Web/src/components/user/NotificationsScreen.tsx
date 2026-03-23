import React, { useState, useEffect, useRef } from 'react';
import { AlertCircle, AlertTriangle, Info, Filter, ChevronDown } from 'lucide-react';
import { alertService, Alert } from '../../services/alert.service';
import { toast } from 'sonner';

export default function NotificationsScreen() {
  const [filterMode, setFilterMode] = useState<'status' | 'severity'>('status');
  const [filter, setFilter] = useState<'all' | 'resolved' | 'unresolved'>('all');
  const [severityFilter, setSeverityFilter] = useState<'all' | 'critical' | 'warning' | 'info'>('all');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [notifications, setNotifications] = useState<Alert[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [showTypeDropdown, setShowTypeDropdown] = useState(false);
  const [showValueDropdown, setShowValueDropdown] = useState(false);
  const typeDropdownRef = useRef<HTMLDivElement>(null);
  const valueDropdownRef = useRef<HTMLDivElement>(null);

  const fetchAlerts = async () => {
    try {
      setLoading(true);
      const params: any = { limit: 20, page };
      if (filterMode === 'status') {
      if (filter === 'unresolved') {
        params.status = 'active';
        } else if (filter === 'resolved') {
          params.status = 'resolved';
        }
      }
      if (filterMode === 'severity' && severityFilter !== 'all') {
        params.severity = severityFilter;
      }
      const response = await alertService.getAll(params);
      setNotifications(response.data);
      setTotalPages(response.pages || 1);
    } catch (error: any) {
      toast.error('Không thể tải thông báo: ' + (error.response?.data?.message || error.message));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
  }, [filterMode, filter, severityFilter, page]);

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (typeDropdownRef.current && !typeDropdownRef.current.contains(event.target as Node)) {
        setShowTypeDropdown(false);
      }
      if (valueDropdownRef.current && !valueDropdownRef.current.contains(event.target as Node)) {
        setShowValueDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleResolve = async (id: string) => {
    try {
      await alertService.resolve(id);
      setNotifications((prev) =>
        prev.map((n) => (n._id === id ? { ...n, status: 'resolved' } : n))
      );
      toast.success('Đã xử lý cảnh báo');
    } catch (error: any) {
      toast.error('Không thể xử lý cảnh báo: ' + (error.response?.data?.message || error.message));
    }
  };

  const filteredNotifications = notifications.filter((n) => {
    if (filterMode === 'status') {
      if (filter === 'all') return true;
      if (filter === 'unresolved') return n.status === 'active';
      if (filter === 'resolved') return n.status === 'resolved';
    } else {
      if (severityFilter === 'all') return true;
      return (n.severity || 'info') === severityFilter;
    }
    return true;
  });

  const getCurrentValueLabel = () => {
    if (filterMode === 'status') {
      if (filter === 'all') return 'Tất cả';
      if (filter === 'unresolved') return 'Chưa xử lý';
      if (filter === 'resolved') return 'Đã xử lý';
    } else {
      if (severityFilter === 'all') return 'Tất cả';
      if (severityFilter === 'critical') return 'Nghiêm trọng';
      if (severityFilter === 'warning') return 'Cảnh báo';
      if (severityFilter === 'info') return 'Thông tin';
    }
    return 'Tất cả';
  };

  const handleTypeChange = (type: 'status' | 'severity') => {
    setFilterMode(type);
    if (type === 'status') {
      setFilter('all');
    } else {
      setSeverityFilter('all');
    }
    setShowTypeDropdown(false);
  };

  const handleStatusChange = (value: 'all' | 'resolved' | 'unresolved') => {
    setFilter(value);
    setShowValueDropdown(false);
  };

  const handleSeverityChange = (value: 'all' | 'critical' | 'warning' | 'info') => {
    setSeverityFilter(value);
    setShowValueDropdown(false);
  };

  const formatMessage = (message?: string) => {
    if (!message) return '';
    return message
      .replace(/water_level/gi, 'mực nước')
      .replace(/soil_moisture/gi, 'độ ẩm đất')
      .replace(/temperature/gi, 'nhiệt độ')
      .replace(/humidity/gi, 'độ ẩm không khí')
      .replace(/light/gi, 'ánh sáng');
  };

  const formatTime = (notification: Alert) => {
    // Prefer createdAt -> updatedAt -> resolvedAt -> timestamp
    const ts =
      notification.createdAt ||
      notification.updatedAt ||
      notification.resolvedAt ||
      notification.timestamp;

    if (!ts) return '-';

    const date = new Date(ts);
    if (Number.isNaN(date.getTime())) return '-';

    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Vừa xong';
    if (diffMins < 60) return `${diffMins} phút trước`;
    if (diffHours < 24) return `${diffHours} giờ trước`;
    return `${diffDays} ngày trước`;
  };

  const getLevelConfig = (severity: string) => {
    const configs = {
      critical: {
        icon: AlertCircle,
        color: 'text-red-600',
        bg: 'bg-red-50',
        border: 'border-l-red-500',
        label: 'Nghiêm trọng',
      },
      warning: {
        icon: AlertTriangle,
        color: 'text-orange-600',
        bg: 'bg-orange-50',
        border: 'border-l-orange-500',
        label: 'Cảnh báo',
      },
      info: {
        icon: Info,
        color: 'text-blue-600',
        bg: 'bg-blue-50',
        border: 'border-l-blue-500',
        label: 'Thông tin',
      },
    };
    return configs[severity as keyof typeof configs] || configs.info;
  };

  const handleRefresh = () => {
    setRefreshing(true);
    setPage(1);
    fetchAlerts();
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">Thông báo</h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Filters */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-4">
            <Filter className="w-5 h-5 text-gray-600" />
            
            {/* Loại Dropdown */}
            <div className="relative" ref={typeDropdownRef}>
              <button
                onClick={() => {
                  setShowTypeDropdown(!showTypeDropdown);
                  setShowValueDropdown(false);
                }}
                className="flex items-center gap-2 px-6 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium whitespace-nowrap min-w-[140px] justify-between"
              >
                <span>Loại</span>
                <ChevronDown className={`w-4 h-4 transition-transform ${showTypeDropdown ? 'rotate-180' : ''}`} />
              </button>
              {showTypeDropdown && (
                <div className="absolute top-full left-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-[180px]">
                  <button
                    onClick={() => handleTypeChange('status')}
                    className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                      filterMode === 'status' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                    }`}
                  >
                    Trạng thái
                  </button>
                  <button
                    onClick={() => handleTypeChange('severity')}
                    className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors rounded-b-lg whitespace-nowrap ${
                      filterMode === 'severity' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                    }`}
                  >
                    Mức độ
                  </button>
                </div>
              )}
            </div>

            {/* Value Dropdown */}
            <div className="relative" ref={valueDropdownRef}>
              <button
                onClick={() => {
                  setShowValueDropdown(!showValueDropdown);
                  setShowTypeDropdown(false);
                }}
                className="flex items-center gap-2 px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium whitespace-nowrap min-w-[160px] justify-between"
              >
                <span>{getCurrentValueLabel()}</span>
                <ChevronDown className={`w-4 h-4 transition-transform ${showValueDropdown ? 'rotate-180' : ''}`} />
              </button>
              {showValueDropdown && (
                <div className="absolute top-full left-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-[180px]">
                  {filterMode === 'status' ? (
                    <>
                      <button
                        onClick={() => handleStatusChange('all')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                          filter === 'all' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Tất cả
                      </button>
                      <button
                        onClick={() => handleStatusChange('resolved')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                          filter === 'resolved' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Đã xử lý
                      </button>
                      <button
                        onClick={() => handleStatusChange('unresolved')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors rounded-b-lg whitespace-nowrap ${
                          filter === 'unresolved' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Chưa xử lý
                      </button>
                    </>
                  ) : (
                    <>
                      <button
                        onClick={() => handleSeverityChange('all')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                          severityFilter === 'all' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Tất cả
                      </button>
                      <button
                        onClick={() => handleSeverityChange('critical')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                          severityFilter === 'critical' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Nghiêm trọng
                      </button>
                      <button
                        onClick={() => handleSeverityChange('warning')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors whitespace-nowrap ${
                          severityFilter === 'warning' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Cảnh báo
                      </button>
                      <button
                        onClick={() => handleSeverityChange('info')}
                        className={`w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors rounded-b-lg whitespace-nowrap ${
                          severityFilter === 'info' ? 'bg-purple-50 text-purple-700 font-medium' : 'text-gray-700'
                        }`}
                      >
                        Thông tin
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Notifications List */}
        <div className="space-y-4">
          {loading ? (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
              <div className="text-gray-600">Đang tải...</div>
            </div>
          ) : filteredNotifications.length === 0 ? (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
              <Info className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500 text-lg">Không có thông báo nào</p>
            </div>
          ) : (
            filteredNotifications.map((notification) => {
               const config = getLevelConfig(notification.severity || 'info');
              const Icon = config.icon;
              return (
                <div
                  key={notification._id}
                  className={`bg-white rounded-xl shadow-sm border-l-4 ${config.border} border-t border-r border-b border-gray-200 overflow-hidden hover:shadow-md transition-shadow`}
                >
                  <div className="p-6">
                    <div className="flex items-start gap-4">
                      <div className={`${config.bg} p-3 rounded-xl`}>
                        <Icon className={`w-6 h-6 ${config.color}`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-4 mb-2">
                          <div className="flex items-center gap-3">
                            <h3 className="text-gray-900 font-medium text-lg">
                              {notification.title || notification.message || config.label}
                            </h3>
                            <span
                              className={`text-xs px-3 py-1 rounded-full font-medium ${
                                notification.status === 'resolved'
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-red-100 text-red-700'
                              }`}
                            >
                              {notification.status === 'resolved' ? 'Đã xử lý' : 'Chưa xử lý'}
                            </span>
                          </div>
                          <span className="text-sm text-gray-500 whitespace-nowrap">
                            {formatTime(notification)}
                          </span>
                        </div>
                        <p className="text-gray-600 mb-3">
                          {formatMessage(notification.message)}
                        </p>
                        <div className="flex items-center gap-2">
                          <span
                            className={`text-xs px-3 py-1 rounded-full font-medium ${
                              notification.type === 'critical'
                                ? 'bg-red-100 text-red-700'
                                : notification.type === 'warning'
                                ? 'bg-orange-100 text-orange-700'
                                : 'bg-blue-100 text-blue-700'
                            }`}
                          >
                            {config.label}
                          </span>
                          {notification.status === 'active' && (
                            <button
                              onClick={() => handleResolve(notification._id)}
                              className="text-xs px-3 py-1 rounded-full bg-green-100 text-green-700 font-medium hover:bg-green-200"
                            >
                              Xử lý
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Trước
            </button>
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">
                Trang {page} / {totalPages}
              </span>
            </div>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Sau
            </button>
          </div>
        )}
      </div>
    </div>
  );
}