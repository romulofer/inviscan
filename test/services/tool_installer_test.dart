import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/services/tool_installer.dart';
import 'package:inviscan/utils/tool_manifest.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dest;
  late ToolInstaller installer;

  setUp(() async {
    dest = await Directory.systemTemp.createTemp('inviscan_install');
    installer = ToolInstaller(binDirOverride: dest.path);
  });
  tearDown(() => dest.delete(recursive: true));

  Uint8List tarGzWith(String name, List<int> body) {
    final archive = Archive()
      ..addFile(ArchiveFile(name, body.length, body));
    final tar = TarEncoder().encode(archive);
    return Uint8List.fromList(GZipEncoder().encode(tar));
  }

  test('raw: grava bytes verificados e retorna path do binário', () async {
    final body = Uint8List.fromList('BINARY'.codeUnits);
    final asset = ToolAsset(
      fileName: 'x-raw',
      type: ArchiveType.raw,
      sha256: sha256.convert(body).toString(),
    );

    final path = await installer.installFromBytes('mytool', asset, body);

    expect(File(path).existsSync(), isTrue);
    expect(await File(path).readAsBytes(), body);
    expect(p.basename(path), 'mytool');
  });

  test('tarGz: extrai pathInArchive e grava com o nome da ferramenta', () async {
    final body = Uint8List.fromList('TOOLBODY'.codeUnits);
    final bytes = tarGzWith('assetfinder', body);
    final asset = ToolAsset(
      fileName: 'a.tgz',
      type: ArchiveType.tarGz,
      pathInArchive: 'assetfinder',
      sha256: sha256.convert(bytes).toString(),
    );

    final path = await installer.installFromBytes('assetfinder', asset, bytes);

    expect(await File(path).readAsBytes(), body);
    expect(p.basename(path), 'assetfinder');
  });

  test('sha256 divergente aborta e não grava binário', () async {
    final body = Uint8List.fromList('BINARY'.codeUnits);
    final asset = ToolAsset(
      fileName: 'x-raw',
      type: ArchiveType.raw,
      sha256: 'deadbeef',
    );

    expect(
      () => installer.installFromBytes('mytool', asset, body),
      throwsA(isA<ChecksumMismatchException>()),
    );
    expect(Directory(dest.path).listSync().isEmpty, isTrue);
  });
}
