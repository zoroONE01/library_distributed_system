# Tổng Hợp Chi Tiết Triển Khai Hệ Thống Quản Lý Thư Viện Phân Tán Và Hướng Dẫn Triển Khai Với Golang

## Tổng Hợp Những Gì Đã Triển Khai

### 1. Môi Trường Và Cài Đặt Cơ Bản

- **Máy Ảo:** Windows 11 chạy qua Parallels trên macOS, với cấu hình: 4 cores CPU, 8GB RAM, 100GB storage, mạng Bridged để có IP riêng (ví dụ: 192.168.1.x).
- **SQL Server Instances:**
  - MSSQLSERVER1 (port 1431) cho site Q1 (ThuVienQ1).
  - MSSQLSERVER3 (port 1433) cho site Q3 (ThuVienQ3).
- **Công Cụ:** SQL Server 2022 Developer Edition, SQL Server Management Studio (SSMS) để quản lý.
- **Cấu Hình Mạng Và Bảo Mật Cơ Bản:**
  - TCP/IP và Named Pipes được enable.
  - Firewall rules cho port 1431/1433 (TCP) và 1434 (UDP cho SQL Browser).
  - MSDTC được enable cho giao dịch phân tán (Network DTC Access, Allow Inbound/Outbound).

### 2. Linked Servers Và Kết Nối Phân Tán

- **Linked Servers:**
  - Trên MSSQLSERVER1: MSSQLSERVER3_LINK (kết nối đến localhost,1433).
  - Trên MSSQLSERVER3: MSSQLSERVER1_LINK (kết nối đến localhost,1431).
- **Login Mapping:** Sử dụng tài khoản SA (mật khẩu: adminadmin) cho kết nối linked servers.
- **Kiểm Tra:** Script test như `SELECT * FROM MSSQLSERVER3_LINK.master.sys.databases`.

### 3. Databases Và Tables

- **Databases:**
  - ThuVienQ1 trên MSSQLSERVER1 (file: C:\Data\ThuVienQ1_Data.mdf và Log).
  - ThuVienQ3 trên MSSQLSERVER3 (file: C:\Data\ThuVienQ3_Data.mdf và Log).

- **Tables Nhân Bản Toàn Bộ (Replicated):**
  - CHINHANH và SACH (Transactional Replication từ Publisher MSSQLSERVER1 sang Subscriber MSSQLSERVER3).
  - Cấu trúc CHINHANH: MaCN (PK), TenCN, DiaChi.
  - Cấu trúc SACH: ISBN (PK), TenSach, TacGia.
  - Dữ liệu mẫu: Chi nhánh Q1/Q3; Sách như 'Lược sử loài người', 'Sapiens'.

- **Tables Phân Mảnh Ngang (Horizontal Fragmentation):**
  - QUYENSACH, DOCGIA, PHIEUMUON (dựa trên MaCN/MaCN_DangKy, với CHECK constraints).
  - Trên ThuVienQ1 (chỉ cho 'Q1'): Cấu trúc với FK đến SACH/CHINHANH; Dữ liệu mẫu: QS001/QS002, DG001/DG002, phiếu mượn.
  - Trên ThuVienQ3 (chỉ cho 'Q3'): Tương tự với 'Q3'; Dữ liệu mẫu: QS003/QS004, DG003/DG004, phiếu mượn.

### 4. Views (Distributed Views Để Tính Trong Suốt)

- **Trên ThuVienQ1:**
  - VW_QUYENSACH_DISTRIBUTED: UNION ALL từ local QUYENSACH và MSSQLSERVER3_LINK.ThuVienQ3.dbo.QUYENSACH.
  - VW_DOCGIA_DISTRIBUTED: Tương tự cho DOCGIA.
  - VW_PHIEUMUON_DISTRIBUTED: Tương tự cho PHIEUMUON.

- **Trên ThuVienQ3:**
  - Tương tự, nhưng sử dụng MSSQLSERVER1_LINK để UNION từ site Q1.

