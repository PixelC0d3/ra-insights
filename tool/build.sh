#!/usr/bin/env bash
# Gera os builds do app sem depender de mim pedir JAVA_HOME/flutter na mão.
#
#   tool/build.sh debug              # app-debug.apk — rápido, para testar
#   tool/build.sh release            # app-release.apk — instalável, R8 ativo
#   tool/build.sh bundle             # app-release.aab — para subir na Play Store
#   tool/build.sh all                # os três, em sequência
#
# Sem argumento, gera "release" (o mais pedido até aqui).
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=tool/env.sh
source tool/env.sh

APK_DIR="build/app/outputs/flutter-apk"
AAB_DIR="build/app/outputs/bundle/release"

human_size() { du -h "$1" 2>/dev/null | cut -f1; }

build_debug() {
  echo "→ debug (sem R8, mais rápido de compilar)"
  flutter build apk --debug
  echo "  ✓ $APK_DIR/app-debug.apk ($(human_size "$APK_DIR/app-debug.apk"))"
}

build_release() {
  echo "→ release (R8 + ofuscação ativos)"
  flutter build apk --release
  local apk="$APK_DIR/app-release.apk"
  echo "  ✓ $apk ($(human_size "$apk"))"

  # Sem android/key.properties o build cai para a chave de debug de propósito
  # (ver comentário em android/app/build.gradle.kts) — isso é instalável à
  # vontade, mas a Play Store rejeita. Avisa em vez de deixar você descobrir
  # só na hora do upload.
  local signer
  signer="$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools" | sort -V | tail -1)/apksigner"
  if [[ -x "$signer" ]]; then
    if "$signer" verify --print-certs "$apk" 2>/dev/null | grep -q "CN=Android Debug"; then
      echo "  ⚠ assinado com a chave de DEBUG — rode tool/make_keystore.sh antes de publicar"
    else
      echo "  ✓ assinado com a chave de upload"
    fi
  fi
}

build_bundle() {
  echo "→ app bundle (.aab, formato exigido pela Play Store)"
  flutter build appbundle --release
  local aab="$AAB_DIR/app-release.aab"
  echo "  ✓ $aab ($(human_size "$aab"))"
  echo "  (boa parte do tamanho é símbolo de depuração; o download real na Play é bem menor — ver RELEASE.md)"
}

case "${1:-release}" in
  debug)   build_debug ;;
  release) build_release ;;
  bundle)  build_bundle ;;
  all)     build_debug; build_release; build_bundle ;;
  *)
    echo "Uso: tool/build.sh [debug|release|bundle|all]" >&2
    exit 1
    ;;
esac
