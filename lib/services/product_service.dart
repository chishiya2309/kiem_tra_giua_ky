import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/sample_data.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore? _customFirestore;

  ProductService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.productsCollection);

  /// Lắng nghe danh sách sản phẩm thời gian thực (Real-time Stream)
  Stream<List<Product>> streamProducts() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(SampleData.sampleProducts);
    }
    return _collection
        .orderBy('tenSanPham')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// Lấy toàn bộ danh sách sản phẩm 1 lần (Future)
  Future<List<Product>> getAllProducts() async {
    if (Firebase.apps.isEmpty) {
      return SampleData.sampleProducts;
    }
    final snapshot = await _collection.orderBy('tenSanPham').get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  /// Lấy thông tin 1 sản phẩm theo ID
  Future<Product?> getProductById(String id) async {
    if (Firebase.apps.isEmpty) {
      return SampleData.sampleProducts.where((p) => p.id == id).firstOrNull;
    }
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Thêm mới một sản phẩm
  Future<String> addProduct(Product product) async {
    if (product.id.isNotEmpty) {
      await _collection.doc(product.id).set(product.toMap());
      return product.id;
    } else {
      final docRef = await _collection.add(product.toMap());
      return docRef.id;
    }
  }

  /// Cập nhật thông tin sản phẩm
  Future<void> updateProduct(Product product) async {
    await _collection.doc(product.id).update(product.toMap());
  }

  /// Cập nhật số lượng tồn kho
  Future<void> updateStock(String productId, int newQuantity) async {
    await _collection.doc(productId).update({
      'soLuongTon': newQuantity,
    });
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  /// Nạp các sản phẩm mẫu vào Firestore (Hữu ích khi khởi tạo dự án)
  Future<int> seedSampleProducts({bool overwrite = false}) async {
    int seededCount = 0;
    final batch = _firestore.batch();

    for (final sample in SampleData.sampleProducts) {
      final docRef = _collection.doc(sample.id);
      final doc = await docRef.get();

      if (!doc.exists || overwrite) {
        batch.set(docRef, sample.toMap(), SetOptions(merge: !overwrite));
        seededCount++;
      }
    }

    if (seededCount > 0) {
      await batch.commit();
    }
    return seededCount;
  }
}
