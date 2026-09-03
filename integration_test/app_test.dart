// Testes end-to-end das jornadas de UI que NÃO disparam um scan real.
//
// Um scan de verdade baixa binários e faz requisições de rede (subfinder,
// crt.sh, etc.), o que não é reproduzível/determinístico em CI — por isso os
// fluxos aqui cobrem: boot, validação de domínio, navegação, edição/reset de
// comandos em Configurações e troca de idioma.
//
// Rodar em um device/emulador:  flutter test integration_test/app_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inviscan/l10n/app_localizations.dart';
import 'package:inviscan/main.dart';
import 'package:inviscan/providers/locale_provider.dart';
import 'package:inviscan/viewmodels/scan_viewmodel.dart';

class _MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _MockPathProvider(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inviscan_e2e_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // Monta o app com providers reais e o locale já carregado, como em `main`.
  Future<AppLocalizations> bootApp(WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    await localeProvider.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScanViewModel()),
          ChangeNotifierProvider.value(value: localeProvider),
        ],
        child: const MyApp(),
      ),
    );
    // Sem pumpAndSettle: PreviousScansList anima um indicador ao carregar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final ctx = tester.element(find.byType(Scaffold).first);
    return AppLocalizations.of(ctx);
  }

  testWidgets('boot: home em português com botão de scan', (tester) async {
    final l10n = await bootApp(tester);
    expect(find.text(l10n.scanButton), findsWidgets);
    expect(l10n.scanButton, 'Escanear');
  });

  testWidgets('domínio inválido mostra erro e não navega', (tester) async {
    final l10n = await bootApp(tester);

    await tester.enterText(find.byType(TextField).first, 'not a domain!!');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.scanButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    // Continuou na home: a ScanScreen (com o log de execução) não foi empilhada.
    expect(find.text(l10n.executionLog), findsNothing);
  });

  testWidgets('abre Configurações, edita e salva comando do ffuf',
      (tester) async {
    final l10n = await bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsTitle), findsWidgets);
    expect(find.text(l10n.ffufCommandLabel), findsOneWidget);

    final ffufField = find.byType(TextFormField).first;
    await tester.enterText(ffufField, 'ffuf -w x.txt -u http://FUZZ.DOMAIN');

    final saveBtn = find.widgetWithText(ElevatedButton, l10n.saveAllButton);
    // Botão fica no fim da ListView; rola até ele aparecer.
    await tester.scrollUntilVisible(
      saveBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pump();
    expect(find.text(l10n.commandsSaved), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text(l10n.scanButton), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ffuf_command'),
        'ffuf -w x.txt -u http://FUZZ.DOMAIN');
  });

  testWidgets('restaurar padrão do ffuf reverte o campo', (tester) async {
    await bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final ffufField = find.byType(TextFormField).first;
    await tester.enterText(ffufField, 'lixo');

    // Primeiro ícone de restaurar corresponde ao campo do ffuf.
    await tester.tap(find.byIcon(Icons.restore).first);
    await tester.pump();

    final field = tester.widget<TextFormField>(ffufField);
    expect(field.controller!.text, contains('ffuf'));
    expect(field.controller!.text, isNot('lixo'));
  });

  testWidgets('trocar idioma para inglês atualiza a UI', (tester) async {
    await bootApp(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Escanear'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
  });
}
