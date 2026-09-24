import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../shared/receipt_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  String _selectedPeriod = 'today'; // 'today', 'month', 'all'

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  List<Invoice> _filterInvoices(List<Invoice> allInvoices) {
    final now = DateTime.now();
    if (_selectedPeriod == 'today') {
      return allInvoices.where((inv) => _isSameDay(inv.ngayBan, now)).toList();
    } else if (_selectedPeriod == 'month') {
      return allInvoices.where((inv) => _isSameMonth(inv.ngayBan, now)).toList();
    }
    return allInvoices;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return StreamBuilder<List<Invoice>>(
      stream: _invoiceService.streamInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allInvoices = snapshot.data ?? [];
        final filteredInvoices = _filterInvoices(allInvoices);

        // Tính toán các chỉ số thống kê
        double totalRevenue = 0;
        double totalDiscount = 0;
        double totalVat = 0;

        for (final inv in filteredInvoices) {
          totalRevenue += inv.tongTien;
          totalDiscount += inv.giamGia;
          totalVat += inv.vat;
        }

        final avgOrderValue = filteredInvoices.isEmpty
            ? 0.0
            : totalRevenue / filteredInvoices.length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // 1. Bộ chọn thời gian thống kê
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'today',
                        label: Text('Hôm nay'),
                        icon: Icon(Icons.today, size: 16),
                      ),
                      ButtonSegment(
                        value: 'month',
                        label: Text('Tháng này'),
                        icon: Icon(Icons.calendar_month, size: 16),
                      ),
                      ButtonSegment(
                        value: 'all',
                        label: Text('Tất cả'),
                        icon: Icon(Icons.history, size: 16),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                      });
                    },
                  ),
                ),
              ),

              // 2. Thẻ KPI tổng quan doanh thu & chỉ số
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      // Thẻ lớn: Tổng doanh thu
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade800, Colors.teal.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TỔNG DOANH THU',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedPeriod == 'today'
                                        ? 'Hôm nay'
                                        : _selectedPeriod == 'month'
                                            ? 'Tháng này'
                                            : 'Tất cả',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(totalRevenue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Đã bao gồm 10% VAT | ${filteredInvoices.length} đơn hàng thành công',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Hàng các chỉ số phụ: Số đơn, Giảm giá, VAT, TB/đơn
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Số đơn hàng',
                              value: '${filteredInvoices.length} đơn',
                              icon: Icons.receipt_long,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'TB / Đơn',
                              value: CurrencyFormatter.format(avgOrderValue),
                              icon: Icons.trending_up,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Ưu đãi giảm giá',
                              value: CurrencyFormatter.format(totalDiscount),
                              icon: Icons.discount,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Tổng thuế VAT',
                              value: CurrencyFormatter.format(totalVat),
                              icon: Icons.account_balance,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Tiêu đề danh sách hóa đơn
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch Sử Hóa Đơn Bán Hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredInvoices.length} hóa đơn',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Danh sách hóa đơn
              if (filteredInvoices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedPeriod == 'today'
                              ? 'Chưa có hóa đơn nào được tạo hôm nay.'
                              : 'Chưa có dữ liệu hóa đơn trong thời gian này.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final invoice = filteredInvoices[index];
                        final displayId = invoice.id.length > 8
                            ? invoice.id.substring(0, 8).toUpperCase()
                            : invoice.id;

                        final totalItemsCount = invoice.danhSachChiTiet.fold(
                          0,
                          (sum, it) => sum + it.soLuong,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => ReceiptDialog.show(context, invoice),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.green.shade50,
                                    child: Icon(
                                      Icons.receipt,
                                      color: Colors.green.shade700,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '#$displayId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (invoice.giamGia > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                        const SizedBox(height: 3),
                                        Text(
                                          dateFormat.format(invoice.ngayBan),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'NV: ${invoice.nhanVien} • $totalItemsCount SP',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        invoice.formattedTongTien,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Xem HĐ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: Colors.green.shade700,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredInvoices.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
