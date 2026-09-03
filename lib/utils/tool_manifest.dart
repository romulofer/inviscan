import 'dart:ffi';

/// Formato do asset publicado na release.
enum ArchiveType { tarGz, zip, raw }

/// Um asset específico para uma combinação plataforma+arquitetura.
class ToolAsset {
  const ToolAsset({
    required this.fileName,
    required this.type,
    required this.sha256,
    this.pathInArchive,
    this.repo,
    this.tag,
  });

  /// Nome do arquivo na release (usado para montar a URL de download).
  final String fileName;

  /// Como descompactar. [ArchiveType.raw] = o próprio asset já é o binário.
  final ArchiveType type;

  /// sha256 esperado do asset baixado (hex minúsculo, 64 chars).
  final String sha256;

  /// Caminho do binário dentro do arquivo. Nulo quando [type] é raw.
  final String? pathInArchive;

  /// Sobrescreve o `owner/name` do [ToolSpec]. Usado quando o asset é hospedado
  /// num repositório diferente do upstream (ex.: binários android compilados por
  /// nós e publicados no release do InviScan).
  final String? repo;

  /// Sobrescreve a tag do [ToolSpec]. Ver [repo].
  final String? tag;
}

/// Especificação de download de uma ferramenta, com versão fixada.
class ToolSpec {
  const ToolSpec({
    required this.repo,
    required this.tag,
    required this.assets,
  });

  /// `owner/name` no GitHub.
  final String repo;

  /// Tag da release fixada (ex.: `v2.16.0`).
  final String tag;

  /// Asset por Abi. Abis ausentes = ferramenta indisponível naquela plataforma.
  final Map<Abi, ToolAsset> assets;

  ToolAsset? assetForAbi(Abi abi) => assets[abi];

  String downloadUrl(ToolAsset asset) {
    final r = asset.repo ?? repo;
    final t = asset.tag ?? tag;
    return 'https://github.com/$r/releases/download/$t/${asset.fileName}';
  }
}

/// Ferramentas sem suporte no Android. No Android as ferramentas são
/// empacotadas no APK (jniLibs), não baixadas; gowitness fica de fora por
/// depender de Chrome headless.
const Set<String> kAndroidUnsupportedTools = {'gowitness'};

/// Repositório que hospeda os binários android compilados por nós.
const String _androidHostRepo = 'romulofer/inviscan';

/// Tag do release do InviScan que hospeda os binários android.
const String _androidHostTag = 'v1.0.0';

