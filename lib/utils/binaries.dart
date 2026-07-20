import 'dart:io';
import 'package:path/path.dart' as p;

String _platformDir() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  return 'linux';
}

String _ext() => Platform.isWindows ? '.exe' : '';

/// Diretório dos binários baixados em runtime. Resolvido de forma assíncrona no
/// startup (ver `main`) e injetado aqui porque [binPath] é síncrono.
String? _downloadedBinDir;

/// Define o diretório dos binários baixados. `null` limpa (usado em testes).
void setDownloadedBinDir(String? path) => _downloadedBinDir = path;

/// Returns the path to a bundled binary, falling back to the bare name so the
/// OS can resolve it from PATH when the binary is not bundled.
String binPath(String baseName) {
  // Scripts keep their own extension; executables get the platform suffix.
  final hasOwnExt =
      baseName.endsWith('.sh') ||
      baseName.endsWith('.bat') ||
      baseName.endsWith('.py');
  final fileName = hasOwnExt ? baseName : '$baseName${_ext()}';

  // Prioridade máxima: binário baixado em runtime para a plataforma+arch atual.
  final downloadedDir = _downloadedBinDir;
  if (downloadedDir != null) {
    final downloaded = File(p.join(downloadedDir, fileName));
    if (downloaded.existsSync()) return downloaded.path;
  }

  // Prefer the binary bundled next to the executable (portable distribution).
  final executableDir = File(Platform.resolvedExecutable).parent.path;
  final bundledInExecDir =
      File(p.join(executableDir, 'binaries', _platformDir(), fileName));
  if (bundledInExecDir.existsSync()) return bundledInExecDir.path;

  // Also check relative to the working directory (development / debug runs).
  final bundledInCwd = File(
    p.join(Directory.current.path, 'binaries', _platformDir(), fileName),
  );
  if (bundledInCwd.existsSync()) return bundledInCwd.path;

  // Fall back to the bare name so the OS resolves it from PATH.
  return hasOwnExt ? baseName : '$baseName${_ext()}';
}
