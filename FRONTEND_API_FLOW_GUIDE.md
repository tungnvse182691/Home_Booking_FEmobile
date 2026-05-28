# Homestay Booking Backend API Guide for Flutter Frontend

## 1. Cover Page
- **Title**: Homestay Booking Backend API Guide for Flutter Frontend
- **Project**: PRM393 Mobile Application Development
- **Backend**: ASP.NET Core Web API + MySQL + EF Core Code First
- **Frontend**: Flutter
- **Base URL**: `http://localhost:8080`
- **Date generated**: 2026-05-19

## 2. Business Overview
Ứng dụng Homestay Booking cho phép:
- **Customer** (Khách hàng): Tìm kiếm, xem chi tiết và đặt phòng homestay. Xem lịch sử đặt phòng, thanh toán, đánh giá và quản lý phòng yêu thích.
- **Host** (Chủ nhà): Quản lý danh sách phòng của mình, theo dõi các lượt đặt phòng và xem báo cáo doanh thu từ các phòng đó.
- **Admin** (Quản trị viên): Quản lý toàn bộ hệ thống bao gồm người dùng, thống kê doanh thu toàn hệ thống, quản lý khóa/mở khóa tài khoản.

## 3. Team / Backend Scope
- **Huy**: Auth improvements, Register/Login/Forgot password/Reset password/Google login, Email sending, Profile, Rooms browse/search/filter/detail, Favorites, Reviews, Notifications, Room support APIs (room types, amenities).
- **Khoa**: Booking flow, Booking history/cancel/change date, Payment/mock MoMo/VNPay flow, Host room management, Host dashboard/revenue, Admin user management, Admin dashboard, Admin payment/revenue reports, Map/Seed data.

## 4. System Architecture for Frontend
- Flutter calls REST API
- JWT Bearer authentication
- Role-based routing
- MySQL backend
- Email SMTP
- Mock payment gateway

## 5. App Flow by Role
### 5.1 Customer Flow
- Đăng ký / Đăng nhập
- Lướt xem danh sách phòng
- Lọc/Tìm kiếm phòng
- Xem chi tiết phòng và Reviews
- Đặt phòng -> Chọn ngày -> Checkout -> Thanh toán Mock (CASH/MOMO)
- Quản lý lịch sử đặt phòng (Hủy / Đổi ngày)
- Đánh giá phòng sau khi hoàn tất.

### 5.2 Host Flow
- Đăng nhập (tài khoản Host)
- Xem Host Dashboard (Chỉ dữ liệu phòng của Host)
- Quản lý phòng (Thêm, sửa, xóa phòng của chính mình)
- Xem Host Revenue (Doanh thu của chính mình)

### 5.3 Admin Flow
- Đăng nhập (tài khoản Admin)
- Xem Admin Dashboard (Dữ liệu toàn hệ thống)
- Quản lý User (Ban / Unban / Đổi Role)
- Quản lý toàn bộ Booking và Thanh toán
- Xem báo cáo tổng hợp.

## 6. Authentication Flow
- **Register**: `POST /api/auth/register`
- **Login**: `POST /api/auth/login` -> Trả về `accessToken`
- **Store token**: Flutter lưu `accessToken` và `role` vào Secure Storage.
- **Authorize request**: Thêm Header `Authorization: Bearer <accessToken>`
- **Get current user**: Gọi `GET /api/auth/me` để lấy thông tin.
- **Logout**: `POST /api/auth/logout` và xóa token ở client.
- **Forgot password**: Gửi email -> Lấy code
- **Reset password**: Nhập code + password mới
- **Google login**: Trả về token giống như Login.

## 7. API Convention
- **Base URL**: `http://localhost:8080` (hoặc IP máy tính nếu chạy trên máy ảo/máy thật)
- **Authorization header**: `Authorization: Bearer <token>`
- **Common success response**:
```json
{
  "success": true,
  "message": "Thao tác thành công",
  "data": { ... }
}
```
- **Common error response**:
```json
{
  "success": false,
  "message": "Chi tiết lỗi",
  "errors": ["Lỗi 1", "Lỗi 2"]
}
```
- **Date format**: `yyyy-MM-dd`
- **DateTime format**: ISO `yyyy-MM-ddTHH:mm:ssZ`

