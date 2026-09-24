import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterStockStatus = 'all'; // 'all', 'in_stock', 'low_stock', 'out_of_stock'
  bool _isSeeding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedSampleData() async {
    setState(() => _isSeeding = true);
    try {
      final count = await _productService.seedSampleProducts(overwrite: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(' Đã nạp thành công $count sản phẩm mẫu lên Firestore!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Lỗi nạp dữ liệu: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showProductDialog({Product? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.tenSanPham ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.donGia.toStringAsFixed(0) : '',
    );
    final stockController = TextEditingController(
      text: product != null ? product.soLuongTon.toString() : '10',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit : Icons.add_circle,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(isEditing ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    hintText: 'Ví dụ: Sữa tươi 1L',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên sản phẩm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá (VNĐ) *',
                    hintText: 'Ví dụ: 28000',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập đơn giá';
                    }
                    final parsed = double.tryParse(val.replaceAll('.', '').trim());
                    if (parsed == null || parsed < 0) {
                      return 'Đơn giá không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng tồn kho *',
                    hintText: 'Ví dụ: 50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số lượng tồn';
                    }
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Số lượng phải lớn hơn hoặc bằng 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final price = double.parse(
                  priceController.text.replaceAll('.', '').trim(),
                );
                final stock = int.parse(stockController.text.trim());

                final updatedProduct = Product(
                  id: product?.id ?? '',
                  tenSanPham: name,
                  donGia: price,
                  soLuongTon: stock,
                );

                Navigator.of(ctx).pop();

                try {
                  if (isEditing) {
                    await _productService.updateProduct(updatedProduct);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(' Đã cập nhật thông tin sản phẩm!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await _productService.addProduct(updatedProduct);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(' Đã thêm sản phẩm mới vào kho!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.tenSanPham}" khỏi danh mục không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _productService.deleteProduct(product.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(' Đã xóa sản phẩm "${product.tenSanPham}"'),
                      backgroundColor: Colors.grey.shade800,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xóa'),
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

        // Lọc theo từ khóa tìm kiếm và trạng thái tồn kho
        final filtered = products.where((p) {
          final matchesSearch = _searchQuery.isEmpty ||
              p.tenSanPham.toLowerCase().contains(_searchQuery.toLowerCase());

          if (!matchesSearch) return false;

          if (_filterStockStatus == 'in_stock') {
            return p.soLuongTon > 20;
          } else if (_filterStockStatus == 'low_stock') {
            return p.soLuongTon > 0 && p.soLuongTon <= 20;
          } else if (_filterStockStatus == 'out_of_stock') {
            return p.soLuongTon == 0;
          }
          return true;
        }).toList();

        final inStockCount = products.where((p) => p.soLuongTon > 20).length;
        final lowStockCount =
            products.where((p) => p.soLuongTon > 0 && p.soLuongTon <= 20).length;
        final outOfStockCount = products.where((p) => p.soLuongTon == 0).length;

        return Scaffold(
          body: Column(
            children: [
              // Thanh tìm kiếm & nút nạp mẫu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên sản phẩm...',
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
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Nạp lại 4 sản phẩm mẫu',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.teal.shade50,
                        foregroundColor: Colors.teal.shade800,
                      ),
                      onPressed: _isSeeding ? null : _seedSampleData,
                      icon: _isSeeding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download),
                    ),
                  ],
                ),
              ),

              // Bộ lọc trạng thái tồn kho (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả (${products.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'in_stock',
                      'Còn hàng ($inStockCount)',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'low_stock',
                      'Sắp hết ($lowStockCount)',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'out_of_stock',
                      'Hết hàng ($outOfStockCount)',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Danh sách sản phẩm tồn kho
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              products.isEmpty
                                  ? 'Kho hàng hiện tại đang trống.'
                                  : 'Không tìm thấy sản phẩm nào.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (products.isEmpty) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isSeeding ? null : _seedSampleData,
                                icon: const Icon(Icons.download),
                                label: const Text('Nạp 4 Sản Phẩm Mẫu Ngay'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final isOutOfStock = product.soLuongTon == 0;
                          final isLowStock =
                              product.soLuongTon > 0 && product.soLuongTon <= 20;

                          Color statusColor = Colors.green;
                          String statusText = 'Còn hàng';
                          if (isOutOfStock) {
                            statusColor = Colors.red;
                            statusText = 'Hết hàng';
                          } else if (isLowStock) {
                            statusColor = Colors.orange;
                            statusText = 'Sắp hết';
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isOutOfStock
                                    ? Colors.red.shade200
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Icon đại diện
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: statusColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: statusColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Thông tin sản phẩm
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.tenSanPham,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Đơn giá: ${product.formattedDonGia}',
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: statusColor.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                '$statusText (Tồn: ${product.soLuongTon})',
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Hành động Sửa / Xóa
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Sửa thông tin / Tồn kho',
                                        onPressed: () => _showProductDialog(
                                          product: product,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Xóa sản phẩm',
                                        onPressed: () => _confirmDelete(product),
                                      ),
                                    ],
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

          // Nút thêm sản phẩm mới
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Sản Phẩm'),
            onPressed: () => _showProductDialog(),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _filterStockStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStockStatus = key);
      },
      selectedColor: (color ?? Colors.blue).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Colors.blue.shade900) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
