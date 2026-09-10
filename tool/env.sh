# Ferramentas do projeto. Nada disso está no PATH do shell por padrão nesta
# máquina, então `flutter run` sozinho falha com "comando não encontrado".
#
#   source tool/env.sh
#
# Depois disso, flutter, dart, adb e emulator funcionam na sessão atual.
export JAVA_HOME="$HOME/toolchain/jdk"
export ANDROID_HOME="$HOME/toolchain/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$HOME/toolchain/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
