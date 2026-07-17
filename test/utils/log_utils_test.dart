import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/log_utils.dart';

void main() {
  group('LogUtils.getLogColor', () {
    test('[+] retorna verde', () {
      expect(LogUtils.getLogColor('[+] found 5 subdomains'), Colors.green.shade700);
    });

    test('[*] retorna azul', () {
      expect(LogUtils.getLogColor('[*] running subfinder'), Colors.blue.shade700);
    });

    test('[!] retorna laranja', () {
      expect(LogUtils.getLogColor('[!] rate limit warning'), Colors.orange.shade800);
    });

    test('[-] retorna vermelho', () {
      expect(LogUtils.getLogColor('[-] subfinder failed'), Colors.red.shade700);
    });

    test('prefixo não reconhecido retorna preto', () {
      expect(LogUtils.getLogColor('plain log line'), Colors.black);
    });

    test('string vazia retorna preto', () {
      expect(LogUtils.getLogColor(''), Colors.black);
    });

    test('prefixo precisa estar no início — não no meio da string', () {
      expect(LogUtils.getLogColor('note: [+] found'), Colors.black);
    });
  });
}