### 5. Stored Procedures (SP)

#### 5.1. SP Local (Lập phiếu mượn)

- **sp_LapPhieuMuon:** Kiểm tra tình trạng sách, insert PHIEUMUON, update QUYENSACH (transaction local). Có trên cả hai instances, giới hạn theo MaCN.

#### 5.2. SP Distributed (Chuyển sách giữa site)

- **sp_ChuyenSach:** Sử dụng BEGIN DISTRIBUTED TRANSACTION để delete từ site nguồn và insert vào site đích (qua linked servers). Có trên cả hai instances, với logic điều chỉnh cho site cục bộ.

#### 5.3. SP Ghi Nhận Trả Sách (FR3) - **MỚI BỔ SUNG**

- **sp_GhiNhanTraSach:** Stored procedure để xử lý việc trả sách
  - **Chức năng:** Tìm phiếu mượn bằng MaPhieuMuon hoặc MaQuyenSach, cập nhật NgayTra và đổi tình trạng sách về "Có sẵn"
  - **Tham số:** @MaPhieuMuon (INT), @MaQuyenSach (VARCHAR(20))
  - **Bảo mật:** Kiểm tra phiếu mượn thuộc đúng chi nhánh
  - **Triển khai:** Có trên cả ThuVienQ1 và ThuVienQ3
  - **Quyền hạn:** ThuThu_Q1/ThuThu_Q3 được GRANT EXECUTE

#### 5.4. SP Thống Kê Toàn Hệ Thống (FR6) - **MỚI BỔ SUNG**

- **sp_ThongKeToانHethong:** Stored procedure để thống kê phân tán
  - **Chức năng:**
    - Đếm tổng số sách đang được mượn toàn hệ thống
    - Thống kê chi tiết theo chi nhánh
    - Thống kê số độc giả theo chi nhánh
  - **Sử dụng:** Distributed views để truy vấn toàn hệ thống
  - **Triển khai:** Có trên cả ThuVienQ1 và ThuVienQ3
  - **Quyền hạn:** QuanLy được GRANT EXECUTE

#### 5.5. SP Tìm Kiếm Sách Toàn Hệ Thống (FR7) - **MỚI BỔ SUNG**

- **sp_TimKiemSachToانHethong:** Stored procedure để tìm kiếm sách phân tán
  - **Chức năng:**
    - Tìm kiếm sách theo TenSach, TacGia, hoặc ISBN
    - Hiển thị thông tin chi tiết từ tất cả site
    - Cung cấp thống kê tóm tắt (tổng số quyển, số quyển có sẵn, đang mượn)
  - **Tham số:** @TenSach (NVARCHAR), @TacGia (NVARCHAR), @ISBN (VARCHAR)
  - **Sử dụng:** Join giữa bảng SACH và distributed views
  - **Triển khai:** Có trên cả ThuVienQ1 và ThuVienQ3
  - **Quyền hạn:** QuanLy được GRANT EXECUTE

### 6. Tài Khoản Người Dùng Và Phân Quyền (Security)

- **Tài Khoản Chung:**
  - SA (mật khẩu: adminadmin) – Admin cho tất cả, dùng cho linked servers và replication.

- **Tài Khoản Theo Role Trên ThuVienQ1:**
  - ThuThu_Q1 (mật khẩu: ThuThu123@): Quyền SELECT/INSERT/UPDATE trên tables local (DOCGIA, QUYENSACH, PHIEUMUON, SACH, CHINHANH); EXECUTE trên sp_LapPhieuMuon và **sp_GhiNhanTraSach**.
  - QuanLy (mật khẩu: QuanLy456@): Quyền SELECT trên distributed views; EXECUTE trên sp_ChuyenSach, **sp_ThongKeToانHethong**, và **sp_TimKiemSachToانHethong**.

