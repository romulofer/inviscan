import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('inviscan/native');

/// Retorna o `nativeLibraryDir` do app Android (onde as ferramentas empacotadas
/// como `lib<tool>.so` ficam executáveis), ou `null` se indisponível.
Future<String?> fetchAndroidNativeLibDir() async {
  try {
    return await _channel.invokeMethod<String>('nativeLibDir');
  } catch (_) {
    return null;
  }
}
