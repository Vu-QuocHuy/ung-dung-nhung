import React, { useState, useEffect } from 'react';
import {
  Search,
  Plus,
  Edit,
  Lock,
  Unlock,
  Trash2,
  X,
  Users,
  UserCheck,
  Shield,
  RefreshCw,
} from 'lucide-react';
import { userService, User } from '../../services/user.service';
import { authService } from '../../services/auth.service';
import { toast } from 'sonner';

interface UserManagementScreenProps {
  onBack: () => void;
}

export default function UserManagementScreen({ onBack }: UserManagementScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [newUser, setNewUser] = useState({
    username: '',
    email: '',
    password: '',
    role: 'user' as 'admin' | 'user',
    phone: '',
    address: '',
  });
  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState({
    currentPage: 1,
    totalPages: 1,
    totalUsers: 0,
    limit: 10,
  });
  const [currentPage, setCurrentPage] = useState(1);
  const [roleFilter, setRoleFilter] = useState<'admin' | 'user' | ''>('');

  const fetchUsers = async (page: number = 1, search: string = '', role: string = '') => {
    try {
      setLoading(true);
      const params: any = {
        page,
        limit: 10,
      };
      if (search) {
        params.search = search;
      }
      if (role) {
        params.role = role;
      }
      const response = await userService.getAll(params);
      setUsers(response.data);
      setPagination(response.pagination);
    } catch (error: any) {
      toast.error('Không thể tải danh sách người dùng: ' + (error.response?.data?.message || error.message));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchUsers(currentPage, searchQuery, roleFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage, roleFilter]);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (currentPage === 1) {
        fetchUsers(1, searchQuery, roleFilter);
      } else {
        setCurrentPage(1);
      }
    }, 500);

    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchQuery]);

  const stats = {
    total: pagination.totalUsers,
    active: users.filter((u) => u.isActive).length,
    admins: users.filter((u) => u.role === 'admin').length,
  };

  const handleAddUser = async () => {
    if (!newUser.username || !newUser.email || !newUser.password) {
      toast.error('Vui lòng nhập đầy đủ thông tin bắt buộc');
      return;
    }

    if (newUser.username.length < 3) {
      toast.error('Tên người dùng phải có ít nhất 3 ký tự');
      return;
    }

    if (newUser.password.length < 6) {
      toast.error('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    try {
      const registerData: any = {
        username: newUser.username,
        email: newUser.email,
        password: newUser.password,
        role: newUser.role,
      };

      if (newUser.phone) registerData.phone = newUser.phone;
      if (newUser.address) registerData.address = newUser.address;

      await authService.register(registerData);
      toast.success('Thêm người dùng thành công');
    setShowAddDialog(false);
      setNewUser({ 
        username: '', 
        email: '', 
        password: '',
        role: 'user',
        phone: '',
        address: '',
      });
      fetchUsers(currentPage, searchQuery, roleFilter);
    } catch (error: any) {
      toast.error('Không thể thêm người dùng: ' + (error.response?.data?.message || error.message));
    }
  };

  const handleEditUser = async () => {
    if (!selectedUser) return;

    try {
      await userService.update(selectedUser._id, {
        email: selectedUser.email,
        phone: selectedUser.phone,
        address: selectedUser.address,
      });
      toast.success('Cập nhật người dùng thành công');
    setShowEditDialog(false);
    setSelectedUser(null);
      fetchUsers(currentPage, searchQuery, roleFilter);
    } catch (error: any) {
      toast.error('Không thể cập nhật người dùng: ' + (error.response?.data?.message || error.message));
    }
  };

  const toggleUserStatus = async (userId: string) => {
    try {
      await userService.toggleStatus(userId);
      toast.success('Đã cập nhật trạng thái người dùng');
      fetchUsers(currentPage, searchQuery, roleFilter);
    } catch (error: any) {
      toast.error('Không thể cập nhật trạng thái: ' + (error.response?.data?.message || error.message));
    }
  };

  const deleteUser = async (userId: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa người dùng này?')) {
      try {
        await userService.delete(userId);
        toast.success('Đã xóa người dùng');
        fetchUsers(currentPage, searchQuery, roleFilter);
      } catch (error: any) {
        toast.error('Không thể xóa người dùng: ' + (error.response?.data?.message || error.message));
    }
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    fetchUsers(currentPage, searchQuery, roleFilter);
  };

  return (
    <div className="h-full">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6" style={{ paddingTop: '24px', paddingBottom: '24px' }}>
        <div className="flex items-center justify-between">
          <div className="h-[44px] flex items-center">
            <h1 className="text-gray-900 text-lg font-semibold leading-[44px]">Quản lý người dùng</h1>
          </div>
          <div className="flex items-center gap-3">
            <button
            onClick={() => setShowAddDialog(true)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
          >
            <Plus className="w-5 h-5" />
            <span>Thêm người dùng</span>
          </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-3 gap-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-4">
              <div className="bg-blue-100 p-4 rounded-xl">
                <Users className="w-8 h-8 text-blue-600" />
              </div>
              <div>
                <div className="text-3xl font-bold text-blue-600 mb-1">{stats.total}</div>
                <div className="text-gray-600">Tổng số người dùng</div>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-4">
              <div className="bg-green-100 p-4 rounded-xl">
                <UserCheck className="w-8 h-8 text-green-600" />
              </div>
              <div>
                <div className="text-3xl font-bold text-green-600 mb-1">{stats.active}</div>
                <div className="text-gray-600">Đang hoạt động</div>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center gap-4">
              <div className="bg-purple-100 p-4 rounded-xl">
                <Shield className="w-8 h-8 text-purple-600" />
              </div>
              <div>
                <div className="text-3xl font-bold text-purple-600 mb-1">{stats.admins}</div>
                <div className="text-gray-600">Quản trị viên</div>
              </div>
            </div>
          </div>
        </div>

        {/* Search and Filter */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex gap-4">
            <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="Tìm kiếm theo tên, email, số điện thoại..."
              />
            </div>
            <select
              value={roleFilter}
              onChange={(e) => {
                setRoleFilter(e.target.value as 'admin' | 'user' | '');
                setCurrentPage(1);
              }}
              className="px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
            >
              <option value="">Tất cả vai trò</option>
              <option value="admin">Quản trị viên</option>
              <option value="user">Người dùng</option>
            </select>
          </div>
        </div>

        {/* Users List */}
        {loading ? (
          <div className="text-center py-12">
            <div className="text-gray-600">Đang tải...</div>
          </div>
        ) : users.length === 0 ? (
          <div className="text-center py-12">
            <Users className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500 text-lg">Không có người dùng nào</p>
          </div>
        ) : (
          <>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {users.map((user) => (
              <div key={user._id} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                      <h3 className="text-gray-900 font-medium">{user.username}</h3>
                    {user.role === 'admin' && (
                      <span className="px-2 py-1 bg-purple-100 text-purple-700 text-xs rounded-full font-medium">
                        Admin
                      </span>
                    )}
                    <span
                      className={`px-2 py-1 text-xs rounded-full font-medium ${
                          user.isActive
                          ? 'bg-green-100 text-green-700'
                          : 'bg-red-100 text-red-700'
                      }`}
                    >
                        {user.isActive ? 'Hoạt động' : 'Khóa'}
                    </span>
                  </div>
                  <div className="space-y-1 text-sm text-gray-600">
                    <div>
                      <span className="font-medium">Email:</span> {user.email}
                    </div>
                    {user.phone && (
                      <div>
                        <span className="font-medium">Số điện thoại:</span> {user.phone}
                      </div>
                    )}
                    {user.address && (
                      <div>
                        <span className="font-medium">Địa chỉ:</span> {user.address}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => {
                    setSelectedUser(user);
                    setShowEditDialog(true);
                  }}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors font-medium"
                >
                  <Edit className="w-4 h-4" />
                  <span>Sửa</span>
                </button>
                <button
                    onClick={() => toggleUserStatus(user._id)}
                  className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-lg transition-colors font-medium ${
                      user.isActive
                      ? 'bg-orange-50 text-orange-600 hover:bg-orange-100'
                      : 'bg-green-50 text-green-600 hover:bg-green-100'
                  }`}
                >
                    {user.isActive ? (
                    <>
                      <Lock className="w-4 h-4" />
                      <span>Khóa</span>
                    </>
                  ) : (
                    <>
                      <Unlock className="w-4 h-4" />
                      <span>Mở</span>
                    </>
                  )}
                </button>
                <button
                    onClick={() => deleteUser(user._id)}
                  className="flex items-center justify-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors font-medium"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>

            {/* Pagination */}
            {pagination.totalPages > 1 && (
              <div className="flex items-center justify-center gap-2 mt-6">
                <button
                  onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Trước
                </button>
                <div className="flex items-center gap-2">
                  {Array.from({ length: pagination.totalPages }, (_, i) => i + 1).map((page) => (
                    <button
                      key={page}
                      onClick={() => setCurrentPage(page)}
                      className={`px-4 py-2 rounded-lg ${
                        currentPage === page
                          ? 'bg-purple-600 text-white'
                          : 'border border-gray-300 hover:bg-gray-50'
                      }`}
                    >
                      {page}
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => setCurrentPage((prev) => Math.min(pagination.totalPages, prev + 1))}
                  disabled={currentPage === pagination.totalPages}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Sau
                </button>
                <div className="ml-4 text-sm text-gray-600">
                  Trang {pagination.currentPage} / {pagination.totalPages} ({pagination.totalUsers} người dùng)
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Add User Dialog */}
      {showAddDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h2>Thêm người dùng mới</h2>
              <button onClick={() => setShowAddDialog(false)} className="p-1 hover:bg-gray-100 rounded">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2">
                  Tên người dùng <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={newUser.username}
                  onChange={(e) => setNewUser({ ...newUser, username: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Tối thiểu 3 ký tự"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">
                  Email <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  value={newUser.email}
                  onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="example@farm.com"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">
                  Mật khẩu <span className="text-red-500">*</span>
                </label>
                <input
                  type="password"
                  value={newUser.password}
                  onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Tối thiểu 6 ký tự"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Vai trò</label>
                <select
                  value={newUser.role}
                  onChange={(e) => setNewUser({ ...newUser, role: e.target.value as 'admin' | 'user' })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  <option value="user">Người dùng</option>
                  <option value="admin">Quản trị viên</option>
                </select>
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Số điện thoại</label>
                <input
                  type="text"
                  value={newUser.phone}
                  onChange={(e) => setNewUser({ ...newUser, phone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="10 chữ số"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Địa chỉ</label>
                <textarea
                  value={newUser.address}
                  onChange={(e) => setNewUser({ ...newUser, address: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Địa chỉ của người dùng"
                  rows={2}
                />
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setShowAddDialog(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Hủy
                </button>
                <button
                  onClick={handleAddUser}
                  className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                >
                  Thêm
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit User Dialog */}
      {showEditDialog && selectedUser && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h2>Chỉnh sửa người dùng</h2>
              <button onClick={() => setShowEditDialog(false)} className="p-1 hover:bg-gray-100 rounded">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-gray-700 mb-2">Tên người dùng</label>
                <input
                  type="text"
                  value={selectedUser.username || ''}
                  onChange={(e) => setSelectedUser({ ...selectedUser, username: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Email</label>
                <input
                  type="email"
                  value={selectedUser.email || ''}
                  onChange={(e) => setSelectedUser({ ...selectedUser, email: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Số điện thoại</label>
                <input
                  type="text"
                  value={selectedUser.phone || ''}
                  onChange={(e) => setSelectedUser({ ...selectedUser, phone: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="0987654321"
                />
              </div>
              <div>
                <label className="block text-gray-700 mb-2">Địa chỉ</label>
                <input
                  type="text"
                  value={selectedUser.address || ''}
                  onChange={(e) => setSelectedUser({ ...selectedUser, address: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Địa chỉ của người dùng"
                />
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => setShowEditDialog(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Hủy
                </button>
                <button
                  onClick={handleEditUser}
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