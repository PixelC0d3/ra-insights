# RA Insights

App mobile Flutter de análise de perfil RetroAchievements. **Não oficial**, sem
vínculo com o RetroAchievements. Ver `PLANO.md` para o plano original e
`design/REORGANIZACAO.md` para o redesenho de navegação já aplicado.

## Estado

Implementado, além das Fases 0–4 do plano original (fundação, onboarding,
dashboard, insights portados, heatmap, progressão por console): desafios
(events do RA com plano de conquistas), busca de jogos e jogadores, perfil de
outro jogador (comparação, mural, mensagem, seguir), cache offline-first em
SQLite, splash screen, internacionalização pt/en, e a configuração para
publicar na Play Store (assinatura, R8, política de privacidade — falta só
gerar a chave de upload e preencher a ficha da loja, ver `RELEASE.md`).

Navegação: 4 abas — **Início** (o que jogar agora, mais raras), **Jogos**
(recentes + progressão por console, um segmentado), **Desafios**, **Perfil**
(pontuação, coleção, atividade com heatmap, prêmios, mural).

## Rodar

```bash
tool/run.sh                   # sobe o emulador se preciso e roda o app
tool/run.sh --release         # flags extras vão direto para `flutter run`
```

O script existe porque `flutter`, `adb` e `emulator` não estão no `PATH` desta
máquina. Para usar os comandos na mão, carregue o ambiente primeiro:

```bash
source tool/env.sh
flutter pub get
dart run build_runner build   # gera lib/core/db/database.g.dart (drift)
flutter test
flutter run                   # emulador ou aparelho conectado
```

## Build

```bash
tool/build.sh debug           # app-debug.apk — rápido, sem R8, para testar
tool/build.sh release         # app-release.apk — instalável, R8 ativo (padrão)
tool/build.sh bundle          # app-release.aab — formato exigido pela Play Store
tool/build.sh all             # os três em sequência
```

Avisa se o APK release saiu assinado com a chave de debug (o padrão até você
rodar o script abaixo) em vez da chave de upload.

Equivalente na mão, se preferir:

```bash
source tool/env.sh
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## Publicar na Play Store

```bash
tool/make_keystore.sh                 # gera a chave de upload (uma vez, guarde a senha)
tool/build.sh bundle                  # gera o .aab assinado com ela
```

Sem `android/key.properties` (git-ignorado), o build cai para a chave de debug
de propósito — instalável, mas não publicável. Passo a passo completo,
incluindo o que só você pode decidir (acesso do app para revisão, URL da
política de privacidade, capturas de tela), em `RELEASE.md`.

## Outros scripts

```bash
python3 tool/make_branding.py         # regenera ícones/splash a partir de assets/branding/src/
```

## Chave de API

O app pede o seu usuário e a sua **Web API Key** (retroachievements.org →
Settings → Web API Key) na primeira abertura. A chave é validada com
`API_GetUserProfile` e guardada no keystore do Android via
`flutter_secure_storage`. Não há servidor, telemetria nem chave embutida no
binário — cada usuário usa a própria chave (ver `RELEASE.md` sobre por que essa
é a decisão tomada, apesar de o outro app do gênero embutir a dele).

## Arquitetura

```
lib/
  app/         router (go_router), tema, providers (Riverpod)
  core/        api (dio + fila de rate limit + Result/AppError), auth, db (drift)
  domain/      Dart puro: models + insights (streaks, almost-there, rarity,
               heatmap, progression, recommendation, challenges) — zero
               Flutter, zero IO
  data/        repositories cache-then-network + TTLs
  features/    onboarding, splash, dashboard, games (recentes + progressão),
               challenges, game, heatmap, players, profile, search, settings,
               shell
  ui/          design system: cards, skeletons, estados de erro/vazio
  l10n/        ARB (pt/en) + gen_l10n
```

`domain/insights/` não importa Flutter, HTTP nem banco — é onde a lógica do
userscript RA Toolkit foi portada, e é testada sem widget nem rede.

O índice das capturas de tela (para Figma e para a ficha da loja) fica em
`design/screens/README.md`.

## Testes

```bash
flutter test         # 132 testes: domínio puro + parsing de API + l10n
flutter analyze      # deve sair limpo
```
