import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan_record.dart';

class ScanHistoryRepository {
  static const _fileName = 'scan_history.json';

  Future<File> _historyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
    }
    return file;
  }

  Future<List<ScanRecord>> getAll() async {
    final file = await _historyFile();
    final content = await file.readAsString();
    return ScanRecord.listFromJson(content);
  }

  Future<void> saveAll(List<ScanRecord> items) async {
    final file = await _historyFile();
    await file.writeAsString(ScanRecord.listToJson(items));
  }

  Future<void> append(ScanRecord record) async {
    final list = await getAll();
    list.insert(0, record);
    await saveAll(list);
  }

  Future<void> removeById(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  Future<void> clear() async {
    final file = await _historyFile();
    await file.writeAsString('[]');
  }
}
