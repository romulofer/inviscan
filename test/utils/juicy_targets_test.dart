import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/juicy_targets.dart';

void main() {
  group('identifyJuicyTargets', () {
    test('retorna vazio para entrada vazia', () {
      expect(identifyJuicyTargets([]), isEmpty);
    });

    test('identifica termos de alto valor conhecidos', () {
      final hits = {
        'https://admin.example.com',
        'https://api.example.com',
        'https://dev.example.com',
        'https://staging.example.com',
        'https://jenkins.example.com',
        'https://vpn.example.com',
        'https://grafana.example.com',
        'https://backup.example.com',
      };
      for (final url in hits) {
        expect(
          identifyJuicyTargets([url]),
          isNotEmpty,
          reason: '$url deveria ser suculento',
        );
      }
    });

    test('ignora urls não suculentas', () {
      final clean = [
        'https://www.example.com',
        'https://about.example.com',
        'https://shop.example.com',
        'https://news.example.com',
      ];
      expect(identifyJuicyTargets(clean), isEmpty);
    });

    test('correspondência ignora maiúsculas/minúsculas', () {
      expect(identifyJuicyTargets(['https://ADMIN.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://Admin.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://aDmIn.example.com']), isNotEmpty);
    });

    test('preserva a string original da url inalterada', () {
      const url = 'https://dev.example.com';
      expect(identifyJuicyTargets([url]).first, url);
    });

    test('filtra corretamente em uma lista mista', () {
      final result = identifyJuicyTargets([
        'https://admin.example.com',
        'https://www.example.com',
        'https://jenkins.ci.example.com',
        'https://shop.example.com',
      ]);
      expect(result, contains('https://admin.example.com'));
      expect(result, contains('https://jenkins.ci.example.com'));
      expect(result, isNot(contains('https://www.example.com')));
      expect(result, isNot(contains('https://shop.example.com')));
    });

    test('não deduplica — a mesma url duas vezes gera duas entradas', () {
      const url = 'https://admin.example.com';
      expect(identifyJuicyTargets([url, url]).length, 2);
    });

    test('não casa termos embutidos dentro de uma palavra maior', () {
      // "api" em "rapidshare", "old" em "gold", "ci" em "social",
      // "db" em "adblock" — antes casavam por substring.
      final falsePositives = [
        'https://rapidshare.example.com',
        'https://gold.example.com',
        'https://social.example.com',
        'https://adblock.example.com',
      ];
      expect(identifyJuicyTargets(falsePositives), isEmpty);
    });

    test('casa termos delimitados por ponto ou hífen', () {
      expect(identifyJuicyTargets(['https://api.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://api-gateway.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://backup-old.example.com']), isNotEmpty);
    });
  });
}
