import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/juicy_targets.dart';

void main() {
  group('identifyJuicyTargets', () {
    test('returns empty for empty input', () {
      expect(identifyJuicyTargets([]), isEmpty);
    });

    test('identifies known high-value terms', () {
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
          reason: '$url should be juicy',
        );
      }
    });

    test('ignores non-juicy urls', () {
      final clean = [
        'https://www.example.com',
        'https://about.example.com',
        'https://shop.example.com',
        'https://news.example.com',
      ];
      expect(identifyJuicyTargets(clean), isEmpty);
    });

    test('matching is case-insensitive', () {
      expect(identifyJuicyTargets(['https://ADMIN.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://Admin.example.com']), isNotEmpty);
      expect(identifyJuicyTargets(['https://aDmIn.example.com']), isNotEmpty);
    });

    test('preserves the original url string unchanged', () {
      const url = 'https://dev.example.com';
      expect(identifyJuicyTargets([url]).first, url);
    });

    test('filters correctly in a mixed list', () {
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

    test('does not deduplicate — same url twice yields two entries', () {
      const url = 'https://admin.example.com';
      expect(identifyJuicyTargets([url, url]).length, 2);
    });
  });
}
