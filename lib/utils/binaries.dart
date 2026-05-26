import 'dart:io';
import 'package:path/path.dart' as p;

String _platformDir() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  return 'linux';
}

String _ext() => Platform.isWindows ? '.exe' : '';

/// Returns the path to a bundled binary, falling back to the bare name so the
/// OS can resolve it from PATH when the binary is not bundled.
String binPath(String baseName) {
  // Scripts keep their own extension; executables get the platform suffix.
  final hasOwnExt =
      baseName.endsWith('.sh') ||
      baseName.endsWith('.bat') ||
      baseName.endsWith('.py');
  final fileName = hasOwnExt ? baseName : '$baseName${_ext()}';

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
