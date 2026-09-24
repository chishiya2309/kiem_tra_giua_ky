import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiem_tra_giua_ky_nhom_9/core/utils/currency_formatter.dart';
import 'package:kiem_tra_giua_ky_nhom_9/models/models.dart';
import 'package:kiem_tra_giua_ky_nhom_9/screens/shared/receipt_dialog.dart';

void main() {
  group('Receipt Dialog Tests', () {
    testWidgets('Hiển thị đầy đủ thông tin hóa đơn bán lẻ chuẩn', (tester) async {
      final items = [
        InvoiceDetail(
          id: '1',
          invoiceId: 'hd_test_001',
          productId: 'gao_5kg',
          tenSanPham: 'Gạo 5kg',
          soLuong: 4,
          donGia: 150000.0,
        ),
      ];

      final invoice = Invoice.create(
        id: 'hd_test_001',
        ngayBan: DateTime(2026, 9, 24, 8, 30),
        nhanVien: 'Thu ngân 01',
        items: items,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptDialog(invoice: invoice),
          ),
        ),
      );

      // Kiểm tra tiêu đề và thông tin cửa hàng
      expect(find.text('CỬA HÀNG TẠP HÓA NHÓM 9'), findsOneWidget);
      expect(find.text('HÓA ĐƠN BÁN HÀNG'), findsOneWidget);
      expect(find.text('Thu ngân 01'), findsOneWidget);

      // Kiểm tra món hàng
      expect(find.text('Gạo 5kg'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Kiểm tra tạm tính, giảm giá 5%, VAT 10%
      expect(find.text(CurrencyFormatter.format(600000)), findsWidgets); // Tạm tính & thành tiền
      expect(find.text('-${CurrencyFormatter.format(30000)}'), findsOneWidget); // Giảm giá 5%
      expect(find.text('+${CurrencyFormatter.format(57000)}'), findsOneWidget); // VAT 10%
      expect(find.text(CurrencyFormatter.format(627000)), findsOneWidget); // Tổng thanh toán

      // Kiểm tra nút hành động
      expect(find.text('In HĐ'), findsOneWidget);
      expect(find.text('Xong / Đóng'), findsOneWidget);
    });
  });
}