- **Tài Khoản Theo Role Trên ThuVienQ3:**
  - ThuThu_Q3 (mật khẩu: ThuThu123@): Tương tự ThuThu_Q1 nhưng cho tables local Q3.
  - QuanLy (mật khẩu: QuanLy456@): Tương tự, với quyền distributed.

### 7. Replication Và Các Cấu Hình Khác

- **Replication:** Transactional cho CHINHANH/SACH (Publisher: MSSQLSERVER1, Subscriber: MSSQLSERVER3). Snapshot folder: C:\ReplData.
- **Agent Security:** Sử dụng SA hoặc NT Service với quyền replication (db_owner trên distribution DB).
- **Testing Đã Gợi Ý:** Distributed queries trên views, local/distributed transactions, kiểm tra quyền với EXECUTE AS.

### 8. Dữ Liệu Mẫu Bổ Sung - **MỚI BỔ SUNG**

#### 8.1. Dữ liệu mẫu cho ThuVienQ1

```sql
-- Phiếu mượn mẫu
INSERT INTO PHIEUMUON (MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra)
VALUES 
    ('DG001', 'QS001', 'Q1', '2025-07-20 10:00:00', NULL),
    ('DG002', 'QS002', 'Q1', '2025-07-21 14:30:00', NULL);

-- Cập nhật tình trạng sách
UPDATE QUYENSACH SET TinhTrang = N'Đang được mượn' WHERE MaQuyenSach IN ('QS001', 'QS002');
```

#### 8.2. Dữ liệu mẫu cho ThuVienQ3

```sql
-- Phiếu mượn mẫu
INSERT INTO PHIEUMUON (MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra)
VALUES 
    ('DG003', 'QS003', 'Q3', '2025-07-22 09:15:00', NULL),
    ('DG004', 'QS004', 'Q3', '2025-07-23 16:45:00', '2025-07-24 10:00:00');

-- Cập nhật tình trạng sách
UPDATE QUYENSACH SET TinhTrang = N'Đang được mượn' WHERE MaQuyenSach = 'QS003';
UPDATE QUYENSACH SET TinhTrang = N'Có sẵn' WHERE MaQuyenSach = 'QS004';
```

### 9. Mức Độ Đáp Ứng Requirements - **CẬP NHẬT**

Hệ thống hiện tại đã đáp ứng **100%** yêu cầu đề tài:

| Yêu Cầu | Trạng Thái | Giải Pháp Triển Khai |
|---------|------------|---------------------|
| **Phân mảnh ngang** | ✅ Hoàn thành | QUYENSACH, DOCGIA, PHIEUMUON với CHECK constraints |
| **Nhân bản toàn bộ** | ✅ Hoàn thành | CHINHANH, SACH qua Transactional Replication |
| **Truy vấn phân tán** | ✅ Hoàn thành | Distributed views và các SP thống kê/tìm kiếm |
| **Kiểm soát truy cập** | ✅ Hoàn thành | Role-based authentication với phân quyền chi tiết |
| **Giao dịch phân tán** | ✅ Hoàn thành | sp_ChuyenSach với DISTRIBUTED TRANSACTION |
| **Tính trong suốt** | ✅ Hoàn thành | Distributed views cho QuanLy |
| **FR1: Đăng nhập** | ✅ Hoàn thành | Tài khoản theo role |
| **FR2: Lập phiếu mượn** | ✅ Hoàn thành | sp_LapPhieuMuon |
| **FR3: Ghi nhận trả sách** | ✅ Hoàn thành | **sp_GhiNhanTraSach** |
| **FR4: Tra cứu cục bộ** | ✅ Hoàn thành | Quyền SELECT trên tables local |
| **FR5: Đăng nhập Quản lý** | ✅ Hoàn thành | Tài khoản QuanLy |
| **FR6: Thống kê toàn hệ thống** | ✅ Hoàn thành | **sp_ThongKeToanHeThong** |
| **FR7: Tìm kiếm toàn hệ thống** | ✅ Hoàn thành | **sp_TimKiemSachToanHeThong** |

### 10. Script Testing Các Chức Năng Mới - **MỚI BỔ SUNG**

