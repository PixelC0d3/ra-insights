#!/usr/bin/env bash
# Generates the upload keystore for Google Play and writes android/key.properties.
#
# Run once, keep the .jks file backed up somewhere safe and OUT of the repo.
# If you lose it you cannot publish updates to the same listing ever again —
# Play identifies the app by this key. (Play App Signing gives you a recovery
# path for the *app* signing key, but never for the upload key.)
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=tool/env.sh
source tool/env.sh   # põe o keytool do JDK do projeto no PATH

OUT="${1:-$HOME/.keys/ra-insights-upload.jks}"
ALIAS="upload"

if [[ -f "$OUT" ]]; then
  echo "Já existe um keystore em $OUT — não vou sobrescrever." >&2
  echo "Apague-o manualmente se tiver certeza, ou passe outro caminho:" >&2
  echo "  tool/make_keystore.sh /outro/caminho.jks" >&2
  exit 1
fi

command -v keytool >/dev/null || {
  echo "keytool não encontrado. Instale um JDK (ex.: sudo apt install default-jdk)." >&2
  exit 1
}

mkdir -p "$(dirname "$OUT")"
chmod 700 "$(dirname "$OUT")"

echo "Criando o keystore de upload em: $OUT"
echo "Escolha uma senha forte. Ela NÃO fica salva em lugar nenhum além de"
echo "android/key.properties (git-ignored) — anote-a no seu gerenciador de senhas."
echo

# -storepass/-keypass are deliberately absent: keytool prompts, so the password
# never lands in the shell history or in the process list.
keytool -genkeypair -v \
  -keystore "$OUT" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 \
  -validity 10000

chmod 600 "$OUT"

echo
read -r -s -p "Repita a senha para gravar em android/key.properties: " PASS
echo

umask 077
cat > android/key.properties <<PROPS
storeFile=$OUT
storePassword=$PASS
keyAlias=$ALIAS
keyPassword=$PASS
PROPS
unset PASS

echo "Pronto."
echo "  keystore .......... $OUT      (faça backup!)"
echo "  configuração ...... android/key.properties  (git-ignored)"
echo
echo "Confira a impressão digital com:"
echo "  keytool -list -v -keystore \"$OUT\" -alias $ALIAS"
echo
echo "Agora: flutter build appbundle --release"
