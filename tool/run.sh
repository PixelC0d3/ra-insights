#!/usr/bin/env bash
# Sobe o app no emulador (ou no aparelho plugado, se houver um).
#
#   tool/run.sh                 # debug, com hot reload
#   tool/run.sh --release       # qualquer flag extra vai direto para flutter run
#
# Cuida das três coisas que fazem `flutter run` falhar nesta máquina: PATH,
# emulador desligado e trava de instância deixada por um emulador morto à força.
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=tool/env.sh
source tool/env.sh

AVD="ra_insights"

device_ready() {
  adb devices | awk 'NR>1 && $2=="device" {found=1} END {exit !found}'
}

if device_ready; then
  echo "→ aparelho já conectado, seguindo direto."
else
  # Um emulador morto com `kill -9` deixa multiinstance.lock para trás e o
  # próximo start falha alegando que já existe uma instância. Só é seguro
  # remover quando de fato não há processo de emulador vivo.
  if ! pgrep -f "qemu-system.*$AVD" >/dev/null 2>&1; then
    find "$HOME/.android/avd/$AVD.avd" -maxdepth 1 -name '*.lock' -delete 2>/dev/null || true
  fi

  echo "→ subindo o emulador $AVD..."
  nohup emulator -avd "$AVD" -netdelay none -netspeed full \
    > /tmp/ra_emulator.log 2>&1 &

  echo "→ esperando o boot (log em /tmp/ra_emulator.log)..."
  adb wait-for-device
  for _ in $(seq 1 90); do
    [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]] && break
    sleep 2
  done

  if ! device_ready; then
    echo "O emulador não subiu. Veja /tmp/ra_emulator.log" >&2
    exit 1
  fi
  echo "→ pronto."
fi

exec flutter run "$@"
