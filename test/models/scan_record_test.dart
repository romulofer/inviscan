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
    test('inclui todos os campos', () {
      final m = full.toMap();
      expect(m['id'], 'abc-123');
      expect(m['domain'], 'example.com');
      expect(m['startedAt'], start.toIso8601String());
      expect(m['finishedAt'], finish.toIso8601String());
      expect(m['subdomainsFound'], 42);
      expect(m['status'], 'success');
      expect(m['outputDir'], '/tmp/scan');
    });

    test('campos anuláveis serializam como null', () {
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
    test('faz round-trip de todos os campos', () {
      final r = ScanRecord.fromMap(full.toMap());
      expect(r.id, full.id);
      expect(r.domain, full.domain);
      expect(r.startedAt, full.startedAt);
      expect(r.finishedAt, full.finishedAt);
      expect(r.subdomainsFound, full.subdomainsFound);
      expect(r.status, full.status);
      expect(r.outputDir, full.outputDir);
    });

    test('campos anuláveis sobrevivem ao round-trip com null', () {
      final r = ScanRecord.fromMap(full.toMap()
        ..['finishedAt'] = null
        ..['outputDir'] = null);
      expect(r.finishedAt, isNull);
      expect(r.outputDir, isNull);
    });

    test('status ausente assume "success" por padrão', () {
      final m = full.toMap()..remove('status');
      expect(ScanRecord.fromMap(m).status, 'success');
    });

    test('subdomainsFound ausente assume 0 por padrão', () {
      final m = full.toMap()..remove('subdomainsFound');
      expect(ScanRecord.fromMap(m).subdomainsFound, 0);
    });
  });

  group('ScanRecord.listFromJson / listToJson', () {
    test('faz round-trip de uma lista de registros', () {
      final json = ScanRecord.listToJson([full, full]);
      final decoded = ScanRecord.listFromJson(json);
      expect(decoded.length, 2);
      expect(decoded.first.id, full.id);
    });

    test('string vazia retorna lista vazia', () {
      expect(ScanRecord.listFromJson(''), isEmpty);
    });

    test('string só com espaços retorna lista vazia', () {
      expect(ScanRecord.listFromJson('   '), isEmpty);
    });

    test('array JSON vazio retorna lista vazia', () {
      expect(ScanRecord.listFromJson('[]'), isEmpty);
    });

    test('listToJson de lista vazia produz array vazio válido', () {
      expect(ScanRecord.listFromJson(ScanRecord.listToJson([])), isEmpty);
    });
  });
}
