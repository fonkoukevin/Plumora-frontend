import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/main.dart';

void main() {
  testWidgets('Plumora starts on authentication placeholder', (tester) async {
    await tester.pumpWidget(const PlumoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Authentication placeholder'), findsOneWidget);
    expect(find.text('Enter Plumora'), findsOneWidget);
  });
}
