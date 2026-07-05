import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_assistant/main.dart';
import 'package:student_assistant/services/storage_service.dart';
import 'package:student_assistant/screens/home/home_screen.dart';

void main() {
  testWidgets('Student Assistant splash screen renders smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences initial values
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          ChangeNotifierProvider<ThemeNotifier>(
            create: (context) => ThemeNotifier(storageService),
          ),
        ],
        child: const StudentAssistantApp(),
      ),
    );

    // Verify that Splash Screen text contents are rendered
    expect(find.text('Student Assistant'), findsOneWidget);
    expect(find.text('AI Powered Learning'), findsOneWidget);
  });
}
