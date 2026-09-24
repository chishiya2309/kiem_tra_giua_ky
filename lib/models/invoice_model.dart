import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/invoice_calculator.dart';
import 'invoice_detail_model.dart';

class Invoice {
  final String id;
  final DateTime ngayBan;
  final String nhanVien;
  final double tamTinh;
  final double vat;
  final double giamGia;
  final double tongTien;
  final List<InvoiceDetail> danhSachChiTiet;

  Invoice({
    required this.id,
    required this.ngayBan,
    required this.nhanVien,
    required this.tongTien,
    required this.vat,
    required this.giamGia,
    double? tamTinh,
    List<InvoiceDetail>? danhSachChiTiet,
  })  : tamTinh = tamTinh ?? (tongTien - vat + giamGia),
        danhSachChiTiet = danhSachChiTiet ?? const [];

  /// Factory tiện ích tự động tính tổng tiền, VAT (10%), giảm giá (5% > 500k) từ danh sách chi tiết
  factory Invoice.create({
    required String id,
    required DateTime ngayBan,
    required String nhanVien,
    required List<InvoiceDetail> items,
  }) {
    final calc = InvoiceCalculator.calculate(items: items);
    return Invoice(
      id: id,
      ngayBan: ngayBan,
      nhanVien: nhanVien,
      tamTinh: calc.tamTinh,
      vat: calc.vat,
      giamGia: calc.giamGia,
      tongTien: calc.tongTien,
      danhSachChiTiet: items,
    );
  }

  /// Chuyển đối tượng thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'ngayBan': Timestamp.fromDate(ngayBan),
      'nhanVien': nhanVien,
      'tamTinh': tamTinh,
      'vat': vat,
      'giamGia': giamGia,
      'tongTien': tongTien,
      'danhSachChiTiet': danhSachChiTiet.map((item) => item.toMap()).toList(),
    };
  }

  /// Tạo đối tượng Invoice từ Map
  factory Invoice.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parsedNgayBan;
    final rawNgayBan = map['ngayBan'];
    if (rawNgayBan is Timestamp) {
      parsedNgayBan = rawNgayBan.toDate();
    } else if (rawNgayBan is String) {
      parsedNgayBan = DateTime.tryParse(rawNgayBan) ?? DateTime.now();
    } else if (rawNgayBan is int) {
      parsedNgayBan = DateTime.fromMillisecondsSinceEpoch(rawNgayBan);
    } else {
      parsedNgayBan = DateTime.now();
    }

    final rawDetails = map['danhSachChiTiet'] as List<dynamic>? ?? [];
    final details = rawDetails.map((e) {
      if (e is Map<String, dynamic>) {
        return InvoiceDetail.fromMap(e);
      }
      return InvoiceDetail.fromMap(Map<String, dynamic>.from(e as Map));
    }).toList();

    return Invoice(
      id: id ?? map['id'] ?? '',
      ngayBan: parsedNgayBan,
      nhanVien: map['nhanVien'] as String? ?? 'NhanVien',
      tamTinh: (map['tamTinh'] as num?)?.toDouble() ?? 0.0,
      vat: (map['vat'] as num?)?.toDouble() ?? 0.0,
      giamGia: (map['giamGia'] as num?)?.toDouble() ?? 0.0,
      tongTien: (map['tongTien'] as num?)?.toDouble() ?? 0.0,
      danhSachChiTiet: details,
    );
  }

  /// Tạo đối tượng Invoice từ DocumentSnapshot của Firestore
  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Invoice.fromMap(data, id: doc.id);
  }

  /// Tạo bản sao với các thuộc tính cập nhật
  Invoice copyWith({
    String? id,
    DateTime? ngayBan,
    String? nhanVien,
    double? tamTinh,
    double? vat,
    double? giamGia,
    double? tongTien,
    List<InvoiceDetail>? danhSachChiTiet,
  }) {
    return Invoice(
      id: id ?? this.id,
      ngayBan: ngayBan ?? this.ngayBan,
      nhanVien: nhanVien ?? this.nhanVien,
      tamTinh: tamTinh ?? this.tamTinh,
      vat: vat ?? this.vat,
      giamGia: giamGia ?? this.giamGia,
      tongTien: tongTien ?? this.tongTien,
      danhSachChiTiet: danhSachChiTiet ?? this.danhSachChiTiet,
    );
  }

  // Tiện ích format hiển thị VND
  String get formattedTamTinh => CurrencyFormatter.format(tamTinh);
  String get formattedVAT => CurrencyFormatter.format(vat);
  String get formattedGiamGia => CurrencyFormatter.format(giamGia);
  String get formattedTongTien => CurrencyFormatter.format(tongTien);

  @override
  String toString() {
    return 'Invoice(id: $id, ngayBan: $ngayBan, nhanVien: $nhanVien, tongTien: $tongTien, vat: $vat, giamGia: $giamGia, soLuongMon: ${danhSachChiTiet.length})';
  }
}
