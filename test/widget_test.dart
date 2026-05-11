import 'package:flutter_test/flutter_test.dart';

import 'package:floracerta/app.dart';

void main() {
  testWidgets('renders FloraCerta home content', (tester) async {
    await tester.pumpWidget(const FloraCertaApp());
    await tester.pumpAndSettle();

    expect(find.text('FloraCerta'), findsOneWidget);
    expect(
      find.text('Identifique, registre e acompanhe suas plantas.'),
      findsOneWidget,
    );
    expect(find.text('Identificar planta'), findsWidgets);
  });
}
