# Secure Employee Management System - Backend

Dự án Backend cho hệ thống Quản lý Nhân viên, được xây dựng trên nền tảng Node.js và SQL Server. Hệ thống tập trung giải quyết bài toán quản lý nhân sự kết hợp với các cơ chế bảo mật cơ sở dữ liệu chuyên sâu.

## 🌟 Tính năng bảo mật & Nghiệp vụ nổi bật

* **Xác thực & Phân quyền nhiều lớp (RBAC):** Quản lý truy cập bằng JSON Web Token (JWT). Hệ thống phân định rạch ròi 5 vai trò nghiệp vụ:
  * `EMP` (Employee): Xem thông tin cá nhân và đồng nghiệp cùng phòng (ẩn lương).
  * `MAN` (Manager): Quản lý và xem lương nhân sự trong phòng ban.
  * `FIN` (Finance): Tính lương toàn công ty (chỉ xem Mã NV, Lương, Mã số thuế của phòng khác).
  * `HR` (HR Staff): Quản lý nhân sự toàn công ty (không được can thiệp người cùng phòng HR).
  * `HRM` (HR Manager): Toàn quyền quản trị nhân sự, cấp phát/khóa tài khoản, phân quyền và kiểm tra nhật ký hệ thống.
* **Mã hóa dữ liệu vật lý (TDE):** Triển khai Transparent Data Encryption trên SQL Server, bảo vệ toàn bộ file cơ sở dữ liệu khỏi nguy cơ rò rỉ phần cứng.
* **Truy vết hệ thống (Audit Logging):** Mọi thao tác Thêm/Sửa/Xóa đều được Trigger ghi lại. Tích hợp `SESSION_CONTEXT` truyền định danh từ Backend xuống CSDL để định danh chính xác người thực hiện.
* **Phòng chống SQL Injection & Truy cập trái phép:** Giao tiếp hoàn toàn qua Stored Procedures có tham số (`Parameterized Queries`). Đặt lệnh `DENY` chặn truy cập trực tiếp vào các bảng dữ liệu gốc.

## 🛠 Công nghệ sử dụng

* **Môi trường:** Node.js, Express.js
* **Cơ sở dữ liệu:** Microsoft SQL Server (MSSQL)
* **Bảo mật & Mã hóa:** `jsonwebtoken` (JWT), `bcryptjs` (Hashing), `dotenv`.
* **Kết nối DB:** `mssql` (với cơ chế Connection Pool).

## 📋 Cấu trúc thư mục

```text
sql/
└── QL_NhanVien_Init.sql    # Script khởi tạo DB, TDE, Tables, Roles, Trigger & SPs
src/
├── config/                 # Cấu hình kết nối SQL Server (db.js)
├── controllers/            # Logic xử lý API cho từng Role (hr, finance, manager...)
├── middlewares/            # Chốt chặn bảo mật (verifyToken, checkRole)
├── routes/                 # Định tuyến các Endpoint API
├── app.js                  # Khởi tạo Express và gắn kết các Router
└── server.js               # Điểm khởi chạy hệ thống
.env                        # Chứa các biến môi trường nhạy cảm

```

## 🚀 Hướng dẫn cài đặt

### 1. Khởi tạo Cơ sở dữ liệu

1. Mở SQL Server Management Studio (SSMS).
2. Mở file `sql/QL_NhanVien_Init.sql`.
3. Nhấn **Execute (F5)** để hệ thống tự động thiết lập TDE, bảng, quy tắc bảo mật và dữ liệu mẫu.

### 2. Cấu hình Backend

Tạo file `.env` tại thư mục gốc:

```env
PORT=5000
DB_USER=test_login
DB_PASSWORD=Test@123456
DB_SERVER=localhost
DB_NAME=QL_NHANVIEN
JWT_SECRET=Chuoi_Bao_Mat_JWT_Cua_Ban

```

### 3. Khởi chạy Server

```bash
npm install
npm run dev

```

## 📡 Danh sách API (Endpoints)

| Nhóm | Phương thức | Endpoint | Chức năng | Quyền yêu cầu |
| --- | --- | --- | --- | --- |
| **Auth** | `POST` | `/api/auth/login` | Đăng nhập hệ thống & nhận Token | Public |
| **Employee** | `GET` | `/api/employee/profile` | Xem hồ sơ cá nhân | Đã đăng nhập |
|  | `GET` | `/api/employee/peers` | Xem đồng nghiệp cùng phòng (ẩn lương) | Đã đăng nhập |
| **Manager** | `GET` | `/api/manager/department` | Xem toàn bộ nhân sự phòng mình | `MAN` |
| **Finance** | `GET` | `/api/finance/salary` | Xem bảng tính lương toàn công ty | `FIN` |
| **HR Staff** | `GET` | `/api/hr-staff/others` | Xem nhân sự công ty (trừ phòng HR) | `HR` |
|  | `PUT` | `/api/hr-staff/update/:MaNV` | Sửa nhân sự công ty (trừ phòng HR) | `HR` |
| **HR Manager** | `GET` | `/api/hr/all` | Xem toàn bộ nhân sự công ty | `HRM` |
|  | `POST` | `/api/hr/add` | Thêm nhân viên & Cấp tài khoản | `HRM` |
|  | `PUT` | `/api/hr/update/:MaNV` | Cập nhật thông tin bất kỳ ai | `HRM` |
|  | `DELETE` | `/api/hr/delete/:MaNV` | Xóa nhân viên & Thu hồi tài khoản | `HRM` |
|  | `GET` | `/api/hr/accounts` | Quản lý danh sách tài khoản đăng nhập | `HRM` |
|  | `PUT` | `/api/hr/accounts/status` | Khóa / Mở khóa tài khoản | `HRM` |
|  | `PUT` | `/api/hr/accounts/role` | Cấp phát / Đổi vai trò (Role) | `HRM` |
|  | `GET` | `/api/hr/logs` | Xem nhật ký hệ thống (Audit Log) | `HRM` |

## 👤 Thông tin thực hiện
* **Nhóm:** 5
* **Đơn vị:** Khoa Công nghệ thông tin - Đại học Sư phạm TP.HCM (HCMUE)

---

*Dự án phục vụ mục đích đồ án học phần: Bảo mật cơ sở dữ liệu.*
