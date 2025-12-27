import 'package:flutter_test/flutter_test.dart';

// Siguraduhin na ang 'apartment_management_system' ay tugma sa name sa iyong pubspec.yaml
import 'package:apartment_management_system/main.dart'; 

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Dito natin tinatawag ang ApartmentApp() na ginawa natin sa main.dart
    await tester.pumpWidget(const ApartmentApp());

    // Dahil Login Screen ang unang lumalabas, 
    // ite-test natin kung nahanap ba ang text na "APARTMENT ADMIN"
    expect(find.text('APARTMENT ADMIN'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);

    // Ite-test din natin kung wala pang Dashboard text sa simula
    expect(find.text('Dashboard Overview'), findsNothing);
  });
}