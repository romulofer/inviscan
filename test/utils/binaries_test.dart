import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/binaries.dart';
import 'package:path/path.dart' as p;

void main() {
  tearDown(() => setDownloadedBinDir(null));

  test('binPath usa o diretório baixado quando o binário existe lá', () async {
    final dir = await Directory.systemTemp.createTemp('inviscan_bin');
    addTearDown(() => dir.delete(recursive: true));
    final name = Platform.isWindows ? 'assetfinder.exe' : 'assetfinder';
    await File(p.join(dir.path, name)).writeAsString('x');

    setDownloadedBinDir(dir.path);

    expect(binPath('assetfinder'), p.join(dir.path, name));
  });

  test('binPath cai no nome puro quando não há binário em lugar nenhum', () {
    setDownloadedBinDir('/definitivamente/inexistente');
    final name = Platform.isWindows ? 'assetfinder.exe' : 'assetfinder';
    expect(binPath('assetfinder'), name);
  });
}
