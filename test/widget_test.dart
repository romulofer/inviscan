import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inviscan/l10n/app_localizations.dart';
import 'package:inviscan/main.dart';
import 'package:inviscan/providers/locale_provider.dart';
import 'package:inviscan/viewmodels/scan_viewmodel.dart';

void main() {
  Widget montarApp() => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScanViewModel()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: const MyApp(),
      );

  testWidgets('app renderiza a tela inicial com campo de scan', (tester) async {
    await tester.pumpWidget(montarApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('app usa português como idioma padrão', (tester) async {
    await tester.pumpWidget(montarApp());
    // Sem pumpAndSettle: PreviousScansList mantém um CircularProgressIndicator
    // animando enquanto carrega o histórico, o que nunca "assenta".
    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    // Botão principal em pt-BR confirma que o idioma padrão é português.
    expect(find.text(l10n.scanButton), findsWidgets);
    expect(l10n.scanButton, 'Escanear');
  });
}
