import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/binaries.dart';
import '../utils/tool_manifest.dart';

/// Lançada quando o sha256 do asset baixado não confere.
class ChecksumMismatchException implements Exception {
  ChecksumMismatchException(this.tool, this.expected, this.actual);
  final String tool;
  final String expected;
  final String actual;
  @override
  String toString() =>
      'Checksum inválido para $tool: esperado $expected, obtido $actual';
}

/// Lançada quando não há asset para a plataforma+arquitetura atual.
class UnsupportedPlatformException implements Exception {
  UnsupportedPlatformException(this.tool, this.abi);
  final String tool;
  final Abi abi;
  @override
  String toString() => 'Ferramenta $tool indisponível para $abi';
}

/// Garante que os binários das ferramentas estejam instalados no disco,
/// baixando-os das releases fixadas no [kToolManifest].
class ToolInstaller {
  ToolInstaller({String? binDirOverride, HttpClient? httpClient})
      : _binDirOverride = binDirOverride,
        _httpClient = httpClient ?? (HttpClient()
          ..connectionTimeout = const Duration(seconds: 30));

  final String? _binDirOverride;
  final HttpClient _httpClient;

  /// Teto de tamanho do download (bytes). Protege contra respostas gigantes ou
  /// penduradas que estourariam a memória (o corpo é acumulado em memória).
  static const int _maxDownloadBytes = 256 * 1024 * 1024;

  /// Tempo máximo total para baixar um asset.
  static const Duration _downloadTimeout = Duration(minutes: 5);

  /// Nome do arquivo do binário instalado (com `.exe` no Windows).
  String _installedName(String tool) =>
      Platform.isWindows ? '$tool.exe' : tool;

  /// Diretório onde os binários ficam, por Abi.
  Future<String> binDir() async {
    if (_binDirOverride != null) return _binDirOverride;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(
      p.join(support.path, 'binaries', Abi.current().toString()),
    );
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  /// Path do binário se já instalado, senão `null`. No Android, as ferramentas
  /// vêm empacotadas no APK (nativeLibraryDir); não há download.
  Future<String?> resolve(String tool) async {
    if (Platform.isAndroid) return androidBundledPath(tool);
    final path = p.join(await binDir(), _installedName(tool));
    return File(path).existsSync() ? path : null;
  }

  /// Ferramentas do manifesto ainda não instaladas. No Android só considera as
  /// empacotáveis: [kAndroidUnsupportedTools] (ex.: gowitness) são ignoradas.
  Future<List<String>> missing() async {
    final result = <String>[];
    for (final tool in kToolManifest.keys) {
      if (Platform.isAndroid && kAndroidUnsupportedTools.contains(tool)) {
        continue;
      }
      if (await resolve(tool) == null) result.add(tool);
    }
    return result;
  }

  /// Baixa e instala [tool]. Lança em erro de rede, checksum ou plataforma.
  Future<String> install(
    String tool, {
    void Function(int received, int total)? onProgress,
  }) async {
    final spec = kToolManifest[tool];
    if (spec == null) throw ArgumentError('Ferramenta desconhecida: $tool');
    final asset = spec.assetForAbi(Abi.current());
    if (asset == null) {
      throw UnsupportedPlatformException(tool, Abi.current());
    }
    final bytes = await _download(spec.downloadUrl(asset), onProgress);
    return installFromBytes(tool, asset, bytes);
  }

  /// Instala [tool] a partir de bytes já em memória. Verifica sha256, extrai
  /// conforme [ToolAsset.type], grava o binário e marca executável.
  ///
  /// Separado de [install] para ser testável sem rede.
  Future<String> installFromBytes(
    String tool,
    ToolAsset asset,
    Uint8List bytes,
  ) async {
    final actual = sha256.convert(bytes).toString();
    if (actual != asset.sha256) {
      throw ChecksumMismatchException(tool, asset.sha256, actual);
    }

    final binary = _extract(asset, bytes);

    final dir = await binDir();
    final destFile = File(p.join(dir, _installedName(tool)));
    await destFile.writeAsBytes(binary, flush: true);

    if (!Platform.isWindows) {
      // runInShell: false — convenção do projeto (sem shell em Process).
      final res =
          await Process.run('chmod', ['+x', destFile.path], runInShell: false);
      if (res.exitCode != 0) {
        throw Exception('chmod falhou para ${destFile.path}: ${res.stderr}');
      }
    }
    return destFile.path;
  }

  /// Extrai o binário dos bytes do asset conforme o tipo.
  List<int> _extract(ToolAsset asset, Uint8List bytes) {
    switch (asset.type) {
      case ArchiveType.raw:
        return bytes;
      case ArchiveType.zip:
        return _fromArchive(ZipDecoder().decodeBytes(bytes), asset);
      case ArchiveType.tarGz:
        final tar = GZipDecoder().decodeBytes(bytes);
        return _fromArchive(TarDecoder().decodeBytes(tar), asset);
    }
  }

  List<int> _fromArchive(Archive archive, ToolAsset asset) {
    final wanted = asset.pathInArchive;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name == wanted || p.basename(file.name) == wanted) {
        return file.content as List<int>;
      }
    }
    throw Exception('Binário "$wanted" não encontrado no arquivo');
  }

  Future<Uint8List> _download(
    String url,
    void Function(int received, int total)? onProgress,
  ) async {
    Future<Uint8List> run() async {
      final request = await _httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode} ao baixar $url');
      }
      final total = response.contentLength;
      if (total > _maxDownloadBytes) {
        throw HttpException(
          'Asset excede o limite de ${_maxDownloadBytes ~/ (1024 * 1024)} MB: $url',
        );
      }
      final builder = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        if (received > _maxDownloadBytes) {
          throw HttpException(
            'Asset excede o limite de ${_maxDownloadBytes ~/ (1024 * 1024)} MB: $url',
          );
        }
        builder.add(chunk);
        onProgress?.call(received, total);
      }
      return builder.toBytes();
    }

    return run().timeout(_downloadTimeout);
  }

  /// Instala todas as ferramentas faltantes. Retorna erros por ferramenta.
  Future<Map<String, Object>> installMissing({
    void Function(String tool, int received, int total)? onProgress,
  }) async {
    final errors = <String, Object>{};
    for (final tool in await missing()) {
      try {
        await install(
          tool,
          onProgress: (r, t) => onProgress?.call(tool, r, t),
        );
      } catch (e) {
        errors[tool] = e;
      }
    }
    return errors;
  }

  /// Re-baixa todas as ferramentas (usado pelo botão "Atualizar"). No Android
  /// não há o que baixar: as ferramentas vêm empacotadas no APK.
  Future<Map<String, Object>> installAll({
    void Function(String tool, int received, int total)? onProgress,
  }) async {
    if (Platform.isAndroid) return {};
    final errors = <String, Object>{};
    for (final tool in kToolManifest.keys) {
      try {
        await install(
          tool,
          onProgress: (r, t) => onProgress?.call(tool, r, t),
        );
      } catch (e) {
        errors[tool] = e;
      }
    }
    return errors;
  }

  /// Injeta o diretório resolvido em `binaries.dart` (chamar no startup).
  Future<void> registerBinDir() async => setDownloadedBinDir(await binDir());
}
