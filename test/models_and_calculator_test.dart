import 'package:flutter_test/flutter_test.dart';
import 'package:kiem_tra_giua_ky_nhom_9/core/utils/currency_formatter.dart';
import 'package:kiem_tra_giua_ky_nhom_9/core/utils/invoice_calculator.dart';
import 'package:kiem_tra_giua_ky_nhom_9/models/models.dart';

void main() {
  group('1. Product Model Tests', () {
    test('Khởi tạo Product và kiểm tra format tiền tệ', () {
      const product = Product(
        id: 'sp_1',
        tenSanPham: 'Sữa tươi 1L',
        donGia: 28000.0,
        soLuongTon: 50,
      );

      expect(product.id, 'sp_1');
      expect(product.tenSanPham, 'Sữa tươi 1L');
      expect(product.donGia, 28000.0);
      expect(product.soLuongTon, 50);
      expect(product.formattedDonGia, contains('28.000'));
      expect(product.isAvailable(10), isTrue);
      expect(product.isAvailable(51), isFalse);
    });

    test('Product toMap và fromMap bảo toàn dữ liệu', () {
      const product = Product(
        id: 'sp_2',
        tenSanPham: 'Gạo 5kg',
        donGia: 150000.0,
        soLuongTon: 30,
      );

      final map = product.toMap();
      final fromMap = Product.fromMap(map, id: 'sp_2');

      expect(fromMap.id, product.id);
      expect(fromMap.tenSanPham, product.tenSanPham);
      expect(fromMap.donGia, product.donGia);
      expect(fromMap.soLuongTon, product.soLuongTon);
    });
  });

  group('2. InvoiceDetail Model Tests', () {
    test('Tự động tính thanhTien = soLuong * donGia', () {
      final detail = InvoiceDetail(
        id: 'ct_1',
        invoiceId: 'hd_1',
        productId: 'sua_tuoi_1l',
        tenSanPham: 'Sữa tươi 1L',
        soLuong: 3,
        donGia: 28000.0,
      );

      expect(detail.thanhTien, 84000.0);
      expect(detail.formattedThanhTien, contains('84.000'));
    });
  });

  group('3. InvoiceCalculator Logic Tests', () {
    test('Hóa đơn nhỏ hơn 500.000 đ: Không giảm giá, tính 10% VAT', () {
      // 2 Sữa tươi 1L (2 * 28.000 = 56.000)
      // 1 Bánh mì (1 * 12.000 = 12.000)
      // Tổng tạm tính = 68.000 đ <= 500.000 đ
      final items = [
        InvoiceDetail(
          id: '1',
          invoiceId: 'hd_test',
          productId: 'sua_tuoi',
          tenSanPham: 'Sữa tươi 1L',
          soLuong: 2,
          donGia: 28000.0,
        ),
        InvoiceDetail(
          id: '2',
          invoiceId: 'hd_test',
          productId: 'banh_mi',
          tenSanPham: 'Bánh mì',
          soLuong: 1,
          donGia: 12000.0,
        ),
      ];

      final result = InvoiceCalculator.calculate(items: items);

      expect(result.tamTinh, 68000.0);
      expect(result.duocGiamGia, isFalse);
      expect(result.giamGia, 0.0);
      // VAT 10% của 68.000 đ = 6.800 đ
      expect(result.vat, 6800.0);
      // Tổng tiền = 68.000 + 6.800 = 74.800 đ
      expect(result.tongTien, 74800.0);
    });

    test('Hóa đơn lớn hơn 500.000 đ: Giảm 5%, VAT 10% trên tiền sau giảm', () {
      // 4 bao Gạo 5kg (4 * 150.000 = 600.000 đ) > 500.000 đ
      final items = [
        InvoiceDetail(
          id: '1',
          invoiceId: 'hd_test_2',
          productId: 'gao_5kg',
          tenSanPham: 'Gạo 5kg',
          soLuong: 4,
          donGia: 150000.0,
        ),
      ];

      final result = InvoiceCalculator.calculate(items: items);

      expect(result.tamTinh, 600000.0);
      expect(result.duocGiamGia, isTrue);
      // Giảm 5% của 600.000 đ = 30.000 đ
      expect(result.giamGia, 30000.0);
      // Tiền sau giảm = 570.000 đ
      // VAT 10% của 570.000 đ = 57.000 đ
      expect(result.vat, 57000.0);
      // Tổng tiền = 570.000 + 57.000 = 627.000 đ
      expect(result.tongTien, 627000.0);
    });
  });

  group('4. Invoice Model Tests', () {
    test('Invoice.create tự động tính toán chính xác và serialize', () {
      final items = [
        InvoiceDetail(
          id: '1',
          invoiceId: 'hd_01',
          productId: 'gao_5kg',
          tenSanPham: 'Gạo 5kg',
          soLuong: 4,
          donGia: 150000.0,
        ),
      ];

      final invoice = Invoice.create(
        id: 'hd_01',
        ngayBan: DateTime(2026, 9, 24, 10, 30),
        nhanVien: 'NguyenVanA',
        items: items,
      );

      expect(invoice.tamTinh, 600000.0);
      expect(invoice.giamGia, 30000.0);
      expect(invoice.vat, 57000.0);
      expect(invoice.tongTien, 627000.0);
      expect(invoice.nhanVien, 'NguyenVanA');
      expect(invoice.danhSachChiTiet.length, 1);

      final map = invoice.toMap();
      final fromMap = Invoice.fromMap(map, id: 'hd_01');

      expect(fromMap.id, invoice.id);
      expect(fromMap.tongTien, invoice.tongTien);
      expect(fromMap.vat, invoice.vat);
      expect(fromMap.giamGia, invoice.giamGia);
      expect(fromMap.danhSachChiTiet.length, 1);
      expect(fromMap.danhSachChiTiet.first.tenSanPham, 'Gạo 5kg');
    });
  });

  group('5. Currency Formatter Tests', () {
    test('Format định dạng VND', () {
      expect(CurrencyFormatter.format(28000), contains('28.000'));
      expect(CurrencyFormatter.format(150000), contains('150.000'));
      expect(CurrencyFormatter.parse('28.000 đ'), 28000.0);
    });
  });
}
