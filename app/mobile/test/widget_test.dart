import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app.dart';
import 'package:mobile/config/app_config.dart';

void main() {
  testWidgets('Discovery-pET home loads without backend config', (tester) async {
    await tester.pumpWidget(
      const DiscoveryPetApp(config: AppConfig.empty),
    );

    expect(find.text('Discovery-pET'), findsOneWidget);
    expect(find.text('Acciones principales'), findsOneWidget);
    expect(find.text('Ver mapa'), findsOneWidget);
    expect(find.text('Reportar animal'), findsOneWidget);
  });
}
