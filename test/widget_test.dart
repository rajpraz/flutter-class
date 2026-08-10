import 'package:flutter_test/flutter_test.dart';
import 'package:untitled3/main.dart';

void main() {
  testWidgets('shows the pooja store branding on launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pooja Pasal'), findsOneWidget);
  });
}
