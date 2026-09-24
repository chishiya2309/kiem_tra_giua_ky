import '../../models/invoice_detail_model.dart';
import '../constants/app_constants.dart';
import 'currency_formatter.dart';

class InvoiceCalculationResult {
  final double tamTinh;
  final double giamGia;
  final double vat;
  final double tongTien;
  final bool duocGiamGia;

  const InvoiceCalculationResult({
    required this.tamTinh,
    required this.giamGia,
    required this.vat,
    required this.tongTien,
    required this.duocGiamGia,
  });

  String get formattedTamTinh => CurrencyFormatter.format(tamTinh);
  String get formattedGiamGia => CurrencyFormatter.format(giamGia);
  String get formattedVAT => CurrencyFormatter.format(vat);
  String get formattedTongTien => CurrencyFormatter.format(tongTien);
}

class InvoiceCalculator {
  /// Tính toán Tạm tính, Giảm giá (5% khi > 500.000 đ), VAT (10%), và Tổng tiền
  static InvoiceCalculationResult calculate({
    required List<InvoiceDetail> items,
    double vatRate = AppConstants.vatRate,
    double discountRate = AppConstants.discountRate,
    double discountThreshold = AppConstants.discountThreshold,
  }) {
    // 1. Tính tổng tạm tính từ các món hàng
    double tamTinh = 0.0;
    for (final item in items) {
      tamTinh += item.thanhTien;
    }

    // 2. Kiểm tra điều kiện giảm giá (> 500.000 đ)
    final bool duocGiamGia = tamTinh > discountThreshold;
    final double giamGia = duocGiamGia ? (tamTinh * discountRate) : 0.0;

    // 3. Tính tiền chịu thuế sau khi đã giảm giá
    final double tienSauGiam = tamTinh - giamGia;

    // 4. Tính thuế VAT 10% trên số tiền sau giảm giá
    final double vat = tienSauGiam * vatRate;

    // 5. Tổng tiền thanh toán cuối cùng
    final double tongTien = tienSauGiam + vat;

    return InvoiceCalculationResult(
      tamTinh: tamTinh,
      giamGia: giamGia,
      vat: vat,
      tongTien: tongTien,
      duocGiamGia: duocGiamGia,
    );
  }
}
