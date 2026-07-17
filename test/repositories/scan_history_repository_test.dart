import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:inviscan/models/scan_record.dart';
import 'package:inviscan/repositories/scan_history_repository.dart';

class _MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _MockPathProvider(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

ScanRecord _record(String id, {String domain = 'example.com'}) => ScanRecord(
      id: id,
      domain: domain,
      startedAt: DateTime(2025),
      subdomainsFound: 0,
      status: 'success',
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inviscan_repo_test_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ScanHistoryRepository', () {
    test('getAll retorna lista vazia num repositório novo', () async {
      expect(await ScanHistoryRepository().getAll(), isEmpty);
    });

    test('append armazena um registro', () async {
      final repo = ScanHistoryRepository();
      await repo.append(_record('1'));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, '1');
    });

    test('append insere o registro mais novo no índice 0', () async {
      final repo = ScanHistoryRepository();
      await repo.append(_record('first'));
      await repo.append(_record('second'));
      final all = await repo.getAll();
      expect(all[0].id, 'second');
      expect(all[1].id, 'first');
    });

    test('saveAll persiste todos os campos corretamente', () async {
      final repo = ScanHistoryRepository();
      final r = ScanRecord(
        id: 'full',
        domain: 'test.com',
        startedAt: DateTime(2025, 1, 1),
        finishedAt: DateTime(2025, 1, 1, 0, 5),
        subdomainsFound: 7,
        status: 'success',
        outputDir: '/tmp/out',
      );
      await repo.saveAll([r]);
      final loaded = (await repo.getAll()).first;
      expect(loaded.domain, 'test.com');
      expect(loaded.subdomainsFound, 7);
      expect(loaded.finishedAt, r.finishedAt);
      expect(loaded.outputDir, '/tmp/out');
    });

    test('removeById remove apenas o registro correspondente', () async {
      final repo = ScanHistoryRepository();
      await repo.append(_record('keep'));
      await repo.append(_record('drop'));
      await repo.removeById('drop');
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'keep');
    });

    test('removeById não faz nada para um id desconhecido', () async {
      final repo = ScanHistoryRepository();
      await repo.append(_record('a'));
      await repo.removeById('nonexistent');
      expect((await repo.getAll()).length, 1);
    });

    test('clear remove todos os registros', () async {
      final repo = ScanHistoryRepository();
      await repo.append(_record('1'));
      await repo.append(_record('2'));
      await repo.clear();
      expect(await repo.getAll(), isEmpty);
    });

    test('revision incrementa no append', () async {
      final repo = ScanHistoryRepository();
      final before = ScanHistoryRepository.revision.value;
      await repo.append(_record('x'));
      expect(ScanHistoryRepository.revision.value, before + 1);
    });

    test('revision incrementa no saveAll', () async {
      final repo = ScanHistoryRepository();
      final before = ScanHistoryRepository.revision.value;
      await repo.saveAll([]);
      expect(ScanHistoryRepository.revision.value, before + 1);
    });

    test('revision incrementa no clear', () async {
      final repo = ScanHistoryRepository();
      final before = ScanHistoryRepository.revision.value;
      await repo.clear();
      expect(ScanHistoryRepository.revision.value, before + 1);
    });

    test('dados persistem entre instâncias separadas do repositório', () async {
      await ScanHistoryRepository().append(_record('persist'));
      final loaded = await ScanHistoryRepository().getAll();
      expect(loaded.first.id, 'persist');
    });
  });
}
