import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/main.dart';

void main() {
  testWidgets('CivicVoice app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pumpAndSettle();
    // Login screen should be visible at launch
    expect(find.text('CivicVoice'), findsWidgets);
  });
}
