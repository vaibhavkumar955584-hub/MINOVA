import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MineSafe App Startup & Rendering Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MineSafeApp(),
      ),
    );

    // Initial frame pump
    await tester.pump();
    expect(find.byType(MineSafeApp), findsOneWidget);
  });
}

