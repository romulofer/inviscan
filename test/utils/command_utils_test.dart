import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/binaries.dart';
import 'package:inviscan/utils/command_utils.dart';

void main() {
  group('tokenizeCommand', () {
    test('separa por espaços simples', () {
      expect(
        tokenizeCommand('ffuf -w list.txt -mc 200'),
        ['ffuf', '-w', 'list.txt', '-mc', '200'],
      );
    });

    test('preserva argumento entre aspas duplas com espaços', () {
      expect(
        tokenizeCommand('ffuf -w "my wordlist.txt" -mc 200'),
        ['ffuf', '-w', 'my wordlist.txt', '-mc', '200'],
      );
    });

    test('preserva argumento entre aspas simples com espaços', () {
      expect(
        tokenizeCommand("cmd -o 'out dir/file.json'"),
        ['cmd', '-o', 'out dir/file.json'],
      );
    });

    test('aspas simples dentro de aspas duplas são literais', () {
      expect(
        tokenizeCommand('cmd "it\'s here"'),
        ['cmd', "it's here"],
      );
    });

    test('aspas duplas dentro de aspas simples são literais', () {
      expect(
        tokenizeCommand("cmd 'a\"b'"),
        ['cmd', 'a"b'],
      );
    });

    test('colapsa múltiplos espaços consecutivos', () {
      expect(tokenizeCommand('a    b   c'), ['a', 'b', 'c']);
    });

    test('string vazia retorna lista vazia', () {
      expect(tokenizeCommand(''), isEmpty);
    });

    test('string só com espaços retorna lista vazia', () {
      expect(tokenizeCommand('     '), isEmpty);
    });

    test('concatena segmentos entre aspas colados sem espaço', () {
      // -w"a b" vira um único token "-wa b" (aspas removidas, sem separador).
      expect(tokenizeCommand('-w"a b"'), ['-wa b']);
    });
  });

  group('resolveExec', () {
    tearDown(() => setDownloadedBinDir(null));

    test('token contendo o nome da tool resolve via binPath', () {
      setDownloadedBinDir('/inexistente');
      final expected = Platform.isWindows ? 'ffuf.exe' : 'ffuf';
      expect(resolveExec('ffuf', 'ffuf'), expected);
    });

    test('match é case-insensitive', () {
      setDownloadedBinDir('/inexistente');
      final expected = Platform.isWindows ? 'ffuf.exe' : 'ffuf';
      expect(resolveExec('FFUF', 'ffuf'), expected);
    });

    test('token com sufixo .exe ainda casa o nome da tool', () {
      setDownloadedBinDir('/inexistente');
      final expected = Platform.isWindows ? 'ffuf.exe' : 'ffuf';
      expect(resolveExec('ffuf.exe', 'ffuf'), expected);
    });

    test('token diferente é usado como veio (executável customizado)', () {
      expect(resolveExec('/opt/custom/scanner', 'ffuf'), '/opt/custom/scanner');
    });
  });
}
