import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';

class ReceiptDialog extends StatelessWidget {
  final Invoice invoice;

  const ReceiptDialog({super.key, required this.invoice});

  static Future<void> show(BuildContext context, Invoice invoice) {
    return showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final formattedDate = dateFormat.format(invoice.ngayBan);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header cửa hàng
              const Icon(Icons.storefront, size: 40, color: Colors.green),
              const SizedBox(height: 6),
              const Text(
                'CỬA HÀNG TẠP HÓA NHÓM 9',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Đ/c: Trường Đại học - Khoa CNTT\nHotline: 1900 9999',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'HÓA ĐƠN BÁN HÀNG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // 2. Thông tin giao dịch
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Mã HĐ:', invoice.id.length > 10 ? invoice.id.substring(0, 10).toUpperCase() : invoice.id),
                    const SizedBox(height: 4),
                    _buildMetaRow('Thời gian:', formattedDate),
                    const SizedBox(height: 4),
                    _buildMetaRow('Nhân viên:', invoice.nhanVien),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildDashedLine(),
              const SizedBox(height: 8),

              // 3. Tiêu đề bảng chi tiết món
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Tên SP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SL',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Đơn giá',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'T.Tiền',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 6),

              // 4. Danh sách các món trong hóa đơn
              ...invoice.danhSachChiTiet.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.tenSanPham,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.soLuong}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.formattedDonGia,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.formattedThanhTien,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),
              _buildDashedLine(),
              const SizedBox(height: 8),

              // 5. Phần tính tiền: Tạm tính, Giảm giá, VAT, Tổng cộng
              _buildTotalRow('Tạm tính:', invoice.formattedTamTinh),
              const SizedBox(height: 4),
              _buildTotalRow(
                'Giảm giá (5% khi > 500k):',
                invoice.giamGia > 0 ? '-${invoice.formattedGiamGia}' : '0 đ',
                valueColor: invoice.giamGia > 0 ? Colors.green.shade700 : Colors.grey,
              ),
              const SizedBox(height: 4),
              _buildTotalRow(
                'Thuế VAT (10%):',
                '+${invoice.formattedVAT}',
                valueColor: Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              const Divider(thickness: 1.5),
              const SizedBox(height: 4),
              _buildTotalRow(
                'TỔNG THANH TOÁN:',
                invoice.formattedTongTien,
                isLarge: true,
                valueColor: Colors.red.shade700,
              ),

              const SizedBox(height: 16),
              const Text(
                'Cảm ơn Quý khách & Hẹn gặp lại!\n(Giá đã bao gồm 10% VAT)',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 6. Nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(' Đang xuất hóa đơn (PDF / Máy in)...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('In HĐ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Xong / Đóng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 15 : 13,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
              color: isLarge ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 17 : 13,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
