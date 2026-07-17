import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/input_validation.dart';

void main() {
  group('validateAndNormalizeDomain', () {
    test('remove esquema, caminho, query, fragmento e porta', () {
      expect(
        validateAndNormalizeDomain('https://example.com/path?q=1#frag'),
        'example.com',
      );
      expect(validateAndNormalizeDomain('http://sub.example.com:8080'),
          'sub.example.com');
    });

    test('converte para minúsculas e apara espaços', () {
      expect(validateAndNormalizeDomain('  EXAMPLE.COM  '), 'example.com');
    });

    test('aceita domínios válidos com múltiplos rótulos', () {
      expect(validateAndNormalizeDomain('a.b.example.co.uk'), 'a.b.example.co.uk');
    });

    test('rejeita entrada vazia', () {
      expect(() => validateAndNormalizeDomain('   '), throwsArgumentError);
    });

    test('rejeita payloads de injeção de argumento', () {
      // Vetor real: interpolado no comando do ffuf e tokenizado por espaço.
      expect(() => validateAndNormalizeDomain('evil.com -X POST'),
          throwsArgumentError);
      expect(() => validateAndNormalizeDomain('evil.com;rm -rf'),
          throwsArgumentError);
      expect(() => validateAndNormalizeDomain('evil.com"foo'),
          throwsArgumentError);
    });

    test('rejeita hostnames sem TLD', () {
      expect(() => validateAndNormalizeDomain('localhost'), throwsArgumentError);
    });

    test('rejeita domínios longos demais', () {
      final long = '${'a' * 250}.com';
      expect(() => validateAndNormalizeDomain(long), throwsArgumentError);
    });
  });
}
