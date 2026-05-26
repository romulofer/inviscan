import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/log_utils.dart';

void main() {
  group('LogUtils.getLogColor', () {
    test('[+] returns green', () {
      expect(LogUtils.getLogColor('[+] found 5 subdomains'), Colors.green.shade700);
    });

    test('[*] returns blue', () {
      expect(LogUtils.getLogColor('[*] running subfinder'), Colors.blue.shade700);
    });

    test('[!] returns orange', () {
      expect(LogUtils.getLogColor('[!] rate limit warning'), Colors.orange.shade800);
    });

    test('[-] returns red', () {
      expect(LogUtils.getLogColor('[-] subfinder failed'), Colors.red.shade700);
    });

    test('no recognised prefix returns black', () {
      expect(LogUtils.getLogColor('plain log line'), Colors.black);
    });

    test('empty string returns black', () {
      expect(LogUtils.getLogColor(''), Colors.black);
    });

    test('prefix must be at start — not mid-string', () {
      expect(LogUtils.getLogColor('note: [+] found'), Colors.black);
    });
  });
}
