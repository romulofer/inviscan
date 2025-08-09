import 'dart:io';
import 'package:path/path.dart' as p;

String _platformDir() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  return 'linux';
}

String _ext() => Platform.isWindows ? '.exe' : '';

String binPath(String baseName) {
  final binariesRoot = p.join(
    Directory.current.path,
    'binaries',
    _platformDir(),
  );
  final fileName =
      baseName.endsWith('.sh') ||
              baseName.endsWith('.bat') ||
              baseName.endsWith('.py')
          ? baseName
          : '$baseName${_ext()}';
  return p.join(binariesRoot, fileName);
}
