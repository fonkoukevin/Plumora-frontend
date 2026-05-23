import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/main.dart';

void main() {
  testWidgets('Plumora starts on public landing page', (tester) async {
    await tester.pumpWidget(const PlumoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
  testWidgets('PlumoraBookCover resolves backend upload cover URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlumoraBookCover(
            colors: [Colors.black, Colors.white],
            imageUrl: 'uploads/book-covers/cover.png',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;

    expect(provider, isA<NetworkImage>());
    expect(
      (provider as NetworkImage).url,
      'http://localhost:8080/api/v1/uploads/book-covers/cover.png',
    );
  });
}
