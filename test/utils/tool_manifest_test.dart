import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/utils/tool_manifest.dart';

void main() {
  test('manifesto cobre as cinco ferramentas', () {
    expect(
      kToolManifest.keys.toSet(),
      {'subfinder', 'assetfinder', 'ffuf', 'httprobe', 'gowitness'},
    );
  });

  test('assetForAbi retorna asset de linuxX64 para subfinder', () {
    final asset = kToolManifest['subfinder']!.assetForAbi(Abi.linuxX64);
    expect(asset, isNotNull);
    expect(asset!.fileName, 'subfinder_2.16.0_linux_amd64.zip');
    expect(asset.type, ArchiveType.zip);
    expect(asset.sha256.length, 64);
  });

  test('gowitness é raw (sem pathInArchive)', () {
    final asset = kToolManifest['gowitness']!.assetForAbi(Abi.linuxX64);
    expect(asset!.type, ArchiveType.raw);
    expect(asset.pathInArchive, isNull);
  });

  test('assetfinder não tem asset para linuxArm64', () {
    expect(
      kToolManifest['assetfinder']!.assetForAbi(Abi.linuxArm64),
      isNull,
    );
  });

  test('downloadUrl monta URL direta da release', () {
    final spec = kToolManifest['ffuf']!;
    final asset = spec.assetForAbi(Abi.linuxX64)!;
    expect(
      spec.downloadUrl(asset),
      'https://github.com/ffuf/ffuf/releases/download/v2.2.1/ffuf_2.2.1_linux_amd64.tar.gz',
    );
  });

  test('asset android usa repo/tag override no downloadUrl', () {
    final spec = kToolManifest['subfinder']!;
    final asset = spec.assetForAbi(Abi.androidArm64)!;
    expect(asset.type, ArchiveType.raw);
    expect(asset.repo, 'romulofer/inviscan');
    expect(
      spec.downloadUrl(asset),
      'https://github.com/romulofer/inviscan/releases/download/v1.0.0/subfinder-android-arm64',
    );
  });

  test('gowitness não tem asset android', () {
    expect(kToolManifest['gowitness']!.assetForAbi(Abi.androidArm64), isNull);
  });
}
