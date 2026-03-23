# Smart Farm API Endpoints

Base URL: `https://smart-farm-backend-id2x.onrender.com/api`

## 📋 Table of Contents

- [Authentication APIs](#authentication-apis)
- [User Management APIs](#user-management-apis)
- [Sensor APIs](#sensor-apis)
- [Device Control APIs](#device-control-apis)
- [Alert APIs](#alert-apis)
- [Threshold APIs](#threshold-apis)
- [Schedule APIs](#schedule-apis)
- [Activity Log APIs](#activity-log-apis)

---

## 🔐 Authentication APIs

### 1. Login

- **Endpoint**: `POST /auth/login`
- **Access**: Public
- **Body**:
  ```json
  {
    "email": "admin@gmail.com",
    "password": "admin123"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Đăng nhập thành công",
    "accessToken": "eyJhbGci...",
    "refreshToken": "d70d371...",
    "expiresIn": 900,
    "user": {
      "id": "693966a67e8435beeee71e82",
      "username": "admin",
      "email": "admin@gmail.com",
      "role": "admin"
    }
  }
  ```

### 2. Register (Admin Only)

- **Endpoint**: `POST /auth/register`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "username": "newuser",
    "email": "newuser@example.com",
    "password": "password123"
  }
  ```

### 3. Refresh Token

- **Endpoint**: `POST /auth/refresh`
- **Access**: Public
- **Body**:
  ```json
  {
    "refreshToken": "d70d371..."
  }
  ```

### 4. Logout

- **Endpoint**: `POST /auth/logout`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "refreshToken": "d70d371..."
  }
  ```

### 5. Change Password

- **Endpoint**: `POST /auth/change-password`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "currentPassword": "oldpass123",
    "newPassword": "newpass123",
    "confirmPassword": "newpass123"
  }
  ```

---

## 👥 User Management APIs

### 1. Get All Users (Admin Only)

- **Endpoint**: `GET /users`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `page` (optional)
  - `limit` (optional)
  - `role` (optional): admin | user
  - `isActive` (optional): true | false

### 2. Get User By ID

- **Endpoint**: `GET /users/:id`
- **Access**: Private (Admin or own user)
- **Headers**: `Authorization: Bearer {accessToken}`

### 3. Update User

- **Endpoint**: `PUT /users/:id`
- **Access**: Private (Admin or own user)
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "username": "updated_username",
    "email": "updated@email.com"
  }
  ```

### 4. Toggle User Status (Admin Only)

- **Endpoint**: `PUT /users/:id/toggle-status`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`

### 5. Delete User (Admin Only)

- **Endpoint**: `DELETE /users/:id`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`

---

## 🌡️ Sensor APIs

### 1. Get Latest Sensor Data

- **Endpoint**: `GET /sensors/latest`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "temperature": 28.5,
      "humidity": 65,
      "soilMoisture": 45,
      "waterLevel": 80,
      "light": 15000,
      "timestamp": "2024-12-10T10:30:00Z"
    }
  }
  ```

### 2. Get Sensor History

- **Endpoint**: `GET /sensors/history`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `type`: temperature | humidity | soil_moisture | water_level | light
  - `hours`: 24 (default), 48, 168, etc.
  - `limit` (optional)

### 3. Get All Sensors

- **Endpoint**: `GET /sensors`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `limit`: 50 (default)
  - `page`: 1 (default)

### 4. Cleanup Old Data (Admin Only)

- **Endpoint**: `DELETE /sensors/cleanup`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `days`: 90 (số ngày data cũ cần xóa)

---

## 🎛️ Device Control APIs

### 1. Control Device

- **Endpoint**: `POST /devices/control`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "deviceName": "pump",
    "action": "ON",
    "value": 255
  }
  ```
- **Device Names**: pump | fan | light
- **Actions**: ON | OFF | AUTO
- **Value**: 0-255 (optional, for PWM control)

### 2. Get Device Status

- **Endpoint**: `GET /devices/status`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "pump": {
        "status": "ON",
        "value": 255,
        "lastUpdate": "2024-12-10T10:30:00Z"
      },
      "fan": {
        "status": "OFF",
        "value": 0,
        "lastUpdate": "2024-12-10T10:25:00Z"
      },
      "light": {
        "status": "AUTO",
        "value": 180,
        "lastUpdate": "2024-12-10T10:20:00Z"
      }
    }
  }
  ```

### 3. Get Control History

- **Endpoint**: `GET /devices/history`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `deviceName` (optional): pump | fan | light
  - `limit`: 50 (default)
  - `page`: 1 (default)

---

## 🔔 Alert APIs

### 1. Get All Alerts

- **Endpoint**: `GET /alerts`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `status` (optional): active | resolved
  - `level` (optional): info | warning | critical
  - `isRead` (optional): true | false
  - `limit`: 50 (default)
- **Response**:
  ```json
  {
    "success": true,
    "count": 1,
    "data": [
      {
        "_id": "69395c59ff79d5cf2163b135",
        "type": "warning",
        "message": "Nhiệt độ cao (35.5°C), vượt ngưỡng 35°C",
        "isRead": false,
        "timestamp": "2024-12-10T12:00:00.000Z"
      }
    ]
  }
  ```

### 2. Get Unread Alerts

- **Endpoint**: `GET /alerts/unread`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

### 3. Mark Alert as Read

- **Endpoint**: `PUT /alerts/:id/read`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

### 4. Resolve Alert

- **Endpoint**: `PUT /alerts/:id/resolve`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

### 5. Delete Alert

- **Endpoint**: `DELETE /alerts/:id`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

---

## ⚙️ Threshold APIs

### 1. Get All Thresholds

- **Endpoint**: `GET /thresholds`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

### 2. Get Threshold By Sensor Type

- **Endpoint**: `GET /thresholds/:sensorType`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Sensor Types**: temperature | humidity | soil_moisture | water_level | light

### 3. Create/Update Threshold (Admin Only)

- **Endpoint**: `POST /thresholds`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "sensorType": "temperature",
    "minValue": 15,
    "maxValue": 35,
    "alertType": "both",
    "severity": "warning",
    "isActive": true
  }
  ```
- **Alert Types**: low | high | both
- **Severity**: info | warning | critical

### 4. Update Threshold By Sensor Type (Admin Only)

- **Endpoint**: `PUT /thresholds/:sensorType`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: Same as Create

### 5. Delete Threshold (Admin Only)

- **Endpoint**: `DELETE /thresholds/:sensorType`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`

### 6. Toggle Threshold Active Status (Admin Only)

- **Endpoint**: `PATCH /thresholds/:sensorType/toggle`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "isActive": false
  }
  ```

---

## 📅 Schedule APIs

### 1. Get All Schedules

- **Endpoint**: `GET /schedules`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`

### 2. Create Schedule (Admin Only)

- **Endpoint**: `POST /schedules`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**:
  ```json
  {
    "name": "Tưới sáng",
    "deviceName": "pump",
    "action": "ON",
    "time": "06:00",
    "daysOfWeek": [1, 2, 3, 4, 5],
    "enabled": true
  }
  ```
- **Days of Week**: [0=Sunday, 1=Monday, ..., 6=Saturday]
- **Time Format**: "HH:mm" (e.g., "06:00", "18:30")

### 3. Update Schedule (Admin Only)

- **Endpoint**: `PUT /schedules/:id`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Body**: Same as Create

### 4. Delete Schedule (Admin Only)

- **Endpoint**: `DELETE /schedules/:id`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`

### 5. Toggle Schedule (Admin Only)

- **Endpoint**: `PUT /schedules/:id/toggle`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`

---

## 📊 Activity Log APIs

### 1. Get My Logs

- **Endpoint**: `GET /activity-logs/my-logs`
- **Access**: Private
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `limit`: 20 (default)
  - `page`: 1 (default)

### 2. Get All Logs (Admin Only)

- **Endpoint**: `GET /activity-logs`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `userId` (optional)
  - `action` (optional)
  - `status` (optional): success | failure
  - `startDate` (optional)
  - `endDate` (optional)
  - `limit` (default: 50)
  - `page` (default: 1)

### 3. Get Activity Statistics (Admin Only)

- **Endpoint**: `GET /activity-logs/stats`
- **Access**: Private/Admin
- **Headers**: `Authorization: Bearer {accessToken}`
- **Query Params**:
  - `startDate` (optional)
  - `endDate` (optional)

---

## 📝 Common Response Format

### Success Response

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error information"
}
```

### Pagination Response

```json
{
  "success": true,
  "count": 100,
  "totalPages": 10,
  "currentPage": 1,
  "data": [ ... ]
}
```

---

## 🔑 Authentication

Tất cả các endpoint (trừ login, register, refresh) đều cần gửi kèm Access Token trong header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📌 Notes

1. **Access Token** hết hạn sau 15 phút (900 seconds)
2. **Refresh Token** dùng để lấy Access Token mới
3. Một số endpoint chỉ dành cho **Admin**
4. Tất cả thời gian đều theo chuẩn **ISO 8601**
5. Sensor types: `temperature`, `humidity`, `soil_moisture`, `water_level`, `light`
6. Device names: `pump`, `fan`, `light`
7. Device actions: `ON`, `OFF`, `AUTO`
