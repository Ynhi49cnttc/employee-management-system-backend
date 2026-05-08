# Employee Management System - Backend

Dự án Backend cho hệ thống Quản lý Nhân viên, được xây dựng trên nền tảng Node.js và SQL Server, tập trung vào tính bảo mật cao, phân quyền chặt chẽ và ghi nhật ký hệ thống tự động.

## Tính năng nổi bật

* **Xác thực & Phân quyền (RBAC):** Sử dụng JSON Web Token (JWT) để quản lý phiên đăng nhập và phân quyền đa cấp (Admin, HR Manager, HR Staff, Finance, Manager, Employee).
* **Bảo mật dữ liệu (TDE):** Triển khai Transparent Data Encryption (TDE) trên SQL Server để mã hóa toàn bộ cơ sở dữ liệu ở trạng thái nghỉ.
* **Truy vết hệ thống (Audit Logging):** Hệ thống tự động ghi lại mọi thay đổi dữ liệu (Insert, Update, Delete) thông qua SQL Triggers.
* **Quản lý ngữ cảnh phiên:** Sử dụng `SESSION_CONTEXT` trong SQL Server để truyền định danh người dùng từ Backend xuống Database, giúp ghi nhật ký chính xác đối tượng thực hiện thao tác.
* **Bảo mật Stored Procedures:** Toàn bộ logic nghiệp vụ được đóng gói trong Stored Procedures; chặn quyền truy cập trực tiếp vào các bảng nhạy cảm đối với người dùng thông thường.

## 🛠 Công nghệ sử dụng

* **Runtime:** Node.js
* **Framework:** Express.js
* **Database:** Microsoft SQL Server (MSSQL)
* **Thư viện kết nối:** `mssql` (với Connection Pool tối ưu hiệu suất)
* **Bảo mật:** `jsonwebtoken`, `bcryptjs`, `dotenv`, `cors`
* **Kiểm tra dữ liệu:** `joi`

## 📋 Cấu trúc thư mục

```text
src/
├── config/             # Cấu hình kết nối Database
├── controllers/        # Xử lý logic nghiệp vụ API
├── middlewares/        # Các hàm chặn (Auth, Check Role)
├── routes/             # Định nghĩa các đầu cuối API
├── app.js              # Cấu hình Express & Middleware
└── server.js           # Điểm khởi chạy ứng dụng
sql/                    # Các kịch bản khởi tạo và phân quyền Database

```

## 🚀 Cài đặt & Chạy thử

### 1. Chuẩn bị Cơ sở dữ liệu

1. Mở SQL Server Management Studio (SSMS).
2. Chạy lần lượt các file trong thư mục `sql/`:
* `init.sql`: Khởi tạo Database, bảng và cấu hình TDE.
* `rbac_employee_procs.sql`: Tạo các Stored Procedures và phân quyền Role.
* `seed.sql`: Nạp dữ liệu mẫu và tài khoản Admin khởi tạo.



### 2. Cấu hình Backend

Tạo file `.env` tại thư mục gốc và nhập các thông tin sau:

```env
PORT=5000
DB_USER=test_login
DB_PASSWORD=Test@123456
DB_SERVER=localhost
DB_NAME=QL_NHANVIEN
JWT_SECRET=YourSuperSecretKey

```

### 3. Khởi chạy

```bash
# Cài đặt thư viện
npm install

# Chạy chế độ phát triển (với nodemon)
npm run dev

```

## 📡 Danh sách API chính

| Phương thức | Endpoint | Mô tả | Quyền truy cập |
| --- | --- | --- | --- |
| `POST` | `/api/auth/login` | Đăng nhập hệ thống | Public |
| `GET` | `/api/employee/profile` | Xem thông tin cá nhân | Đã đăng nhập |
| `GET` | `/api/hr/all` | Xem danh sách nhân viên | HR Manager |
| `POST` | `/api/hr/add` | Thêm nhân viên mới | HR Manager |
| `GET` | `/api/hr/logs` | Xem nhật ký hệ thống | HR Manager |
| `GET` | `/api/admin/accounts` | Quản lý danh sách tài khoản | Admin |
| `PUT` | `/api/admin/accounts/status` | Khóa/Mở tài khoản | Admin |

---

*Dự án được phát triển phục vụ mục đích học tập và nghiên cứu môn bảo mật cơ sở dữ liệu.*