## 8. Final Role Strategy
| Role | Main screen | Allowed APIs | Data scope |
|---|---|---|---|
| ADMIN | Admin Dashboard | `/api/admin/*` + shared APIs | Global system data |
| HOST | Host Dashboard | `/api/host/*` + shared APIs | Own host rooms/data |
| CUSTOMER | Customer Home | customer APIs + shared APIs | Own user data |

*Forbidden examples:*
- CUSTOMER -> `/api/host/dashboard` = 403
- CUSTOMER -> `/api/admin/dashboard` = 403
- HOST -> `/api/admin/dashboard` = 403
- ADMIN -> `/api/bookings/my-history` = 403

## 9. Demo Accounts
- **ADMIN**:
  - Email: admin@gmail.com
  - Password: password123
- **HOST**:
  - Email: host@gmail.com
  - Password: password123
- **CUSTOMER**:
  - Email: customer@gmail.com
  - Password: password123

## 10. Frontend Screen Mapping
| Screen | Role | APIs used | Notes |
|---|---|---|---|
| LoginScreen | Public | `POST /api/auth/login`, `POST /api/auth/google` | |
| RegisterScreen | Public | `POST /api/auth/register` | |
| ForgotPasswordScreen | Public | `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` | |
| CustomerHomeScreen | CUSTOMER | `GET /api/rooms`, `GET /api/room-types`, `GET /api/amenities` | |
| RoomDetailScreen | CUSTOMER | `GET /api/rooms/{id}`, `GET /api/rooms/{id}/reviews`, `POST /api/favorites`, `DELETE /api/favorites/{id}` | |
| BookingCreateScreen | CUSTOMER | `POST /api/bookings` | |
| PaymentScreen | CUSTOMER | `POST /api/payments/create`, `POST /api/payments/confirm` | |
| BookingHistoryScreen| CUSTOMER | `GET /api/bookings/my-history`, `PATCH /api/bookings/{id}/cancel`, `PUT /api/bookings/{id}/change-date` | |
| FavoritesScreen | CUSTOMER | `GET /api/favorites` | |
| ProfileScreen | All | `GET /api/profile`, `PUT /api/profile` | |
| NotificationsScreen | All | `GET /api/notifications`, `PATCH /api/notifications/{id}/read` | |
| HostDashboardScreen | HOST | `GET /api/host/dashboard` | |
| HostRoomsScreen | HOST | `GET /api/host/rooms`, `POST /api/host/rooms`, `PUT /api/host/rooms/{id}`, `DELETE /api/host/rooms/{id}` | |
| HostRevenueScreen | HOST | `GET /api/host/reports/revenue` | |
| AdminDashboardScreen| ADMIN | `GET /api/admin/dashboard` | |
| AdminUsersScreen | ADMIN | `GET /api/admin/users`, `PATCH /api/admin/users/{id}/status`, `PATCH /api/admin/users/{id}/role` | |
| AdminPaymentsScreen | ADMIN | `GET /api/admin/payments` | |
| AdminReportsScreen | ADMIN | `GET /api/admin/reports/revenue` | |

## 11. Full API Reference

### 11.1 AUTH

**Endpoint:**
`POST /api/auth/login`
- **Method:** POST
- **Auth required:** No
- **Allowed roles:** Public
- **Used by frontend screen:** LoginScreen
- **Description:** Đăng nhập hệ thống

**Request JSON:**
```json
{
  "emailOrPhone": "customer@gmail.com",
  "password": "password123"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "refresh-token-example",
    "expiresAt": "2026-05-19T10:30:00Z",
    "user": {
      "userId": 3,
      "fullName": "Customer Demo",
      "email": "customer@gmail.com",
      "phone": "0900000001",
      "role": "CUSTOMER",
      "status": "ACTIVE",
      "avatarUrl": null
    }
  }
}
```
**Error response JSON:**
```json
{
  "success": false,
  "message": "Invalid email or password."
}
```
**Business rules:**
- Tài khoản BANNED/INACTIVE không thể đăng nhập.
- Flutter phải lưu `accessToken` và route màn hình dựa theo `role`.

---

**Endpoint:**
`POST /api/auth/register`
- **Method:** POST
- **Auth required:** No
- **Allowed roles:** Public
- **Description:** Đăng ký tài khoản Customer mới

**Request JSON:**
```json
{
  "fullName": "Nguyen Van Customer",
  "email": "customer.demo@gmail.com",
  "phone": "0901234567",
  "password": "password123"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": null
}
```

---

