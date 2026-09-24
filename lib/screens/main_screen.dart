import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'inventory/inventory_screen.dart';
import 'pos/pos_screen.dart';
import 'reports/reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PosScreen(),
    InventoryScreen(),
    ReportsScreen(),
  ];

  final List<String> _titles = const [
    'Bán Hàng & Giỏ Hàng',
    'Quản Lý Sản Phẩm & Kho',
    'Thống Kê Doanh Thu & Lịch Sử',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Cửa hàng tạp hóa Nhóm 9',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: FirebaseService.isInitialized
                ? 'Firebase: Đã kết nối'
                : 'Firebase: Đang khởi tạo',
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(
                    FirebaseService.isInitialized
                        ? Icons.cloud_done
                        : Icons.cloud_queue,
                    color: FirebaseService.isInitialized
                        ? Colors.green.shade700
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    FirebaseService.isInitialized ? 'Online' : 'Syncing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FirebaseService.isInitialized
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: Colors.blue),
            label: 'Bán Hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Colors.blue),
            label: 'Kho Hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Colors.blue),
            label: 'Báo Cáo',
          ),
        ],
      ),
    );
  }
}