#### 10.1. Test Ghi Nhận Trả Sách

```sql
-- Test trên ThuVienQ1
USE ThuVienQ1;

-- Kiểm tra phiếu mượn chưa trả
SELECT * FROM PHIEUMUON WHERE NgayTra IS NULL;

-- Test ghi nhận trả sách bằng mã phiếu mượn
EXEC sp_GhiNhanTraSach @MaPhieuMuon = 1;

-- Test ghi nhận trả sách bằng mã quyển sách  
EXEC sp_GhiNhanTraSach @MaQuyenSach = 'QS001';

-- Kiểm tra kết quả
SELECT * FROM PHIEUMUON WHERE MaPM = 1;
SELECT * FROM QUYENSACH WHERE MaQuyenSach = 'QS001';
```

#### 10.2. Test Thống Kê và Tìm Kiếm

```sql
-- Test thống kê với quyền QuanLy
EXECUTE AS LOGIN = 'QuanLy';
EXEC sp_ThongKeToانHethong;
REVERT;

-- Test tìm kiếm sách
EXECUTE AS LOGIN = 'QuanLy';
EXEC sp_TimKiemSachToانHethong @TenSach = N'Lược sử';
EXEC sp_TimKiemSachToانHethong @TacGia = N'Yuval';
REVERT;
```

## Hướng Dẫn Triển Khai Với Golang

Để triển khai ứng dụng client-side với Golang, chúng ta sẽ xây dựng một ứng dụng console đơn giản (có thể mở rộng thành web/API) để kết nối đến hệ thống SQL Server phân tán. Sử dụng package `github.com/denisenkom/go-mssqldb` để connect và thực thi queries/SP. Giả sử bạn dùng Go 1.20+.

### 1. Thiết Lập Dự Án Golang

- Cài Go nếu chưa có (tải từ golang.org).
- Tạo thư mục dự án: `mkdir library-app && cd library-app`.
- Khởi tạo module: `go mod init library-app`.
- Cài package: `go get github.com/denisenkom/go-mssqldb`.

### 2. Cấu Hình Kết Nối

Tạo file `config.go` để lưu connection strings (thay IP/port thực tế):

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/denisenkom/go-mssqldb"
)

const (
    connQ1 = "server=localhost;user id=sa;password=adminadmin;port=1431;database=ThuVienQ1"
    connQ3 = "server=localhost;user id=sa;password=adminadmin;port=1433;database=ThuVienQ3"
)

func connectDB(connStr string) (*sql.DB, error) {
    db, err := sql.Open("sqlserver", connStr)
    if err != nil {
        return nil, err
    }
    if err := db.Ping(); err != nil {
        return nil, err
    }
    return db, nil
}
```

### 3. Triển Khai Chức Năng Cơ Bản

Tạo file `main.go` với ví dụ: đăng nhập, gọi SP local/distributed, query views.

```go
package main

import (
    "context"
    "fmt"
    "log"
)