**Endpoint:**
`POST /api/auth/forgot-password`
- **Method:** POST
- **Auth required:** No
- **Allowed roles:** Public

**Request JSON:**
```json
{
  "email": "customer@gmail.com"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Reset code sent to your email",
  "data": null
}
```

---

**Endpoint:**
`POST /api/auth/reset-password`
- **Method:** POST
- **Auth required:** No
- **Allowed roles:** Public

**Request JSON:**
```json
{
  "email": "customer@gmail.com",
  "code": "123456",
  "newPassword": "newpassword123"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

**Endpoint:**
`GET /api/auth/me`
- **Method:** GET
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER, HOST, ADMIN

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "userId": 3,
    "fullName": "Customer Demo",
    "email": "customer@gmail.com",
    "role": "CUSTOMER"
  }
}
```

### 11.2 PROFILE

**Endpoint:**
`GET /api/profile`
- **Method:** GET
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER, HOST, ADMIN

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "userId": 3,
    "fullName": "Customer Demo",
    "email": "customer@gmail.com",
    "phone": "0900000001",
    "avatarUrl": "https://example.com/avatar.jpg"
  }
}
```

---

**Endpoint:**
`PUT /api/profile`
- **Method:** PUT
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER, HOST, ADMIN

**Request JSON:**
```json
{
  "fullName": "Nguyen Van Customer Updated",
  "phone": "0901234568",
  "avatarUrl": "https://example.com/avatar.jpg"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Profile updated successfully"
}
```

### 11.3 ROOMS

**Endpoint:**
`GET /api/rooms`
- **Method:** GET
- **Auth required:** No
- **Allowed roles:** Public
- **Query params:** `searchTerm`, `city`, `roomTypeId`, `minPrice`, `maxPrice`, `pageNumber`, `pageSize`

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "roomId": 1,
        "name": "Cozy Studio Near City Center",
        "city": "Can Tho",
        "pricePerNight": 450000,
        "thumbnailUrl": "https://picsum.photos/800/600",
        "rating": 4.5,
        "reviewCount": 12
      }
    ],
    "totalCount": 1,
    "pageNumber": 1,
    "pageSize": 10,
    "totalPages": 1
  }
}
```

---

**Endpoint:**
`GET /api/rooms/{roomId}`
- **Method:** GET
- **Auth required:** No

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "roomId": 1,
    "name": "Cozy Studio Near City Center",
    "description": "...",
    "address": "123 Nguyen Van Cu",
    "pricePerNight": 450000,
    "maxGuests": 2,
    "amenities": [
      {"amenityId": 1, "name": "WiFi", "iconUrl": "wifi_icon"}
    ],
    "images": [
      {"imageUrl": "...", "isThumbnail": true}
    ]
  }
}
```

### 11.4 BOOKINGS

**Endpoint:**
`POST /api/bookings`
- **Method:** POST
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER

**Request JSON:**
```json
{
  "roomId": 30,
  "checkInDate": "2026-06-10",
  "checkOutDate": "2026-06-12",
  "paymentMethod": "MOMO",
  "specialRequest": "I want a quiet room."
}
```

**Success response JSON:**
```json
{
  "success": true,
  "message": "Booking created successfully.",
  "data": {
    "bookingId": 201,
    "bookingCode": "BK2026001234",
    "totalAmount": 900000,
    "status": "PENDING"
  }
}
```

---

**Endpoint:**
`GET /api/bookings/my-history`
- **Method:** GET
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER

**Success response JSON:**
```json
{
  "success": true,
  "data": [
    {
      "bookingId": 201,
      "roomName": "Cozy Studio",
      "checkInDate": "2026-06-10",
      "checkOutDate": "2026-06-12",
      "totalAmount": 900000,
      "status": "COMPLETED"
    }
  ]
}
```

---

**Endpoint:**
`PATCH /api/bookings/{id}/cancel`
- **Method:** PATCH
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER

**Success response JSON:**
```json
{
  "success": true,
  "message": "Booking cancelled successfully"
}
```

### 11.5 PAYMENTS

**Endpoint:**
`POST /api/payments/create`
- **Method:** POST
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER

**Request JSON:**
```json
{
  "bookingId": 201,
  "paymentMethod": "MOMO"
}
```
**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "paymentUrl": "https://test-payment.momo.vn/...",
    "transactionCode": "TXN123456"
  }
}
```

---

