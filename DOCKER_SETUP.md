# Docker Setup Guide - Smart Farm Management

## Yêu cầu
- Docker Desktop đã cài đặt
- Docker Compose (thường có sẵn với Docker Desktop)

## Cấu trúc dự án
```
.
├── backend/                 # API Server (Node.js)
├── Front End Web/          # Web Interface (React)
├── mobile/                 # Mobile App (Flutter)
├── docker-compose.yml      # Orchestration file
└── DOCKER_SETUP.md        # File này
```

## Hướng dẫn chạy

### 1. Xây dựng images (lần đầu)
```bash
cd /path/to/ung-dung-nhung

# Kiểm tra MongoDB Atlas connection string trước
# Cập nhật MONGODB_URI trong docker-compose.yml nếu cần

docker-compose build
```

### 2. Chạy các services
```bash
# ⚠️ Đảm bảo:
# - MongoDB Atlas acceptlist IP của máy tôi
# - Network Internet hoạt động
# - Credentials đúng

# Chạy tất cả services ở chế độ detached (background)
docker-compose up -d

# Hoặc chạy và xem logs
docker-compose up
```

### 3. Truy cập ứng dụng
- **Frontend**: http://localhost
- **Backend API**: http://localhost:3000
- **MongoDB Atlas**: Managed by MongoDB.com (không access trực tiếp từ local)

### 4. Dừng services
```bash
docker-compose down
```

### 5. Xóa tất cả (volumes, networks)
```bash
docker-compose down -v
```

## Các lệnh hữu ích

### Xem logs
```bash
# Tất cả services
docker-compose logs

# Chỉ backend
docker-compose logs backend

# Chỉ frontend
docker-compose logs frontend

# Xem logs real-time
docker-compose logs -f
```
Xem logs backend chi tiết
docker-compose logs backend -f
```bash
# Vào shell của backend
docker-compose exec backend sh

# Chạy script seed data
docker-compose exec backend node scripts/seed-user.js

# Vào MongoDB
docker-compose exec mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
```

### Rebuild services
```bash
# Rebuild tất cả
docker-compose build --no-cache

# Rebuild chỉ backend
docker-compose build --no-cache backend
```

### Health check
```bash
# Kiểm tra status của các services
docker-compose ps
```

## Cấu hình môi trường

### Backend
- **Cơ sở dữ liệu**: MongoDB Atlas (cloud)
  - URI: `mongodb+srv://quochuy9804_db_user:password@cluster.mongodb.net/database`
  - ⚠️ **Bảo mật**: KHÔNG commit credentials vào git!
  - Cách đổi connection string: chỉnh sửa `MONGODB_URI` trong `docker-compose.yml`
- **Kết nối MQTT**: Sử dụng HiveMQ cloud broker bên ngoài
- **JWT Secret**: Được thiết lập từ docker-compose.yml

### Frontend
- **Port**: 80 (HTTP)
- **API Base URL**: `http://backend:3000` (được giải quyết qua Docker DNS)
- **Build tool**: Vite

### MongoDB Atlas
- **Yêu cầu**: Internet connection để kết nối tới cloud
- **Whitelist IP**: Đảm bảo IP của máy tôi được whitelist trong Atlas
- **Connection String**: Từ MongoDB Atlas > Clusters > Connect > Connect Your Application

## Troubleshooting

### 1. Port đã được sử dụng
```bash
# Thay đổi port trong docker-compose.yml
# Hoặc dừng container đang sử dụng port
lsof -i :3000  # Kiểm tra port 3000
```

### 2. Backend không thể kết nối MongoDB
```bash
# Kiểm tra logs
docker-compose logs backend

# Kiểm tra MongoDB
docker-compose logs mongodb

# Restart services
docker-compose restart
```

### 3. Frontend không thể kết nối Backend
- Kiểm tra `VITE_API_URL` trong docker-compose.yml
- Mở DevTools > Network tab xem requests
- Kiểm tra CORS settings ở backend

### 4. Xóa cache và rebuild
```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## Development Workflow

### Hot reload cho Backend
Backend container đã được cấu hình với volumes:
```yaml
volumes:
  - ./backend/src:/app/src
  - ./backend/scripts:/app/scripts
```
Thay đổi file sẽ trigger restart (nếu dùng `nodemon`)

### Frontend Development
Để phát triển frontend với hot reload, chạy trực tiếp (không dùng Docker):
```bash
cd "Front End Web"
npm install
npm run dev
```

Sau đó cấu hình frontend này để kết nối tới backend Docker:
- Cập nhật `.env` file với `VITE_API_URL=http://localhost:3000`

## Production Considerations

Để chạy production:

1. Cập nhật `.env` với các biến an toàn:
   - Thay đổi `JWT_SECRET`
   - Cập nhật `MONGODB_URI` 
   - Thay đổi mật khẩu MongoDB

2. Build production images:
```bash
docker-compose -f docker-compose.yml build
```

3. Sử dụng docker-compose.prod.yml (tạo nếu cần)

## Mobile App (Flutter)
Mobile app không được chạy trong Docker. Để phát triển:
```bash
cd mobile
flutter pub get
flutter run
```

Cấu hình API endpoint trong mobile app để kết nối tới backend Docker (localhost:3000 nếu chạy emulator)

## Next Steps

1. ✅ Build images: `docker-compose build`
2. ✅ Chạy: `docker-compose up -d`
3. ✅ Kiểm tra: `docker-compose ps`
4. ✅ Truy cập frontend: http://localhost
5. ✅ Xem logs: `docker-compose logs -f`
