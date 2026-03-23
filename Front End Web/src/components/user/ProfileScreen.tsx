import React, { useState, useEffect } from 'react';
import { User, Mail, Shield, Power, Lock, CheckCircle, X, Phone, MapPin, Edit } from 'lucide-react';
import { authService } from '../../services/auth.service';
import { userService, User as UserType } from '../../services/user.service';
import { toast } from 'sonner';

interface ProfileScreenProps {
  user: {
    id: string;
    name: string;
    email: string;
    role: 'user' | 'admin';
  };
  onLogout: () => void;
}

export default function ProfileScreen({ user, onLogout }: ProfileScreenProps) {
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [showEditProfile, setShowEditProfile] = useState(false);
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [userProfile, setUserProfile] = useState<UserType | null>(null);
  const [editForm, setEditForm] = useState({
    email: '',
    phone: '',
    address: '',
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchUserProfile();
  }, [user.id]);

  const fetchUserProfile = async () => {
    try {
      setLoadingProfile(true);
      const profile = await userService.getById(user.id);
      setUserProfile(profile);
      setEditForm({
        email: profile.email || '',
        phone: profile.phone || '',
        address: profile.address || '',
      });
    } catch (error: any) {
      toast.error('Không thể tải thông tin cá nhân');
    } finally {
      setLoadingProfile(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    if (!oldPassword || !newPassword || !confirmPassword) {
      setError('Vui lòng nhập đầy đủ thông tin');
      setLoading(false);
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Mật khẩu mới không khớp');
      setLoading(false);
      return;
    }

    if (newPassword.length < 6) {
      setError('Mật khẩu phải có ít nhất 6 ký tự');
      setLoading(false);
      return;
    }

    try {
      await authService.changePassword({
        currentPassword: oldPassword,
        newPassword,
        confirmPassword,
      });
      toast.success('Đổi mật khẩu thành công!');
      setShowChangePassword(false);
      setOldPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (error: any) {
      setError(error.response?.data?.message || 'Không thể đổi mật khẩu');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveProfile = async () => {
    if (!editForm.email) {
      toast.error('Email không được để trống');
      return;
    }

    try {
      setSaving(true);
      const response = await userService.update(user.id, {
        email: editForm.email,
        phone: editForm.phone || undefined,
        address: editForm.address || undefined,
      });
      
      setUserProfile(response.data);
      toast.success('Cập nhật thông tin thành công');
      setShowEditProfile(false);
    } catch (error: any) {
      toast.error('Không thể cập nhật thông tin: ' + (error.response?.data?.message || error.message));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '30px', paddingBottom: '30px' }}>
        <div className="h-[44px] flex items-center">
          <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">
            Quản lý tài khoản cá nhân
          </h1>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Account Info */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-gray-900">Thông tin tài khoản</h2>
            <div className="flex gap-3">
              <button
                onClick={() => setShowEditProfile(true)}
                className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
              >
                <Edit className="w-4 h-4" />
                <span>Chỉnh sửa</span>
              </button>
              <button
                onClick={() => setShowChangePassword(true)}
                className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
              >
                <Lock className="w-4 h-4" />
                <span>Đổi mật khẩu</span>
              </button>
            </div>
        </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-blue-100 p-3 rounded-lg">
                <User className="w-6 h-6 text-blue-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Họ tên</div>
                <div className="text-gray-900 font-medium">{user.name}</div>
              </div>
            </div>

            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-purple-100 p-3 rounded-lg">
                <Mail className="w-6 h-6 text-purple-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Email</div>
                <div className="text-gray-900 font-medium">
                  {loadingProfile ? 'Đang tải...' : (userProfile?.email || user.email)}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-cyan-100 p-3 rounded-lg">
                <Phone className="w-6 h-6 text-cyan-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Số điện thoại</div>
                <div className="text-gray-900 font-medium">
                  {loadingProfile ? 'Đang tải...' : (userProfile?.phone || 'Chưa cập nhật')}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-pink-100 p-3 rounded-lg">
                <MapPin className="w-6 h-6 text-pink-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Địa chỉ</div>
                <div className="text-gray-900 font-medium">
                  {loadingProfile ? 'Đang tải...' : (userProfile?.address || 'Chưa cập nhật')}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-orange-100 p-3 rounded-lg">
                <Shield className="w-6 h-6 text-orange-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Vai trò</div>
                <div className="text-gray-900 font-medium">
                  {user.role === 'admin' ? 'Quản trị viên' : 'Người dùng'}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
              <div className="bg-green-100 p-3 rounded-lg">
                <CheckCircle className="w-6 h-6 text-green-600" />
              </div>
              <div className="flex-1">
                <div className="text-sm text-gray-500 mb-1">Trạng thái</div>
                <div className="text-green-600 font-medium">Đang hoạt động</div>
              </div>
            </div>
          </div>
        </div>

        {/* Edit Profile Dialog */}
        {showEditProfile && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-2xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-gray-900 text-xl font-semibold">Chỉnh sửa thông tin cá nhân</h2>
                <button
                  onClick={() => {
                    setShowEditProfile(false);
                    if (userProfile) {
                      setEditForm({
                        email: userProfile.email || '',
                        phone: userProfile.phone || '',
                        address: userProfile.address || '',
                      });
                    }
                  }}
                  className="p-1 hover:bg-gray-100 rounded transition-colors"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Email <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    value={editForm.email}
                    onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                    placeholder="Nhập email"
                  />
                </div>

                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Số điện thoại
                  </label>
                  <input
                    type="tel"
                    value={editForm.phone}
                    onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                    placeholder="Nhập số điện thoại"
                  />
                </div>

                <div>
                  <label className="block text-gray-700 mb-2 font-medium">
                    Địa chỉ
                  </label>
                  <textarea
                    value={editForm.address}
                    onChange={(e) => setEditForm({ ...editForm, address: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                    rows={3}
                    placeholder="Nhập địa chỉ"
                  />
                </div>

                <div className="flex gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowEditProfile(false);
                      if (userProfile) {
                        setEditForm({
                          email: userProfile.email || '',
                          phone: userProfile.phone || '',
                          address: userProfile.address || '',
                        });
                      }
                    }}
                    className="flex-1 px-6 py-3 border-2 border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
                  >
                    Hủy
                  </button>
          <button
                    type="button"
                    onClick={handleSaveProfile}
                    disabled={saving}
                    className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {saving ? 'Đang lưu...' : 'Lưu thay đổi'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Change Password Dialog */}
        {showChangePassword && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-2xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-gray-900 text-xl font-semibold">Đổi mật khẩu</h2>
                <button
                  onClick={() => {
                    setShowChangePassword(false);
                    setOldPassword('');
                    setNewPassword('');
                    setConfirmPassword('');
                    setError('');
                  }}
                  className="p-1 hover:bg-gray-100 rounded transition-colors"
                >
                  <X className="w-5 h-5 text-gray-500" />
          </button>
              </div>

            <form onSubmit={handleChangePassword} className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Mật khẩu cũ
                </label>
                <input
                  type="password"
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="Nhập mật khẩu cũ"
                />
              </div>

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Mật khẩu mới
                </label>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="Nhập mật khẩu mới"
                />
              </div>

              <div>
                <label className="block text-gray-700 mb-2 font-medium">
                  Xác nhận mật khẩu mới
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="Nhập lại mật khẩu mới"
                />
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    setShowChangePassword(false);
                    setOldPassword('');
                    setNewPassword('');
                    setConfirmPassword('');
                    setError('');
                  }}
                  className="flex-1 px-6 py-3 border-2 border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                    disabled={loading}
                    className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {loading ? 'Đang xử lý...' : 'Lưu thay đổi'}
                </button>
              </div>
            </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}