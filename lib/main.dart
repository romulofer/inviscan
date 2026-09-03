import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/tool_installer.dart';
import 'utils/android_native.dart';
import 'utils/binaries.dart';
import 'viewmodels/scan_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android: ferramentas vêm empacotadas no APK; resolve pelo nativeLibraryDir.
  if (Platform.isAndroid) {
    setAndroidNativeLibDir(await fetchAndroidNativeLibDir());
  }
  // Torna binários baixados resolvíveis pelo binPath (síncrono).
  await ToolInstaller().registerBinDir();
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanViewModel()),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
