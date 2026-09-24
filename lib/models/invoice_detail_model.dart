import '../core/utils/currency_formatter.dart';

class InvoiceDetail {
  final String id;
  final String invoiceId;
  final String productId;
  final String tenSanPham;
  final int soLuong;
  final double donGia;
  final double thanhTien;

  InvoiceDetail({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.tenSanPham,
    required this.soLuong,
    required this.donGia,
    double? thanhTien,
  }) : thanhTien = thanhTien ?? (soLuong * donGia);

  /// Chuyển đối tượng thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'tenSanPham': tenSanPham,
      'soLuong': soLuong,
      'donGia': donGia,
      'thanhTien': thanhTien,
    };
  }

  /// Tạo đối tượng InvoiceDetail từ Map
  factory InvoiceDetail.fromMap(Map<String, dynamic> map, {String? id}) {
    final soLuong = (map['soLuong'] as num?)?.toInt() ?? 0;
    final donGia = (map['donGia'] as num?)?.toDouble() ?? 0.0;
    final thanhTien = (map['thanhTien'] as num?)?.toDouble() ?? (soLuong * donGia);

    return InvoiceDetail(
      id: id ?? map['id'] ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      tenSanPham: map['tenSanPham'] as String? ?? '',
      soLuong: soLuong,
      donGia: donGia,
      thanhTien: thanhTien,
    );
  }

  /// Tạo bản sao với các thuộc tính cập nhật
  InvoiceDetail copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? tenSanPham,
    int? soLuong,
    double? donGia,
    double? thanhTien,
  }) {
    return InvoiceDetail(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      tenSanPham: tenSanPham ?? this.tenSanPham,
      soLuong: soLuong ?? this.soLuong,
      donGia: donGia ?? this.donGia,
      thanhTien: thanhTien ?? ((soLuong ?? this.soLuong) * (donGia ?? this.donGia)),
    );
  }

  /// Format thành tiền theo VND
  String get formattedThanhTien => CurrencyFormatter.format(thanhTien);
  String get formattedDonGia => CurrencyFormatter.format(donGia);

  @override
  String toString() {
    return 'InvoiceDetail(id: $id, invoiceId: $invoiceId, productId: $productId, tenSanPham: $tenSanPham, soLuong: $soLuong, donGia: $donGia, thanhTien: $thanhTien)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceDetail &&
        other.id == id &&
        other.invoiceId == invoiceId &&
        other.productId == productId &&
        other.tenSanPham == tenSanPham &&
        other.soLuong == soLuong &&
        other.donGia == donGia &&
        other.thanhTien == thanhTien;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      invoiceId.hashCode ^
      productId.hashCode ^
      tenSanPham.hashCode ^
      soLuong.hashCode ^
      donGia.hashCode ^
      thanhTien.hashCode;
}
