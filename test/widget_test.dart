import 'package:flutter_test/flutter_test.dart';
import 'package:kiem_tra_giua_ky_nhom_9/main.dart';

void main() {
  testWidgets('App launches with MainScreen and 3 Tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const GroceryStoreApp());
    expect(find.text('Bán Hàng & Giỏ Hàng'), findsOneWidget);
    expect(find.text('Bán Hàng'), findsOneWidget);
    expect(find.text('Kho Hàng'), findsOneWidget);
    expect(find.text('Báo Cáo'), findsOneWidget);
  });
}
