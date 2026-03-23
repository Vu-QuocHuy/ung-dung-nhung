import React, { useState } from 'react';
import { Home, Zap, History, Bell, User, Leaf, LogOut } from 'lucide-react';
import HomeScreen from './user/HomeScreen';
import DeviceControlScreen from './user/DeviceControlScreen';
import HistoryScreen from './user/HistoryScreen';
import NotificationsScreen from './user/NotificationsScreen';
import ProfileScreen from './user/ProfileScreen';

interface UserDashboardProps {
  user: {
    id: string;
    name: string;
    email: string;
    role: 'user' | 'admin';
  };
  onLogout: () => void;
}

export default function UserDashboard({ user, onLogout }: UserDashboardProps) {
  const [activeTab, setActiveTab] = useState('home');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  const tabs = [
    { id: 'home', label: 'Trang chủ', icon: Home },
    { id: 'devices', label: 'Thiết bị', icon: Zap },
    { id: 'history', label: 'Lịch sử', icon: History },
    { id: 'notifications', label: 'Thông báo', icon: Bell },
    { id: 'profile', label: 'Cá nhân', icon: User },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <HomeScreen />;
      case 'devices':
        return <DeviceControlScreen />;
      case 'history':
        return <HistoryScreen />;
      case 'notifications':
        return <NotificationsScreen />;
      case 'profile':
        return <ProfileScreen user={user} onLogout={onLogout} />;
      default:
        return <HomeScreen />;
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
            <div className="bg-green-100 p-2 rounded-lg">
              <Leaf className="w-6 h-6 text-green-600" />
            </div>
            {isSidebarOpen && (
              <div className="h-[40px] flex flex-col justify-center leading-none">
                <span className="text-sm font-semibold text-gray-900">
                  Nông Trại
                </span>
                <span className="text-sm font-semibold text-gray-600">
                  Thông Minh
                </span>
              </div>
            )}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center ${isSidebarOpen ? 'gap-3 px-4' : 'justify-center px-2'} py-3 rounded-lg transition-all ${
                  isActive
                    ? 'bg-green-50 text-green-700 font-medium'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
                title={!isSidebarOpen ? tab.label : ''}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'text-green-600' : 'text-gray-500'}`} />
                {isSidebarOpen && <span>{tab.label}</span>}
              </button>
            );
          })}
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
      <main className="flex-1 overflow-y-auto">
        {renderContent()}
      </main>
    </div>
  );
}