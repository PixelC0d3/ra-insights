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

# Telas do RA Insights — para o Figma

Capturas do app rodando no emulador, **1080×2400 px** (Pixel, densidade 420),
um PNG achatado por tela. Resolução cheia de propósito: no Figma dá para dar
zoom e medir espaçamento, e o arquivo em disco não custa nada.

Como importar: no Figma, *File → Place image* (ou arraste a pasta inteira).
Cada PNG vira um frame de 1080×2400.

| # | Arquivo | Tela |
|---|---|---|
| 01 | `01-splash.png` | Splash com o logo e o glow |
| 02 | `02-insights.png` | Insights (aba 1) — topo, cards de números |
| 03 | `03-insights-quase-la.png` | Insights — Streak e Quase lá |
| 04 | `04-insights-desafios.png` | Insights — card Desafios |
| 05 | `05-insights-mais-raras.png` | Insights — Mais raras, com filtro de período |
| 06 | `06-jogos-recentes.png` | Jogos (aba 2) — recentes, com seletor e paginação |
| 07 | `07-atividade.png` | Atividade (aba 3) — heatmap do ano |
| 08 | `08-progressao.png` | Progressão (aba 4) — por console |
| 09 | `09-perfil.png` | Perfil (aba 5) — topo |
| 10 | `10-perfil-detalhe.png` | Perfil — pontuação, coleção, atividade |
| 11 | `11-desafios-lista.png` | Desafios — busca, ordenação e filtros |
| 12 | `12-desafios-card.png` | Desafios — variação do card no dashboard |
| 13 | `13-desafio-carregando.png` | **Estado de carregamento** (skeleton) |
| 14 | `14-desafio-detalhe.png` | Desafio — cabeçalho e "O que fazer a seguir" |
| 15 | `15-desafio-plano.png` | Plano — bottom sheet, passos numerados |
| 16 | `16-desafio-plano-fim.png` | Plano — rolado até o fim |
| 17–20 | `17..20-desafio-conquistas-*.png` | Lista completa das conquistas, com raridade |
| 21 | `21-jogo-detalhe.png` | Jogo — conquistas obtidas e bloqueadas |
| 22 | `22-jogo-metroid.png` | Jogo — variação só com bloqueadas |
| 23 | `23-conquista-sheet.png` | Conquista — bottom sheet de detalhe |
| 24 | `24-busca.png` | Busca — abas Jogos e Jogadores |
| 25 | `25-configuracoes.png` | Ajustes |

## Não capturado

**Login / onboarding.** Exigiria sair da conta no emulador, apagando a chave da
Web API guardada ali. Não fiz isso por conta própria. Se quiser essa tela,
me avise que eu saio, capturo e você refaz o login — ou capture você mesmo antes
de entrar da próxima vez.

## Observação de design

O `13-desafio-carregando.png` foi mantido de propósito: o skeleton fica visível
por vários segundos nos desafios grandes (a CL7W tem 291 conquistas), então é um
estado real da interface, não um acidente da captura.


## Testes

```bash
flutter test         # 132 testes: domínio puro + parsing de API + l10n
flutter analyze      # deve sair limpo
```
