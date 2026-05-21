import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/main.dart';

void main() {
  testWidgets('Plumora starts on public landing page', (tester) async {
    await tester.pumpWidget(const PlumoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
