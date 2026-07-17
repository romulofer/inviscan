import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inviscan/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('locale começa em português (padrão do app)', () {
      expect(LocaleProvider().locale, const Locale('pt'));
    });

    test('load sem preferência salva mantém português', () async {
      final provider = LocaleProvider();
      await provider.load();
      expect(provider.locale, const Locale('pt'));
    });

    test('setLocale muda o idioma e notifica ouvintes', () async {
      final provider = LocaleProvider();
      var notificado = false;
      provider.addListener(() => notificado = true);

      await provider.setLocale(const Locale('en'));

      expect(provider.locale, const Locale('en'));
      expect(notificado, isTrue);
    });

    test('setLocale persiste a preferência', () async {
      await LocaleProvider().setLocale(const Locale('en'));

      final novo = LocaleProvider();
      await novo.load();
      expect(novo.locale.languageCode, 'en');
    });

    test('setLocale ignora idiomas não suportados', () async {
      final provider = LocaleProvider();
      await provider.setLocale(const Locale('fr'));
      expect(provider.locale, const Locale('pt'));
    });
  });
}
