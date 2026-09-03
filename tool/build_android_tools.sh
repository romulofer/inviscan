#!/usr/bin/env bash
# Cross-compila as ferramentas Go (arm64) como bibliotecas nativas do APK.
#
# No Android 10+ não é possível executar binários gravados em storage do app
# (W^X/SELinux). A saída aceita é empacotar os executáveis como `lib*.so` em
# jniLibs: o instalador os extrai para `nativeLibraryDir`, que é executável e
# somente-leitura. Por isso o nome `lib<tool>.so` (exigido pelo empacotador) e
# a resolução via nativeLibraryDir em `lib/utils/binaries.dart`.
#
# gowitness fica de fora: depende de Chrome headless, indisponível no Android.
#
# Requisitos: go, NDK (aarch64-linux-android<API>-clang).
# Uso: tool/build_android_tools.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/android/app/src/main/jniLibs/arm64-v8a"
API=21  # deve casar com minSdkVersion do Flutter

# Localiza o NDK (ANDROID_NDK_HOME, ANDROID_SDK_ROOT/ndk/* ou ~/Android/Sdk).
find_ndk_cc() {
  local candidates=()
  [ -n "${ANDROID_NDK_HOME:-}" ] && candidates+=("$ANDROID_NDK_HOME")
  for base in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$HOME/Android/Sdk"; do
    [ -d "$base/ndk" ] && for d in "$base"/ndk/*; do candidates+=("$d"); done
  done
  for ndk in "${candidates[@]}"; do
    local cc="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-clang"
    [ -x "$cc" ] && { echo "$cc"; return 0; }
  done
  echo "NDK não encontrado (defina ANDROID_NDK_HOME)" >&2
  return 1
}

CC="$(find_ndk_cc)"
echo "NDK CC: $CC"
mkdir -p "$OUT"

export GOOS=android GOARCH=arm64 CGO_ENABLED=1 CC
GPBIN="$(go env GOPATH)/bin/android_arm64"

# out_name <- bin_name (nome produzido por `go install`) de module@versão
# (mesmas versões fixadas em tool_manifest.dart)
build() {
  local out_name="$1" bin_name="$2" module="$3"
  echo ">> $out_name ($module)"
  go install -ldflags '-s -w' "$module"
  cp "$GPBIN/$bin_name" "$OUT/$out_name"
}

build libsubfinder.so   subfinder   github.com/projectdiscovery/subfinder/v2/cmd/subfinder@v2.16.0
build libffuf.so        ffuf        github.com/ffuf/ffuf/v2@v2.2.1
build libassetfinder.so assetfinder github.com/tomnomnom/assetfinder@v0.1.1
build libhttprobe.so    httprobe    github.com/tomnomnom/httprobe@7e8abdb4096ab224f21616478b699b4dfda9d409

echo "=== jniLibs ==="
ls -la "$OUT"