**Endpoint:**
`POST /api/payments/confirm`
- **Method:** POST
- **Auth required:** Yes
- **Allowed roles:** CUSTOMER

**Request JSON:**
```json
{
  "transactionCode": "TXN123456",
  "success": true
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Payment confirmed successfully"
}
```

### 11.6 HOST DASHBOARD & ROOMS

**Endpoint:**
`GET /api/host/dashboard`
- **Method:** GET
- **Auth required:** Yes
- **Allowed roles:** HOST

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "totalRooms": 3,
    "totalBookings": 11,
    "totalRevenue": 4500000,
    "recentBookings": [
      {
         "bookingId": 201,
         "customerName": "Nguyen Van A",
         "status": "COMPLETED"
      }
    ]
  }
}
```

---

**Endpoint:**
`POST /api/host/rooms`
- **Method:** POST
- **Auth required:** Yes
- **Allowed roles:** HOST

**Request JSON:**
```json
{
  "name": "Cozy Studio Near City Center",
  "description": "A clean studio room suitable for two guests, close to local restaurants and attractions.",
  "address": "123 Nguyen Van Cu Street",
  "city": "Can Tho",
  "district": "Ninh Kieu",
  "ward": "An Khanh",
  "areaName": "Ninh Kieu Center",
  "pricePerNight": 450000,
  "maxGuests": 2,
  "bedrooms": 1,
  "bathrooms": 1,
  "latitude": 10.0452,
  "longitude": 105.7469,
  "roomTypeId": 1,
  "isFeatured": true,
  "imageUrls": [
    "https://picsum.photos/800/600?random=101",
    "https://picsum.photos/800/600?random=102"
  ],
  "amenityIds": [1, 2, 3]
}
```
**Success response JSON:**
```json
{
  "success": true,
  "message": "Room created successfully"
}
```

### 11.7 ADMIN DASHBOARD & USERS

**Endpoint:**
`GET /api/admin/dashboard`
- **Method:** GET
- **Auth required:** Yes
- **Allowed roles:** ADMIN

**Success response JSON:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 50,
    "totalRooms": 30,
    "totalBookings": 100,
    "totalRevenue": 50000000
  }
}
```

---

**Endpoint:**
`PATCH /api/admin/users/{id}/status`
- **Method:** PATCH
- **Auth required:** Yes
- **Allowed roles:** ADMIN

**Request JSON:**
```json
{
  "status": "BANNED"
}
```

---

**Endpoint:**
`PATCH /api/admin/users/{id}/role`
- **Method:** PATCH
- **Auth required:** Yes
- **Allowed roles:** ADMIN

**Request JSON:**
```json
{
  "role": "HOST"
}
```

## 12. Error Handling Guide for Flutter
- **400 Bad Request**: Lỗi Validation. Hiện SnackBar thông báo `message`.
- **401 Unauthorized**: Token thiếu hoặc hết hạn. Clear toàn bộ token dưới local và chuyển người dùng về `LoginScreen`.
- **403 Forbidden**: Sai Role (Ví dụ Customer vào Host). Hiện màn hình lỗi hoặc SnackBar "Bạn không có quyền truy cập".
- **404 Not Found**: Endpoint hoặc Object ID không tồn tại.
- **409 Conflict**: Trùng lặp dữ liệu (ví dụ thêm Favorite phòng đã có).
- **500 Server Error**: Lỗi Backend. Báo chung "Có lỗi xảy ra từ máy chủ, vui lòng thử lại sau".

## 13. Testing Checklist
- Đăng nhập `customer@gmail.com` -> Đặt phòng, thanh toán -> Thành công.
- Đăng nhập `host@gmail.com` -> Load Dashboard có thông số khác 0.
- Đăng nhập `admin@gmail.com` -> Load Admin Dashboard thấy doanh thu toàn hệ thống.
- Cố ý dùng token CUSTOMER gọi `GET /api/host/dashboard` -> Chắc chắn phải trả về `403`.

## 14. Appendix (Enums)
- **UserRole**: ADMIN, HOST, CUSTOMER
- **UserStatus**: ACTIVE, INACTIVE, BANNED
- **BookingStatus**: PENDING, CONFIRMED, CANCELED, COMPLETED
- **PaymentMethod**: CASH, MOMO, VNPAY, BANK_TRANSFER, CREDIT_CARD
- **PaymentStatus**: PENDING, SUCCESS, FAILED, REFUNDED
