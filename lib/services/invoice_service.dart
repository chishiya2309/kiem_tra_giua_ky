import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore? _customFirestore;

  InvoiceService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _firestore.collection(AppConstants.invoicesCollection);

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection(AppConstants.productsCollection);

  /// Tạo hóa đơn mới với Firestore Transaction để trừ tồn kho tự động & an toàn
  Future<String> createInvoice(Invoice invoice) async {
    return await _firestore.runTransaction<String>((transaction) async {
      // 1. Kiểm tra tồn kho của tất cả sản phẩm trong hóa đơn trước
      for (final item in invoice.danhSachChiTiet) {
        if (item.productId.isEmpty) continue;

        final productRef = _productsCollection.doc(item.productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Sản phẩm không tồn tại trong hệ thống (ID: ${item.productId})');
        }

        final data = productSnapshot.data() ?? {};
        final int currentStock = (data['soLuongTon'] as num?)?.toInt() ?? 0;
        final String tenSP = data['tenSanPham'] as String? ?? item.tenSanPham;

        if (currentStock < item.soLuong) {
          throw Exception(
            'Sản phẩm "$tenSP" không đủ hàng tồn kho! '
            'Tồn kho hiện tại: $currentStock, Yêu cầu: ${item.soLuong}',
          );
        }

        // Trừ số lượng tồn kho
        final int updatedStock = currentStock - item.soLuong;
        transaction.update(productRef, {'soLuongTon': updatedStock});
      }

      // 2. Tạo ID hóa đơn và lưu thông tin hóa đơn
      final invoiceRef = invoice.id.isNotEmpty
          ? _invoicesCollection.doc(invoice.id)
          : _invoicesCollection.doc();

      final invoiceToSave = invoice.id.isEmpty
          ? invoice.copyWith(id: invoiceRef.id)
          : invoice;

      transaction.set(invoiceRef, invoiceToSave.toMap());

      return invoiceRef.id;
    });
  }

  /// Lắng nghe danh sách hóa đơn theo thời gian thực (Mới nhất lên đầu)
  Stream<List<Invoice>> streamInvoices() {
    if (Firebase.apps.isEmpty) {
      return const Stream.empty();
    }
    return _invoicesCollection
        .orderBy('ngayBan', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
  }

  /// Lấy danh sách hóa đơn trong một khoảng thời gian (Hỗ trợ thống kê ngày, tháng)
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate) async {
    if (Firebase.apps.isEmpty) return [];

    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    final snapshot = await _invoicesCollection
        .where('ngayBan', isGreaterThanOrEqualTo: startTimestamp)
        .where('ngayBan', isLessThanOrEqualTo: endTimestamp)
        .orderBy('ngayBan', descending: true)
        .get();

    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  }

  /// Lấy chi tiết 1 hóa đơn theo ID
  Future<Invoice?> getInvoiceById(String id) async {
    if (Firebase.apps.isEmpty) return null;
    final doc = await _invoicesCollection.doc(id).get();
    if (!doc.exists) return null;
    return Invoice.fromFirestore(doc);
  }
}
