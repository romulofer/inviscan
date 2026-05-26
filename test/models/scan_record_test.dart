import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/models/scan_record.dart';

void main() {
  final start = DateTime(2025, 6, 1, 12, 0, 0);
  final finish = DateTime(2025, 6, 1, 12, 5, 0);

  final full = ScanRecord(
    id: 'abc-123',
    domain: 'example.com',
    startedAt: start,
    finishedAt: finish,
    subdomainsFound: 42,
    status: 'success',
    outputDir: '/tmp/scan',
  );

  group('ScanRecord.toMap', () {
    test('includes all fields', () {
      final m = full.toMap();
      expect(m['id'], 'abc-123');
      expect(m['domain'], 'example.com');
      expect(m['startedAt'], start.toIso8601String());
      expect(m['finishedAt'], finish.toIso8601String());
      expect(m['subdomainsFound'], 42);
      expect(m['status'], 'success');
      expect(m['outputDir'], '/tmp/scan');
    });

    test('nullable fields serialise as null', () {
      final r = ScanRecord(
        id: 'x',
        domain: 'a.com',
        startedAt: start,
        subdomainsFound: 0,
        status: 'running',
      );
      final m = r.toMap();
      expect(m['finishedAt'], isNull);
      expect(m['outputDir'], isNull);
    });
  });

  group('ScanRecord.fromMap', () {
    test('round-trips all fields', () {
      final r = ScanRecord.fromMap(full.toMap());
      expect(r.id, full.id);
      expect(r.domain, full.domain);
      expect(r.startedAt, full.startedAt);
      expect(r.finishedAt, full.finishedAt);
      expect(r.subdomainsFound, full.subdomainsFound);
      expect(r.status, full.status);
      expect(r.outputDir, full.outputDir);
    });

    test('nullable fields survive null round-trip', () {
      final r = ScanRecord.fromMap(full.toMap()
        ..['finishedAt'] = null
        ..['outputDir'] = null);
      expect(r.finishedAt, isNull);
      expect(r.outputDir, isNull);
    });

    test('missing status defaults to "success"', () {
      final m = full.toMap()..remove('status');
      expect(ScanRecord.fromMap(m).status, 'success');
    });

    test('missing subdomainsFound defaults to 0', () {
      final m = full.toMap()..remove('subdomainsFound');
      expect(ScanRecord.fromMap(m).subdomainsFound, 0);
    });
  });

  group('ScanRecord.listFromJson / listToJson', () {
    test('round-trips a list of records', () {
      final json = ScanRecord.listToJson([full, full]);
      final decoded = ScanRecord.listFromJson(json);
      expect(decoded.length, 2);
      expect(decoded.first.id, full.id);
    });

    test('empty string returns empty list', () {
      expect(ScanRecord.listFromJson(''), isEmpty);
    });

    test('whitespace-only string returns empty list', () {
      expect(ScanRecord.listFromJson('   '), isEmpty);
    });

    test('empty JSON array returns empty list', () {
      expect(ScanRecord.listFromJson('[]'), isEmpty);
    });

    test('listToJson of empty list produces valid empty array', () {
      expect(ScanRecord.listFromJson(ScanRecord.listToJson([])), isEmpty);
    });
  });
}
