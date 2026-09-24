import 'package:flutter/material.dart';
import '../../core/utils/invoice_calculator.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../shared/receipt_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductService _productService = ProductService();
  final InvoiceService _invoiceService = InvoiceService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _staffController =
      TextEditingController(text: 'Thu ngân 01');

  // productId -> số lượng đang chọn trong giỏ hàng
  final Map<String, int> _cart = {};
  String _searchQuery = '';
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _searchController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    if (product.soLuongTon <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sản phẩm "${product.tenSanPham}" đã hết hàng!'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.soLuongTon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kho chỉ còn ${product.soLuongTon} sản phẩm "${product.tenSanPham}"!',
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _cart[product.id] = currentQty + 1;
    });
  }

  void _decreaseQuantity(String productId) {
    setState(() {
      final currentQty = _cart[productId] ?? 0;
      if (currentQty > 1) {
        _cart[productId] = currentQty - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  List<InvoiceDetail> _getInvoiceDetails(List<Product> products) {
    final productMap = {for (var p in products) p.id: p};
    final List<InvoiceDetail> details = [];

    _cart.forEach((productId, qty) {
      final product = productMap[productId];
      if (product != null && qty > 0) {
        details.add(
          InvoiceDetail(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_$productId',
            invoiceId: '',
            productId: product.id,
            tenSanPham: product.tenSanPham,
            soLuong: qty,
            donGia: product.donGia,
          ),
        );
      }
    });

    return details;
  }

  Future<void> _handleCheckout(List<Product> products) async {
    final details = _getInvoiceDetails(products);
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng đang trống! Vui lòng chọn sản phẩm.')),
      );
      return;
    }

    final staffName = _staffController.text.trim().isEmpty
        ? 'Thu ngân 01'
        : _staffController.text.trim();

    setState(() => _isCheckingOut = true);

    try {
      final newInvoice = Invoice.create(
        id: '',
        ngayBan: DateTime.now(),
        nhanVien: staffName,
        items: details,
      );

      // Lưu lên Firestore và trừ tồn kho tự động qua Transaction
      final invoiceId = await _invoiceService.createInvoice(newInvoice);
      final finalInvoice = newInvoice.copyWith(id: invoiceId);

      if (!mounted) return;

      // Đóng bottom sheet giỏ hàng nếu đang mở
      Navigator.of(context).popUntil((route) => route.isFirst);

      if (!mounted) return;

      // Hiển thị dialog hóa đơn cho khách
      await ReceiptDialog.show(context, finalInvoice);

      // Làm mới giỏ hàng
      _clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            ' Thanh toán thành công! Mã HĐ: ${finalInvoice.id.length > 8 ? finalInvoice.id.substring(0, 8) : finalInvoice.id}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Lỗi Thanh Toán'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _showCartModal(List<Product> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final details = _getInvoiceDetails(products);
          final calc = InvoiceCalculator.calculate(items: details);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo modal
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Tiêu đề
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Giỏ Hàng (${details.length} món)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (details.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            _clearCart();
                            setModalState(() {});
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Danh sách món trong giỏ
                if (details.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Chưa có sản phẩm nào trong giỏ',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: details.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = details[index];
                        final product = products.firstWhere((p) => p.id == item.productId);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.tenSanPham,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.formattedDonGia} x ${item.soLuong}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item.formattedThanhTien,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bộ tăng giảm số lượng
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () {
                                        _decreaseQuantity(item.productId);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    Text(
                                      '${item.soLuong}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () {
                                        _addToCart(product);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: 'Xóa khỏi giỏ',
                                onPressed: () {
                                  _removeFromCart(item.productId);
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Nhập tên nhân viên & Bảng tổng kết
                if (details.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên nhân viên
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Text(
                              'Nhân viên:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _staffController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  hintText: 'Nhập tên nhân viên',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Banner giảm giá nếu thỏa mãn
                        if (calc.duocGiamGia)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Đơn hàng > 500.000 đ: Đã áp dụng giảm giá 5% (-${calc.formattedGiamGia})',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildCalcRow('Tạm tính:', calc.formattedTamTinh),
                        _buildCalcRow(
                          'Giảm giá (5%):',
                          calc.duocGiamGia ? '-${calc.formattedGiamGia}' : '0 đ',
                          color: calc.duocGiamGia ? Colors.green.shade700 : Colors.grey,
                        ),
                        _buildCalcRow(
                          'Thuế VAT (10%):',
                          '+${calc.formattedVAT}',
                          color: Colors.blue.shade700,
                        ),
                        const Divider(height: 16),
                        _buildCalcRow(
                          'TỔNG TIỀN:',
                          calc.formattedTongTien,
                          isBold: true,
                          color: Colors.red.shade700,
                          fontSize: 18,
                        ),
                        const SizedBox(height: 16),

                        // Nút thanh toán
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isCheckingOut
                                ? null
                                : () => _handleCheckout(products),
                            icon: _isCheckingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(
                              _isCheckingOut
                                  ? 'Đang xử lý...'
                                  : 'THANH TOÁN (${calc.formattedTongTien})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalcRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productService.streamProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];
        final filteredProducts = products.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.tenSanPham.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final details = _getInvoiceDetails(products);
        final calc = InvoiceCalculator.calculate(items: details);
        final int totalCartCount = _cart.values.fold(0, (sum, q) => sum + q);

        return Scaffold(
          body: Column(
            children: [
              // Thanh tìm kiếm nhanh sản phẩm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm bán...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),

              // Danh sách sản phẩm dạng Lưới (Grid)
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              products.isEmpty
                                  ? 'Kho hàng chưa có sản phẩm nào.\nHãy qua Tab "Kho Hàng" để nạp sản phẩm!'
                                  : 'Không tìm thấy sản phẩm phù hợp',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final qtyInCart = _cart[product.id] ?? 0;
                          final bool isOutOfStock = product.soLuongTon <= 0;

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: qtyInCart > 0
                                    ? Colors.blue.shade400
                                    : Colors.grey.shade200,
                                width: qtyInCart > 0 ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: isOutOfStock ? null : () => _addToCart(product),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Biểu tượng món hàng
                                        Center(
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.blue.shade50,
                                            child: const Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 30,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Tên sản phẩm
                                        Text(
                                          product.tenSanPham,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Đơn giá
                                        Text(
                                          product.formattedDonGia,
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Badge tồn kho
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isOutOfStock
                                                  ? 'Hết hàng'
                                                  : 'Tồn: ${product.soLuongTon}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOutOfStock
                                                    ? Colors.red
                                                    : Colors.grey.shade600,
                                                fontWeight: isOutOfStock
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isOutOfStock
                                                    ? Colors.grey.shade300
                                                    : Colors.blue.shade700,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badge số lượng đã thêm vào giỏ
                                  if (qtyInCart > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade700,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$qtyInCart',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Thanh giỏ hàng nổi phía dưới (Sticky Bottom Bar)
          bottomSheet: details.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Nút bấm mở chi tiết giỏ hàng
                      InkWell(
                        onTap: () => _showCartModal(products),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$totalCartCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Giỏ hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Tóm tắt tiền thanh toán
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  calc.formattedTongTien,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                if (calc.duocGiamGia)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '-5%',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'Đã gồm 10% VAT',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nút thanh toán trực tiếp
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isCheckingOut
                            ? null
                            : () => _showCartModal(products),
                        child: const Text(
                          'Chi tiết / Mua',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
