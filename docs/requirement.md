# Yêu cầu Hệ thống Quản lý Thư viện Phân tán

**Tên dự án:** Hệ thống Quản lý cho Chuỗi Thư viện
**Phiên bản:** 1.0
**Ngày:** 13/07/2025

## 1. Giới thiệu

Tài liệu này mô tả các yêu cầu cho ứng dụng "Hệ thống Quản lý Thư viện Phân tán". Mục tiêu của dự án là xây dựng một hệ thống mô phỏng hoạt động của một hệ thống thư viện có nhiều chi nhánh (ví dụ: Thư viện Quận 1, Thư viện Quận 3), qua đó áp dụng các kiến thức cốt lõi của môn học Cơ sở dữ liệu Phân tán.

Hệ thống sẽ được triển khai trên môi trường giả lập gồm ít nhất 2 site (chi nhánh), ví dụ: `Site_TV_Q1` và `Site_TV_Q3`.

## 2. Các khái niệm CSDL Phân tán cần áp dụng

Đây là các yêu cầu phi chức năng (non-functional requirements) trọng tâm, thể hiện được kiến thức đã học.

* **Phân mảnh dữ liệu (Data Fragmentation):** Hệ thống phải triển khai phân mảnh ngang.
  * **Tham khảo:** `Sách giáo trình - Chương 2, trang 40`, `Slide - Bài 2, slide 12-14`.
* **Nhân bản dữ liệu (Data Replication):** Hệ thống phải triển khai nhân bản toàn bộ cho các dữ liệu dùng chung.
  * **Tham khảo:** `Sách giáo trình - Chương 7`, `Slide - Bài 6`.
* **Xử lý truy vấn phân tán (Distributed Query Processing):** Ứng dụng phải có khả năng thực thi các truy vấn trên nhiều site và tổng hợp kết quả.
  * **Tham khảo:** `Sách giáo trình - Chương 4`, `Slide - Bài 4`.
* **Kiểm soát truy cập (Access Control):** Hệ thống phải có cơ chế phân quyền dựa trên vai trò người dùng.
  * **Tham khảo:** `Sách giáo trình - Chương 3, trang 117-124`.
* **Mô phỏng Giao dịch Phân tán (Distributed Transaction Simulation):** Báo cáo cuối kỳ phải mô tả chi tiết cách một giao dịch phức tạp (ví dụ: chuyển một quyển sách từ chi nhánh này sang chi nhánh khác) được xử lý bằng giao thức 2PC.
  * **Tham khảo:** `Sách giáo trình - Chương 8, trang 306-311`, `Slide - Bài 5`.
* **Tính trong suốt (Transparency):** Người dùng cuối (đặc biệt là vai trò Quản lý) tương tác với hệ thống như một CSDL đơn nhất mà không cần biết dữ liệu được lưu trữ ở đâu.

## 3. Lược đồ CSDL và Chiến lược Phân tán

### 3.1. Bảng `CHINHANH`

* **Mô tả:** Lưu thông tin về các chi nhánh thư viện.
* **Chiến lược:** **NHÂN BẢN TOÀN BỘ (Fully Replicated)** trên tất cả các site.
* **Cấu trúc:**

| Tên cột | Kiểu dữ liệu | Khóa | Mô tả |
| :--- | :--- | :--- | :--- |
| `MaCN` | `VARCHAR(10)`| PK | Mã chi nhánh (ví dụ: 'Q1', 'Q3') |
| `TenCN`| `NVARCHAR(255)`| | Tên chi nhánh (ví dụ: 'Thư viện Quận 1')|
| `DiaChi`| `NVARCHAR(255)`| | Địa chỉ chi nhánh |

### 3.2. Bảng `SACH` (Đầu sách)

* **Mô tả:** Lưu thông tin chung về các đầu sách (không phải quyển sách vật lý).
* **Chiến lược:** **NHÂN BẢN TOÀN BỘ (Fully Replicated)** trên tất cả các site để độc giả ở bất kỳ đâu cũng có thể tìm kiếm thông tin sách.
* **Cấu trúc:**

| Tên cột | Kiểu dữ liệu | Khóa | Mô tả |
| :--- | :--- | :--- | :--- |
| `ISBN` | `VARCHAR(20)`| PK | Mã định danh sách quốc tế |
| `TenSach`| `NVARCHAR(255)`| | Tên đầu sách |
| `TacGia`| `NVARCHAR(255)`| | Tác giả |

### 3.3. Bảng `QUYENSACH` (Quyển sách cụ thể)

* **Mô tả:** Đại diện cho một quyển sách vật lý cụ thể tại một chi nhánh.
* **Chiến lược:** **PHÂN MẢNH NGANG (Horizontal Fragmentation)** dựa trên `MaCN`. Quyển sách thuộc chi nhánh nào sẽ được lưu tại site của chi nhánh đó.
* **Cấu trúc:**

