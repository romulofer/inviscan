import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/browser.dart';

void main() {
  group('resolveBrowserPath', () {
    test('retorna o caminho configurado quando o arquivo existe', () {
      final tmp = File(
        '${Directory.systemTemp.path}/fake_chrome_${DateTime.now().microsecondsSinceEpoch}',
      )..writeAsStringSync('');
      addTearDown(() => tmp.deleteSync());

      expect(resolveBrowserPath(tmp.path), tmp.path);
    });

    test('ignora caminho configurado inexistente', () {
      // Um caminho claramente inexistente não deve ser retornado; a resolução
      // cai na autodetecção (que pode achar Chrome/Edge ou nada).
      const bogus = '/definitely/not/a/real/chrome/binary/xyz';
      expect(resolveBrowserPath(bogus), isNot(bogus));
    });

    test('ignora caminho configurado vazio ou só espaços', () {
      expect(resolveBrowserPath('   '), isNot('   '));
    });
  });
}
