import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o idioma escolhido e persiste a preferência.
///
/// O app é primariamente em português (pt); inglês (en) é opcional via
/// Configurações. Por isso o padrão é sempre pt — deliberadamente NÃO seguimos
/// o idioma do sistema, para que um dispositivo em inglês ainda abra em pt até
/// o usuário escolher o contrário.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale';
  static const defaultLocale = Locale('pt');
  static const supportedLanguageCodes = ['pt', 'en'];

  Locale _locale = defaultLocale;
  Locale get locale => _locale;

  /// Carrega a preferência salva. Chamar antes de `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