| Tên cột | Kiểu dữ liệu | Khóa | Mô tả |
| :--- | :--- | :--- | :--- |
| `MaQuyenSach`| `VARCHAR(20)`| PK | Mã định danh duy nhất cho quyển sách |
| `ISBN` | `VARCHAR(20)`| FK | Tham chiếu đến đầu sách tương ứng |
| `MaCN` | `VARCHAR(10)` | FK | **Khóa phân mảnh**, chỉ đến chi nhánh sở hữu|
| `TinhTrang` | `NVARCHAR(50)`| | 'Có sẵn', 'Đang được mượn' |

### 3.4. Bảng `DOCGIA`

* **Mô tả:** Lưu thông tin độc giả.
* **Chiến lược:** **PHÂN MẢNH NGANG** dựa trên `MaCN_DangKy` (chi nhánh mà độc giả đăng ký thẻ).
* **Cấu trúc:**

| Tên cột | Kiểu dữ liệu | Khóa | Mô tả |
| :--- | :--- | :--- | :--- |
| `MaDG` | `VARCHAR(10)` | PK | Mã độc giả |
| `HoTen`| `NVARCHAR(255)` | | Họ và tên độc giả |
| `MaCN_DangKy`| `VARCHAR(10)` | FK | **Khóa phân mảnh**, chi nhánh đăng ký |

### 3.5. Bảng `PHIEUMUON`

* **Mô tả:** Lưu thông tin các lượt mượn sách.
* **Chiến lược:** **PHÂN MẢNH NGANG** dựa trên `MaCN` (nơi thực hiện mượn).
* **Cấu trúc:**

| Tên cột | Kiểu dữ liệu | Khóa | Mô tả |
| :--- | :--- | :--- | :--- |
| `MaPM` | `INT` | PK | Mã phiếu mượn (tự tăng) |
| `MaDG` | `VARCHAR(10)` | FK | Mã độc giả mượn sách |
| `MaQuyenSach` | `VARCHAR(20)` | FK | Mã quyển sách được mượn |
| `MaCN` | `VARCHAR(10)` | FK | **Khóa phân mảnh**, chi nhánh cho mượn |
| `NgayMuon` | `DATETIME` | | Ngày giờ mượn |
| `NgayTra` | `DATETIME` | | Ngày giờ trả (NULL nếu chưa trả) |

## 4. Vai trò người dùng (User Roles)

1. **Thủ thư (THUTHU):**
    * Chỉ có thể đăng nhập và làm việc tại chi nhánh của mình.
    * Có quyền tạo phiếu mượn, ghi nhận trả sách cho độc giả tại chi nhánh.
    * Chỉ có thể tra cứu thông tin độc giả, sách, và phiếu mượn thuộc chi nhánh của mình.
2. **Quản lý (QUANLY):**
    * Có thể đăng nhập từ bất kỳ đâu.
    * Có quyền xem thống kê mượn/trả trên toàn bộ hệ thống.
    * Có quyền tra cứu thông tin một quyển sách hoặc một độc giả trên toàn bộ hệ thống.

## 5. Yêu cầu chức năng (Functional Requirements)

### 5.1. Chức năng cho Thủ thư

* **FR1: Đăng nhập:** Thủ thư đăng nhập bằng tài khoản được cấp.
* **FR2: Lập phiếu mượn sách:**
  * Thủ thư tìm độc giả (bằng `MaDG`) và quyển sách (bằng `MaQuyenSach`).
  * Hệ thống kiểm tra tình trạng quyển sách phải là "Có sẵn".
  * Tạo một bản ghi mới trong bảng `PHIEUMUON` tại site của chi nhánh.
  * Cập nhật `TinhTrang` của quyển sách trong bảng `QUYENSACH` thành "Đang được mượn".
* **FR3: Ghi nhận trả sách:**
  * Thủ thư tìm phiếu mượn hoặc mã quyển sách.
  * Cập nhật `NgayTra` trong bảng `PHIEUMUON`.
  * Cập nhật `TinhTrang` của quyển sách trong bảng `QUYENSACH` thành "Có sẵn".
* **FR4: Tra cứu cục bộ:** Thủ thư có thể tìm kiếm sách, độc giả, phiếu mượn trong phạm vi chi nhánh của mình.

### 5.2. Chức năng cho Quản lý

* **FR5: Đăng nhập:** Quản lý đăng nhập bằng tài khoản của mình.
* **FR6: Thống kê toàn hệ thống (Truy vấn phân tán):**
  * Quản lý có thể xem tổng số sách đang được mượn trên toàn bộ hệ thống.
  * Hệ thống sẽ gửi truy vấn đến **tất cả các site**, đếm số phiếu mượn chưa trả (`NgayTra` IS NULL), sau đó tổng hợp kết quả và hiển thị.
* **FR7: Tìm kiếm sách toàn hệ thống (Truy vấn phân tán):**
  * Quản lý (hoặc độc giả) tìm một đầu sách theo tên (ví dụ: 'Lược sử loài người').
  * Hệ thống truy vấn bảng `SACH` (nhân bản) để lấy ISBN.
  * Sau đó, hệ thống gửi truy vấn đến **tất cả các site** để tìm trong bảng `QUYENSACH` xem chi nhánh nào còn quyển sách đó với tình trạng "Có sẵn" và hiển thị cho người dùng.
