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
  });

  /// Nome do arquivo na release (usado para montar a URL de download).
  final String fileName;

  /// Como descompactar. [ArchiveType.raw] = o próprio asset já é o binário.
  final ArchiveType type;

  /// sha256 esperado do asset baixado (hex minúsculo, 64 chars).
  final String sha256;

  /// Caminho do binário dentro do arquivo. Nulo quando [type] é raw.
  final String? pathInArchive;
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

  /// Tag da release fixada (ex.: `v2.14.0`).
  final String tag;

  /// Asset por Abi. Abis ausentes = ferramenta indisponível naquela plataforma.
  final Map<Abi, ToolAsset> assets;

  ToolAsset? assetForAbi(Abi abi) => assets[abi];

  String downloadUrl(ToolAsset asset) =>
      'https://github.com/$repo/releases/download/$tag/${asset.fileName}';
}

/// Versões fixadas verificadas contra o GitHub em 2026-07-20.
///
/// Notas de arquitetura:
/// - assetfinder v0.1.1 e httprobe v0.2 não publicam builds arm64; macOS arm64
///   usa o binário darwin amd64 (requer Rosetta em Apple Silicon) e linux arm64
///   fica sem asset.
const Map<String, ToolSpec> kToolManifest = {
  'subfinder': ToolSpec(
    repo: 'projectdiscovery/subfinder',
    tag: 'v2.14.0',
    assets: {
      Abi.linuxX64: ToolAsset(
        fileName: 'subfinder_2.14.0_linux_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: '6529294788f56a20ed96a9b70e71f8f3c247f1d6104ba1e2c2e9e58d8a32c6cb',
      ),
      Abi.linuxArm64: ToolAsset(
        fileName: 'subfinder_2.14.0_linux_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: 'e3dc19f1e1b1f01840989e5d2501fd59069e3fd6fc2387ca78fbe246ef5e0680',
      ),
      Abi.macosX64: ToolAsset(
        fileName: 'subfinder_2.14.0_macOS_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: 'f419cf27f8d04ec7de967e9661767908caf1905636276c6c05916b19027c1959',
      ),
      Abi.macosArm64: ToolAsset(
        fileName: 'subfinder_2.14.0_macOS_arm64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder',
        sha256: '622a711bf0dfd4aab5b0f6f1f5efe0d6d20fb75734f947a34a7f8ef1348f5435',
      ),
      Abi.windowsX64: ToolAsset(
        fileName: 'subfinder_2.14.0_windows_amd64.zip',
        type: ArchiveType.zip,
        pathInArchive: 'subfinder.exe',
        sha256: '84e8a01d3d062484bb0958445e635a5773b6671566407fb4ab48417391539681',
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
    },
  ),
};
