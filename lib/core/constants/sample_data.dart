import '../../models/product_model.dart';

class SampleData {
  /// Danh sách sản phẩm mẫu theo yêu cầu đề bài
  static final List<Product> sampleProducts = [
    const Product(
      id: 'sua_tuoi_1l',
      tenSanPham: 'Sữa tươi 1L',
      donGia: 28000.0,
      soLuongTon: 50,
    ),
    const Product(
      id: 'banh_mi',
      tenSanPham: 'Bánh mì',
      donGia: 12000.0,
      soLuongTon: 100,
    ),
    const Product(
      id: 'nuoc_nghot',
      tenSanPham: 'Nước ngọt',
      donGia: 15000.0,
      soLuongTon: 80,
    ),
    const Product(
      id: 'gao_5kg',
      tenSanPham: 'Gạo 5kg',
      donGia: 150000.0,
      soLuongTon: 30,
    ),
  ];
}
