# Hệ Thống Quản Lý Cửa Hàng Tạp Hóa - Nhóm 9

Dự án kiểm tra giữa kỳ môn **Lập trình di động nâng cao**. Hệ thống quản lý sản phẩm, tồn kho, tạo hóa đơn bán hàng và tính tổng tiền theo từng giao dịch cho cửa hàng tạp hóa, tích hợp Cloud Firestore qua Firebase CLI.

---

## 1. Cấu Trúc Dự Án (Clean Architecture)

Mã nguồn được tổ chức thành các tầng module độc lập, giúp các thành viên nhóm dễ dàng phân chia công việc:

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # Tỷ lệ VAT (10%), ngưỡng giảm giá (>500k: 5%), collections
│   │   └── sample_data.dart         # 4 sản phẩm mẫu theo đề bài
│   └── utils/
│       ├── currency_formatter.dart  # Định dạng tiền tệ VND (e.g. 28.000 đ)
│       └── invoice_calculator.dart  # Logic tính tạm tính, giảm giá, VAT, tổng tiền
├── models/
│   ├── product_model.dart           # Model Sản phẩm (id, tenSanPham, donGia, soLuongTon)
│   ├── invoice_detail_model.dart    # Model Chi tiết hóa đơn (id, invoiceId, productId, soLuong, donGia, thanhTien)
│   ├── invoice_model.dart           # Model Hóa đơn (id, ngayBan, nhanVien, tongTien, vat, giamGia, ...)
│   └── models.dart                  # Barrel export
├── services/
│   ├── firebase_service.dart        # Khởi tạo và kiểm tra kết nối Firebase
│   ├── product_service.dart         # CRUD sản phẩm, Realtime stream, cập nhật tồn kho, nạp dữ liệu mẫu
│   ├── invoice_service.dart         # Tạo hóa đơn (Transaction trừ tồn kho an toàn), thống kê doanh thu
│   └── services.dart                # Barrel export
├── firebase_options.dart            # Tự động sinh từ Firebase CLI
└── main.dart                        # Hub kiểm tra kết nối, nạp mẫu và test tính toán
```

---

## 2. Quy Tắc Nghiệp Vụ & Dữ Liệu Mẫu

### Đơn giá mẫu:
- **Sữa tươi 1L**: `28.000 đ`
- **Bánh mì**: `12.000 đ`
- **Nước ngọt**: `15.000 đ`
- **Gạo 5kg**: `150.000 đ`

### Quy định tính tiền:
- **VAT**: `10%`
- **Giảm giá**: `5%` áp dụng cho hóa đơn có **Tạm tính > 500.000 đ**.
- **Công thức**:
  $$\text{Tạm tính} = \sum (\text{soLuong} \times \text{donGia})$$
  $$\text{Giảm giá} = \begin{cases} 0.05 \times \text{Tạm tính}, & \text{nếu Tạm tính} > 500.000 \text{ đ} \\ 0, & \text{ngược lại} \end{cases}$$
  $$\text{VAT} = (\text{Tạm tính} - \text{Giảm giá}) \times 10\%$$
  $$\text{Tổng tiền thanh toán} = (\text{Tạm tính} - \text{Giảm giá}) + \text{VAT}$$

---

## 3. Hướng Dẫn Chạy & Kiểm Thử

### Cài đặt dependencies:
```bash
flutter pub get
```

### Chạy Unit Test kiểm tra tính toán:
```bash
flutter test
```

### Kiểm tra cú pháp:
```bash
flutter analyze
```

### Chạy ứng dụng:
```bash
flutter run
# Hoặc chạy trên Chrome:
flutter run -d chrome
```

---

## 4. Phân Chia Công Việc Làm Menu Hệ Thống (Giai Đoạn Kế Tiếp)

Các thành viên chỉ cần tạo các màn hình trong thư mục `lib/screens/`:

1. **Quản lý sản phẩm và tồn kho**: Sử dụng [ProductService](file:///lib/services/product_service.dart) (`streamProducts()`, `addProduct()`, `updateStock()`).
2. **Thêm sản phẩm vào hóa đơn & Giỏ hàng**: Sử dụng [InvoiceDetail](file:///lib/models/invoice_detail_model.dart) và [Product](file:///lib/models/product_model.dart).
3. **Tự động tính tiền, VAT & Giảm giá**: Gọi trực tiếp [InvoiceCalculator.calculate()](file:///lib/core/utils/invoice_calculator.dart).
4. **Tạo & Xuất hóa đơn**: Gọi [InvoiceService.createInvoice()](file:///lib/services/invoice_service.dart) (Tự động trừ số lượng tồn kho qua Firestore Transaction).
5. **Thống kê doanh thu theo ngày, tháng**: Sử dụng [InvoiceService.getInvoicesByDateRange()](file:///lib/services/invoice_service.dart).
