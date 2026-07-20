import 'dart:io';

/// Resolves a usable Chrome/Chromium binary for gowitness.
///
/// Resolution order:
///   1. [configuredPath] set by the user in Settings (if it exists on disk).
///   2. Auto-detected Google Chrome / Chromium in the platform's common
///      install locations.
///   3. Microsoft Edge as a last resort (present on every Windows 10/11 host).
///
/// Returns the first path that exists, or `null` when no local browser was
/// found — in which case the caller should skip the screenshot step.
String? resolveBrowserPath([String? configuredPath]) {
  final configured = configuredPath?.trim();
  if (configured != null && configured.isNotEmpty) {
    if (File(configured).existsSync()) return configured;
  }

  for (final candidate in _chromeCandidates()) {
    if (candidate.isNotEmpty && File(candidate).existsSync()) return candidate;
  }
  for (final candidate in _edgeCandidates()) {
    if (candidate.isNotEmpty && File(candidate).existsSync()) return candidate;
  }
  return null;
}

List<String> _chromeCandidates() {
  final env = Platform.environment;
  if (Platform.isWindows) {
    final programFiles = env['ProgramFiles'] ?? r'C:\Program Files';
    final programFilesX86 =
        env['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
    final localAppData = env['LOCALAPPDATA'] ?? '';
    return [
      '$programFiles\\Google\\Chrome\\Application\\chrome.exe',
      '$programFilesX86\\Google\\Chrome\\Application\\chrome.exe',
      if (localAppData.isNotEmpty)
        '$localAppData\\Google\\Chrome\\Application\\chrome.exe',
    ];
  }
  if (Platform.isMacOS) {
    return [
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Chromium.app/Contents/MacOS/Chromium',
    ];
  }
  // Linux and other POSIX.
  return [
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/opt/google/chrome/chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/snap/bin/chromium',
  ];
}

List<String> _edgeCandidates() {
  final env = Platform.environment;
  if (Platform.isWindows) {
    final programFiles = env['ProgramFiles'] ?? r'C:\Program Files';
    final programFilesX86 =
        env['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
    return [
      '$programFilesX86\\Microsoft\\Edge\\Application\\msedge.exe',
      '$programFiles\\Microsoft\\Edge\\Application\\msedge.exe',
    ];
  }
  if (Platform.isMacOS) {
    return [
      '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    ];
  }
  return [
    '/usr/bin/microsoft-edge',
    '/usr/bin/microsoft-edge-stable',
  ];
}
