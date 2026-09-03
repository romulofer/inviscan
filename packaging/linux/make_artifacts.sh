#!/usr/bin/env bash
# Gera .deb e .AppImage do InviScan a partir do bundle já compilado por
# `flutter build linux --release`. Reutilizado localmente (amd64) e no CI (arm64).
#
# Uso: make_artifacts.sh <amd64|arm64> <versao>
# Requisitos: dpkg-deb, fakeroot, wget/curl. appimagetool é baixado se ausente.
set -euo pipefail

ARCH="${1:?arch (amd64|arm64) obrigatorio}"
VERSION="${2:?versao obrigatoria}"

case "$ARCH" in
  amd64) FLUTTER_ARCH="x64";   APPIMAGE_ARCH="x86_64" ;;
  arm64) FLUTTER_ARCH="arm64"; APPIMAGE_ARCH="aarch64" ;;
  *) echo "arch invalida: $ARCH (use amd64 ou arm64)" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUNDLE="$REPO_ROOT/build/linux/$FLUTTER_ARCH/release/bundle"
ICON="$REPO_ROOT/icon.png"
DIST="$REPO_ROOT/dist"
APP_ID="com.example.inviscan"

[ -d "$BUNDLE" ] || { echo "bundle nao encontrado: $BUNDLE (rode flutter build linux --release)" >&2; exit 1; }
[ -f "$ICON" ] || { echo "icone nao encontrado: $ICON" >&2; exit 1; }
mkdir -p "$DIST"

# ---------- .desktop compartilhado ----------
desktop_file() {
  cat <<EOF
[Desktop Entry]
Type=Application
Name=InviScan
Comment=Reconhecimento de subdomínios para pentest e bug bounty
Exec=inviscan
Icon=inviscan
Categories=Network;Security;
Terminal=false
EOF
}

# =========================================================================
# .deb
# =========================================================================
build_deb() {
  local stage; stage="$(mktemp -d)"
  local pkgdir="$stage/inviscan"
  mkdir -p "$pkgdir/DEBIAN" \
           "$pkgdir/usr/lib/inviscan" \
           "$pkgdir/usr/bin" \
           "$pkgdir/usr/share/applications" \
           "$pkgdir/usr/share/icons/hicolor/512x512/apps"

  cp -r "$BUNDLE"/. "$pkgdir/usr/lib/inviscan/"
  cp "$ICON" "$pkgdir/usr/share/icons/hicolor/512x512/apps/inviscan.png"
  desktop_file > "$pkgdir/usr/share/applications/inviscan.desktop"

  cat > "$pkgdir/usr/bin/inviscan" <<'EOF'
#!/bin/sh
exec /usr/lib/inviscan/inviscan "$@"
EOF
  chmod 0755 "$pkgdir/usr/bin/inviscan"

  cat > "$pkgdir/DEBIAN/control" <<EOF
Package: inviscan
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Maintainer: Rômulo Fernandes Evangelista <rfe89@hotmail.com>
Depends: libgtk-3-0, libglib2.0-0, libstdc++6
Description: InviScan — reconhecimento de subdomínios
 GUI unificada sobre ferramentas CLI de reconhecimento (subfinder, assetfinder,
 ffuf, httprobe, gowitness) para pentest e bug bounty.
EOF

  local out="$DIST/inviscan_${VERSION}_${ARCH}.deb"
  fakeroot dpkg-deb --build "$pkgdir" "$out"
  echo "deb:  $out"
  rm -rf "$stage"
}

# =========================================================================
# .AppImage
# =========================================================================
ensure_appimagetool() {
  local tool="$DIST/appimagetool-$APPIMAGE_ARCH.AppImage"
  if [ ! -x "$tool" ]; then
    local url="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$APPIMAGE_ARCH.AppImage"
    echo "baixando appimagetool: $url" >&2
    if command -v wget >/dev/null; then wget -qO "$tool" "$url"; else curl -sL -o "$tool" "$url"; fi
    chmod +x "$tool"
  fi
  echo "$tool"
}

build_appimage() {
  local appdir; appdir="$(mktemp -d)/InviScan.AppDir"
  mkdir -p "$appdir/usr/lib/inviscan" \
           "$appdir/usr/share/applications" \
           "$appdir/usr/share/icons/hicolor/512x512/apps"

  cp -r "$BUNDLE"/. "$appdir/usr/lib/inviscan/"
  cp "$ICON" "$appdir/inviscan.png"
  cp "$ICON" "$appdir/usr/share/icons/hicolor/512x512/apps/inviscan.png"
  desktop_file > "$appdir/inviscan.desktop"
  cp "$appdir/inviscan.desktop" "$appdir/usr/share/applications/inviscan.desktop"

  cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/lib/inviscan/inviscan" "$@"
EOF
  chmod 0755 "$appdir/AppRun"

  local tool; tool="$(ensure_appimagetool)"
  local out="$DIST/InviScan-${VERSION}-${APPIMAGE_ARCH}.AppImage"
  # --appimage-extract-and-run: dispensa FUSE (CI/containers).
  ARCH="$APPIMAGE_ARCH" "$tool" --appimage-extract-and-run "$appdir" "$out"
  echo "appimage: $out"
  rm -rf "$(dirname "$appdir")"
}

build_deb
build_appimage
