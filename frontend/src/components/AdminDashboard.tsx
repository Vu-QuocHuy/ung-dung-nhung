import React, { useState } from 'react';
import { Home, Zap, History, Bell, Users, Settings, FileText, Calendar, Leaf, LogOut, User } from 'lucide-react';
import AdminHomeScreen from './admin/AdminHomeScreen';
import DeviceControlScreen from './user/DeviceControlScreen';
import HistoryScreen from './user/HistoryScreen';
import AdminNotificationsScreen from './admin/AdminNotificationsScreen';
import UserManagementScreen from './admin/UserManagementScreen';
import ThresholdSettingsScreen from './admin/ThresholdSettingsScreen';
import ActivityLogsScreen from './admin/ActivityLogsScreen';
import SchedulesScreen from './admin/SchedulesScreen';
import ProfileScreen from './user/ProfileScreen';

interface AdminDashboardProps {
  user: {
    id: string;
    name: string;
    email: string;
    role: 'user' | 'admin';
  };
  onLogout: () => void;
}

export default function AdminDashboard({ user, onLogout }: AdminDashboardProps) {
  const [activeTab, setActiveTab] = useState('home');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  const mainTabs = [
    { id: 'home', label: 'Trang chủ', icon: Home, section: 'main' },
    { id: 'devices', label: 'Thiết bị', icon: Zap, section: 'main' },
    { id: 'history', label: 'Lịch sử', icon: History, section: 'main' },
    { id: 'notifications', label: 'Thông báo', icon: Bell, section: 'main' },
  ];

  const managementTabs = [
    { id: 'users', label: 'Quản lý người dùng', icon: Users, section: 'management' },
    { id: 'thresholds', label: 'Cài đặt ngưỡng', icon: Settings, section: 'management' },
    { id: 'schedules', label: 'Lịch trình', icon: Calendar, section: 'management' },
    { id: 'logs', label: 'Lịch sử hoạt động', icon: FileText, section: 'management' },
  ];

  const personalTabs = [
    { id: 'profile', label: 'Cá nhân', icon: User, section: 'personal' },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <AdminHomeScreen />;
      case 'devices':
        return <DeviceControlScreen />;
      case 'history':
        return <HistoryScreen />;
      case 'notifications':
        return <AdminNotificationsScreen />;
      case 'users':
        return <UserManagementScreen />;
      case 'thresholds':
        return <ThresholdSettingsScreen />;
      case 'logs':
        return <ActivityLogsScreen />;
      case 'schedules':
        return <SchedulesScreen />;
      case 'profile':
        return <ProfileScreen user={user} onLogout={onLogout} />;
      default:
        return <AdminHomeScreen />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      {/* Sidebar */}
      <aside className={`${isSidebarOpen ? 'w-64' : 'w-20'} bg-white border-r border-gray-200 flex flex-col transition-all duration-300`}>
        {/* Logo */}
        <div className="p-6 border-b border-gray-200">
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="flex items-center gap-3 w-full hover:opacity-80 transition-opacity"
          >
            <div className="bg-gradient-to-br from-purple-500 to-purple-600 p-2 rounded-lg">
              <Leaf className="w-6 h-6 text-white" />
            </div>
            {isSidebarOpen && (
              <div className="h-[40px] flex flex-col justify-center leading-none">
                <span className="text-sm font-semibold text-gray-900">
                  Nông Trại
                </span>
                <span className="text-sm font-semibold text-purple-600">
                  Thông Minh
                </span>
              </div>
            )}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-6 overflow-y-auto">
          {/* Main Section */}
          <div>
            {isSidebarOpen && (
              <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 px-4">
                Chính
              </div>
            )}
            <div className="space-y-1">
              {mainTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center ${isSidebarOpen ? 'gap-3 px-4' : 'justify-center px-2'} py-3 rounded-lg transition-all ${
                      isActive
                        ? 'bg-purple-50 text-purple-700 font-medium'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                    title={!isSidebarOpen ? tab.label : ''}
                  >
                    <Icon className={`w-5 h-5 ${isActive ? 'text-purple-600' : 'text-gray-500'}`} />
                    {isSidebarOpen && <span>{tab.label}</span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Management Section */}
          <div>
            {isSidebarOpen && (
              <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 px-4">
                Quản lý
              </div>
            )}
            <div className="space-y-1">
              {managementTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center ${isSidebarOpen ? 'gap-3 px-4' : 'justify-center px-2'} py-3 rounded-lg transition-all ${
                      isActive
                        ? 'bg-purple-50 text-purple-700 font-medium'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                    title={!isSidebarOpen ? tab.label : ''}
                  >
                    <Icon className={`w-5 h-5 ${isActive ? 'text-purple-600' : 'text-gray-500'}`} />
                    {isSidebarOpen && <span className="text-sm">{tab.label}</span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Personal Section */}
          <div>
            {isSidebarOpen && (
              <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 px-4">
                Cá nhân
              </div>
            )}
            <div className="space-y-1">
              {personalTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center ${isSidebarOpen ? 'gap-3 px-4' : 'justify-center px-2'} py-3 rounded-lg transition-all ${
                      isActive
                        ? 'bg-purple-50 text-purple-700 font-medium'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                    title={!isSidebarOpen ? tab.label : ''}
                  >
                    <Icon className={`w-5 h-5 ${isActive ? 'text-purple-600' : 'text-gray-500'}`} />
                    {isSidebarOpen && <span className="text-sm">{tab.label}</span>}
                  </button>
                );
              })}
            </div>
          </div>
        </nav>

        {/* Logout */}
        <div className="p-4 border-t border-gray-200">
          <button
            onClick={onLogout}
            className={`w-full flex items-center ${isSidebarOpen ? 'gap-3 px-4' : 'justify-center px-2'} py-3 text-red-600 hover:bg-red-50 rounded-lg transition-colors`}
            title={!isSidebarOpen ? 'Đăng xuất' : ''}
          >
            <LogOut className="w-5 h-5" />
            {isSidebarOpen && <span>Đăng xuất</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto bg-gray-50">
        {renderContent()}
      </main>
    </div>
  );
}