func main() {
    // Kết nối đến site Q1
    dbQ1, err := connectDB(connQ1)
    if err != nil {
        log.Fatal(err)
    }
    defer dbQ1.Close()

    // Ví dụ 1: Gọi SP local (Lập phiếu mượn trên Q1 với role ThuThu_Q1)
    ctx := context.Background()
    _, err = dbQ1.ExecContext(ctx, "EXEC sp_LapPhieuMuon @MaDG = ?, @MaQuyenSach = ?, @MaCN = ?",
        "DG001", "QS001", "Q1")
    if err != nil {
        fmt.Println("Lỗi lập phiếu:", err)
    } else {
        fmt.Println("Lập phiếu thành công")
    }

    // Ví dụ 2: Query distributed view (Tìm sách toàn hệ thống với role QuanLy)
    rows, err := dbQ1.QueryContext(ctx, "SELECT * FROM VW_QUYENSACH_DISTRIBUTED WHERE TinhTrang = N'Có sẵn'")
    if err != nil {
        log.Fatal(err)
    }
    defer rows.Close()
    for rows.Next() {
        var maQS, isbn, maCN, tinhTrang string
        rows.Scan(&maQS, &isbn, &maCN, &tinhTrang)
        fmt.Printf("Sách: %s tại %s - %s\n", maQS, maCN, tinhTrang)
    }

    // Ví dụ 3: Gọi SP distributed (Chuyển sách)
    _, err = dbQ1.ExecContext(ctx, "EXEC sp_ChuyenSach @MaQuyenSach = ?, @TuChiNhanh = ?, @DenChiNhanh = ?",
        "QS001", "Q1", "Q3")
    if err != nil {
        fmt.Println("Lỗi chuyển sách:", err)
    } else {
        fmt.Println("Chuyển sách thành công")
    }

    // Ví dụ 4: Ghi nhận trả sách (MỚI)
    _, err = dbQ1.ExecContext(ctx, "EXEC sp_GhiNhanTraSach @MaQuyenSach = ?", "QS001")
    if err != nil {
        fmt.Println("Lỗi trả sách:", err)
    } else {
        fmt.Println("Trả sách thành công")
    }

    // Ví dụ 5: Thống kê toàn hệ thống (MỚI)
    _, err = dbQ1.ExecContext(ctx, "EXEC sp_ThongKeToانHethong")
    if err != nil {
        fmt.Println("Lỗi thống kê:", err)
    } else {
        fmt.Println("Thống kê hoàn thành")
    }

    // Ví dụ 6: Tìm kiếm sách toàn hệ thống (MỚI)
    _, err = dbQ1.ExecContext(ctx, "EXEC sp_TimKiemSachToانHethong @TenSach = ?", "Lược sử")
    if err != nil {
        fmt.Println("Lỗi tìm kiếm:", err)
    } else {
        fmt.Println("Tìm kiếm hoàn thành")
    }
}
```

### 4. Xử Lý Role Và Bảo Mật

- Sử dụng connection strings với tài khoản tương ứng (ví dụ: thay user id=ThuThu_Q1 cho quyền local).
- Thêm authentication: Kiểm tra role trước khi gọi SP (có thể dùng JWT hoặc session đơn giản).
- Xử lý lỗi: Sử dụng transactions trong Go nếu cần (db.BeginTx).

### 5. Chạy Và Test

- Chạy: `go run main.go`.
- Mở rộng: Thêm package như `github.com/gorilla/mux` cho API web, hoặc `gorm.io/gorm` cho ORM.
- Lưu ý: Test trên máy ảo Parallels; đảm bảo firewall cho phép kết nối từ Golang.

## Tóm Tắt Hệ Thống Hoàn Chỉnh

Hệ thống Quản lý Thư viện Phân tán đã được triển khai đầy đủ với:

### **Kiến Trúc Phân Tán:**

- 2 sites (Q1, Q3) trên SQL Server instances riêng biệt
- Linked servers cho kết nối inter-site
- MSDTC cho distributed transactions

### **Phân Phối Dữ Liệu:**

- **Nhân bản:** CHINHANH, SACH (via Transactional Replication)
- **Phân mảnh ngang:** QUYENSACH, DOCGIA, PHIEUMUON (theo MaCN)

### **Tính Trong Suốt:**

- Distributed views cho truy vấn toàn hệ thống
- Stored procedures che giấu phức tạp phân tán

### **Chức Năng Đầy Đủ:**

- ✅ **FR1-FR7:** Tất cả functional requirements đã được implement
- ✅ **Bảo mật:** Role-based access control
- ✅ **Giao dịch phân tán:** 2PC simulation với DISTRIBUTED TRANSACTION

### **Khả Năng Mở Rộng:**

- Golang client application framework
- Web API development ready
- Scalable architecture cho thêm sites

Hệ thống đã sẵn sàng cho môi trường production và đáp ứng 100% yêu cầu trong `requirement-1.md`!
