class AppConstants {
  // Tên các Collections trong Firestore
  static const String productsCollection = 'products';
  static const String invoicesCollection = 'invoices';
  static const String invoiceDetailsCollection = 'invoice_details';

  // Quy tắc tính toán
  static const double vatRate = 0.10; // VAT: 10%
  static const double discountRate = 0.05; // Giảm giá: 5%
  static const double discountThreshold = 500000.0; // Áp dụng cho hóa đơn > 500.000 đ
}