/// Versões fixadas verificadas contra o GitHub em 2026-09-03.
///
/// Notas de arquitetura:
/// - assetfinder v0.1.1 e httprobe v0.2 não publicam builds arm64; macOS arm64
///   usa o binário darwin amd64 (requer Rosetta em Apple Silicon) e linux arm64
///   fica sem asset.
/// - Nenhuma das ferramentas publica build android upstream. Os assets
///   `Abi.androidArm64` são compilados por nós (NDK, bionic PIE) e hospedados no
///   release do InviScan ([_androidHostRepo]@[_androidHostTag]). gowitness fica
///   de fora do android (depende de Chrome headless).
const Map<String, ToolSpec> kToolManifest = {
  'subfinder': ToolSpec(
    repo: 'projectdiscovery/subfinder',
    tag: 'v2.16.0',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'subfinder_2.16.0_linux_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: '1b7f9c608e9a5bd59e609a5e09710d63c5485e92d3d49dc2c16eb4fdbe10cb60',
      ),
      Abi.linuxArm64: ToolAsset(
        fileName: 'subfinder_2.16.0_linux_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: 'c81d49559c0f630177be9e347e502e7a3d474aacc6ff78291ffcb4964367d63d',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'subfinder_2.16.0_macOS_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: '8300c4d98f75596b7e8460ba6f3322dfeda4674bc2bcbde14d61d098db260b50',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'subfinder_2.16.0_macOS_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: 'af55827c9e6cdc530cca377ad459214ead16daf1b79d90e3dcefa387f644e057',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'subfinder_2.16.0_windows_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder.exe',
        sha256: 'ef760f0a064c22811100c75a61da35ba73d71398cb99ae85d32d0eed44496ab8',
      ),
      Abi.windowsArm64: ToolAsset(
        fileName: 'subfinder_2.16.0_windows_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder.exe',
        sha256: '442ab5a802953035767cddafc05a988df9625249e5695af9ee3a4d731c7ff60b',
      ),
      Abi.androidArm64: ToolAsset(
        fileName: 'subfinder-android-arm64',
        type: ArchiveType.raw,
        sha256: '5913e1dc07655bd03b8b169bea9a4da96086c8261d6b2c3e3b8a2edf33904145',
        repo: _androidHostRepo,
        tag: _androidHostTag,
      ),
    },
  ),
  'assetfinder': ToolSpec(
    repo: 'tomnomnom/assetfinder',
    tag: 'v0.1.1',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'assetfinder-linux-amd64-0.1.1.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'assetfinder',
        sha256: 'a7c61fe7b8ac16b35b94c1967dfabe0a536efd04283a3764226b30ff75472b20',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'assetfinder-darwin-amd64-0.1.1.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'assetfinder',
        sha256: '881279aa0edbd2983c2b8dc55e761afd871f19137e552c371adbc4624cf0effc',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'assetfinder-darwin-amd64-0.1.1.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'assetfinder',
        sha256: '881279aa0edbd2983c2b8dc55e761afd871f19137e552c371adbc4624cf0effc',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'assetfinder-windows-amd64-0.1.1.zip',
        type: ArchiveType.zip,
        pathInArchive: 'assetfinder.exe',
        sha256: '39ce07c5e86995af83ddc36ed6bd4f7d2bf40497a85cc08ed8b94a6cad566cd3',
      ),
      Abi.androidArm64: ToolAsset(
        fileName: 'assetfinder-android-arm64',
        type: ArchiveType.raw,
        sha256: '75089f645ba46997c26e8ec7c95077565af8c1d42a7678255218d0f0472afa73',
        repo: _androidHostRepo,
        tag: _androidHostTag,
      ),
    },
  ),
  'ffuf': ToolSpec(
    repo: 'ffuf/ffuf',
    tag: 'v2.2.1',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'ffuf_2.2.1_linux_amd64.tar.gz',
        type: ArchiveType.tarGz,
        pathInArchive: 'ffuf',
        sha256: '86307885810d3c36ba4a3e9ba5178c2d9027bba0dd7f4ea39e39e7c972b62396',
      ),
      Abi.linuxArm64: ToolAsset(
        fileName: 'ffuf_2.2.1_linux_arm64.tar.gz',
        type: ArchiveType.tarGz,
        pathInArchive: 'ffuf',
        sha256: '89ad4f50345e6a9a48ecc8d241811d582cedf96279276b48d666b12b31260484',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'ffuf_2.2.1_macOS_amd64.tar.gz',
        type: ArchiveType.tarGz,
        pathInArchive: 'ffuf',
        sha256: 'ad3c0a141c78213a78ce71a8cd0f2d140d9d9785b9cd44b8fac0d206d65dbb75',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'ffuf_2.2.1_macOS_arm64.tar.gz',
        type: ArchiveType.tarGz,
        pathInArchive: 'ffuf',
        sha256: 'b0e9c14a8083fa2e2b52a9a4e004dc132c61347fcda9b4c714fb275ed47c18db',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'ffuf_2.2.1_windows_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'ffuf.exe',
        sha256: '717e3d103ee36ce743a18605be66a4424fca27758eebed1e8ebb2eb0a3645589',
      ),
      Abi.windowsArm64: ToolAsset(
        fileName: 'ffuf_2.2.1_windows_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'ffuf.exe',
        sha256: 'a1a4e9005143e11c8a79f6ae0d0b24b67e54209b8b4f4736399211ebbc7a0b71',
      ),
      Abi.androidArm64: ToolAsset(
        fileName: 'ffuf-android-arm64',
        type: ArchiveType.raw,
        sha256: '870d5d247fe3a8d4422eaf7c9eada5399eb0a367a543f07464b7e24c5aeae3a8',
        repo: _androidHostRepo,
        tag: _androidHostTag,
      ),
    },
  ),
  'httprobe': ToolSpec(
    repo: 'tomnomnom/httprobe',
    tag: 'v0.2',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'httprobe-linux-amd64-0.2.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'httprobe',
        sha256: '4a43ae3cb355c698b811f4ddf1da117ad215984a1187997deb41f89a5c5fff40',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'httprobe-darwin-amd64-0.2.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'httprobe',
        sha256: '316369f0d109aa086eb1a9c9ac4bf17e1a7e53118a5774eb88a2872b8946276a',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'httprobe-darwin-amd64-0.2.tgz',
        type: ArchiveType.tarGz,
        pathInArchive: 'httprobe',
        sha256: '316369f0d109aa086eb1a9c9ac4bf17e1a7e53118a5774eb88a2872b8946276a',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'httprobe-windows-amd64-0.2.zip',
        type: ArchiveType.zip,
        pathInArchive: 'httprobe.exe',
        sha256: 'f16baf121e6ac00584eb740da2e8179590ca9beb8970c4e3374224405c6b5989',
      ),
      Abi.androidArm64: ToolAsset(
        fileName: 'httprobe-android-arm64',
        type: ArchiveType.raw,
        sha256: '5c7714b3b9c8e94a9bef8f979377191128257f822fc1c3ed0b7eddcd9d8bf24b',
        repo: _androidHostRepo,
        tag: _androidHostTag,
      ),
    },
  ),
  'gowitness': ToolSpec(
    repo: 'sensepost/gowitness',
    tag: '3.1.1',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'gowitness-3.1.1-linux-amd64',
        type: ArchiveType.raw,
        sha256: '57b3188e24782c27fdf72493ce599537efd3187d03b80f8afe733c72d68c5517',
      ),
      Abi.linuxArm64: ToolAsset(
        fileName: 'gowitness-3.1.1-linux-arm64',
        type: ArchiveType.raw,
        sha256: 'a24284b4df4ea94a34edc55232b5d102555dcd01c73b1eb950ac4e304f753784',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'gowitness-3.1.1-darwin-amd64',
        type: ArchiveType.raw,
        sha256: '3dc3de9a1f6e811a117301e978af1cdad1f6c307c036a6bcf2d0b499ba429af5',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'gowitness-3.1.1-darwin-arm64',
        type: ArchiveType.raw,
        sha256: '485f0c52887a499d5f6b324d5f55f515763f277deff38c64efc1399f787bf854',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'gowitness-3.1.1-windows-amd64.exe',
        type: ArchiveType.raw,
        sha256: '26ea2da2d7d4ef04e60289c94ecfd43692d6eca3723cfe318a03bda7a43f9374',
      ),
      Abi.windowsArm64: ToolAsset(
        fileName: 'gowitness-3.1.1-windows-arm64.exe',
        type: ArchiveType.raw,
        sha256: '25291cc90e5d38bce857ea6d6a9ddb5d18204a752862c8572b4da1bfa1a19e74',
      ),
    },
  ),
};
