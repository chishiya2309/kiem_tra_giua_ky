import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/currency_formatter.dart';

class Product {
  final String id;
  final String tenSanPham;
  final double donGia;
  final int soLuongTon;

  const Product({
    required this.id,
    required this.tenSanPham,
    required this.donGia,
    required this.soLuongTon,
  });

  /// Chuyển đối tượng thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'tenSanPham': tenSanPham,
      'donGia': donGia,
      'soLuongTon': soLuongTon,
    };
  }

  /// Tạo đối tượng Product từ Map (e.g. từ cache, local, hoặc Firestore)
  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id ?? map['id'] ?? '',
      tenSanPham: map['tenSanPham'] as String? ?? '',
      donGia: (map['donGia'] as num?)?.toDouble() ?? 0.0,
      soLuongTon: (map['soLuongTon'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tạo đối tượng Product từ DocumentSnapshot của Firestore
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product.fromMap(data, id: doc.id);
  }

  /// Tạo bản sao với các thuộc tính được cập nhật
  Product copyWith({
    String? id,
    String? tenSanPham,
    double? donGia,
    int? soLuongTon,
  }) {
    return Product(
      id: id ?? this.id,
      tenSanPham: tenSanPham ?? this.tenSanPham,
      donGia: donGia ?? this.donGia,
      soLuongTon: soLuongTon ?? this.soLuongTon,
    );
  }

  /// Kiểm tra xem còn đủ hàng trong kho hay không
  bool isAvailable(int requestedQuantity) {
    return requestedQuantity > 0 && soLuongTon >= requestedQuantity;
  }

  /// Giá tiền được format sẵn theo chuẩn VND
  String get formattedDonGia => CurrencyFormatter.format(donGia);

  @override
  String toString() {
    return 'Product(id: $id, tenSanPham: $tenSanPham, donGia: $donGia, soLuongTon: $soLuongTon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.tenSanPham == tenSanPham &&
        other.donGia == donGia &&
        other.soLuongTon == soLuongTon;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      tenSanPham.hashCode ^
      donGia.hashCode ^
      soLuongTon.hashCode;
}
