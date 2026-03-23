import React from 'react';
import {
  Users,
  Settings,
  FileText,
  Calendar,
  ChevronRight,
  Power,
  User,
  Mail,
  Shield,
} from 'lucide-react';

interface AdminMoreScreenProps {
  onNavigate: (screen: string) => void;
  onLogout: () => void;
  user: {
    id: string;
    name: string;
    email: string;
    role: 'user' | 'admin';
  };
}

export default function AdminMoreScreen({
  onNavigate,
  onLogout,
  user,
}: AdminMoreScreenProps) {
  const menuItems = [
    {
      id: 'users',
      label: 'Quản lý người dùng',
      icon: Users,
      color: 'blue',
      description: 'Thêm, sửa, xóa người dùng',
    },
    {
      id: 'thresholds',
      label: 'Cài đặt ngưỡng',
      icon: Settings,
      color: 'orange',
      description: 'Cấu hình ngưỡng cảnh báo',
    },
    {
      id: 'schedules',
      label: 'Quản lý lịch trình',
      icon: Calendar,
      color: 'green',
      description: 'Tạo và quản lý lịch tự động',
    },
    {
      id: 'logs',
      label: 'Lịch sử hoạt động',
      icon: FileText,
      color: 'purple',
      description: 'Xem lịch sử thao tác hệ thống',
    },
  ];

  const getColorClasses = (color: string) => {
    const colorMap: Record<string, { text: string; bg: string }> = {
      blue: { text: 'text-blue-600', bg: 'bg-blue-50' },
      orange: { text: 'text-orange-600', bg: 'bg-orange-50' },
      green: { text: 'text-green-600', bg: 'bg-green-50' },
      purple: { text: 'text-purple-600', bg: 'bg-purple-50' },
    };
    return colorMap[color];
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-600 to-purple-700 text-white px-6 py-12">
        <div className="max-w-screen-xl mx-auto">
          <div className="flex items-center gap-4 mb-4">
            <div className="bg-white/20 w-16 h-16 rounded-full flex items-center justify-center">
              <User className="w-8 h-8" />
            </div>
            <div>
              <h1 className="mb-1">{user.name}</h1>
              <p className="text-purple-100">{user.email}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-screen-xl mx-auto px-6 py-6 space-y-6">
        {/* Account Info */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="mb-4">Thông tin tài khoản</h2>
          <div className="space-y-3">
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              <Mail className="w-5 h-5 text-gray-600" />
              <div className="flex-1">
                <div className="text-sm text-gray-500">Email</div>
                <div className="text-gray-900">{user.email}</div>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              <Shield className="w-5 h-5 text-gray-600" />
              <div className="flex-1">
                <div className="text-sm text-gray-500">Vai trò</div>
                <div className="text-gray-900">Quản trị viên</div>
              </div>
            </div>
          </div>
        </div>

        {/* Management Menu */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="mb-4">Quản lý hệ thống</h2>
          <div className="space-y-2">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const colors = getColorClasses(item.color);
              return (
                <button
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  className="w-full flex items-center gap-4 p-4 hover:bg-gray-50 rounded-lg transition-colors"
                >
                  <div className={`${colors.bg} p-3 rounded-lg`}>
                    <Icon className={`w-6 h-6 ${colors.text}`} />
                  </div>
                  <div className="flex-1 text-left">
                    <div className="text-gray-900 mb-1">{item.label}</div>
                    <div className="text-sm text-gray-500">{item.description}</div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-gray-400" />
                </button>
              );
            })}
          </div>
        </div>

        {/* Logout */}
        <button
          onClick={onLogout}
          className="w-full bg-white rounded-xl shadow-sm p-4 flex items-center justify-center gap-3 text-red-600 hover:bg-red-50 transition-colors"
        >
          <Power className="w-5 h-5" />
          <span>Đăng xuất</span>
        </button>
      </div>
    </div>
  );
}
