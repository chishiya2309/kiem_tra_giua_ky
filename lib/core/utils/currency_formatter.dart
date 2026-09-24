import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Định dạng số tiền sang chuẩn hiển thị Việt Nam. Ví dụ: 28000 -> 28.000 đ
  static String format(num amount) {
    return _formatter.format(amount).trim();
  }

  /// Parse chuỗi tiền ngược lại double nếu cần
  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
