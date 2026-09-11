# RA Insights — Plano de Ação

**App mobile Flutter de análise de perfil RetroAchievements.**

> **Documento histórico.** Escrito antes da implementação, mantido como registro
> da intenção original. O estado atual do app está no `README.md`; o redesenho de
> navegação aplicado depois está em `design/REORGANIZACAO.md`.

- Criado em: 2026-08-29
- Origem: features do userscript [RA Toolkit](https://github.com/PixelC0d3/ra-toolkit) (`~/Documentos/Projetos/ra-toolkit`)
- Status: **planejamento** — próximo passo é a Fase 0

---

## 1. Posicionamento

**O que é:** um app de *análise* do perfil RetroAchievements. Streaks, heatmap de atividade, jogos perto do mastery, conquistas mais raras, progressão por console — coisas que **nem o site nem os clientes mobile existentes entregam**.

**O que NÃO é:** mais um cliente RA genérico. Já existe pelo menos um na Play Store (`com.akissame.retroachievements`). Refazer navegação de jogos, listas de conquistas e feed social é gastar meses reimplementando o que o site já faz melhor. O app abre direto no dashboard de insights.

**Frase-guia para decidir escopo:** *"isso responde uma pergunta sobre o meu progresso que o site não responde?"* Se não, fica fora.

---

## 2. Escopo

### Dentro
Tudo que se calcula a partir da **API Web oficial** do RetroAchievements.

### Fora — decidido, não reabrir

| Item | Motivo |
|---|---|
| **Download de ROM** (Myrient, Archive, EmuParadise, RomsFun) | Agregar links de download de ROM é o padrão que a política de propriedade intelectual do Google derruba, e alvo direto de DMCA. No userscript o risco é local; numa loja é distribuição pública sob o seu nome de desenvolvedor. |
| **Tudo que depende de scraping do DOM** | 29 dos 39 módulos de `src/features/` do script existem só para *aumentar* uma página que já renderiza o dado. Num app não há página para aumentar. |
| Botões de tradução, linkify de comentários, badges injetados, painel de settings, navbar, collapsible, `reattach`/MutationObserver | Mesmo motivo. São enhancers de DOM. |
| Backend próprio (v1) | Sem servidor = sem dados de usuário sob minha guarda = política de privacidade trivial. A chave da API fica no aparelho. |

### A única dívida de scraping
`scrapeConsoleBreakdown()` (`src/features/user-profile/insights/progression.js:9`) lê `li.progression-status-row` do DOM para obter `totalGames` / `totalMastered` e a quebra por console. **Precisa de substituto via API:** `API_GetUserCompletionProgress` + `API_GetConsoleIDs`. É a única peça dos insights que não porta direto — resolver na Fase 4.

---

## 3. Features

### 3.1 Portadas do script (a base)

| Feature | O que faz | Fonte de dados | Módulo de origem |
|---|---|---|---|
| **Stats cards** | Games played, Mastered, Mastery rate %, Points + Rank | `API_GetUserSummary` | `insights/stats-cards.js` |
| **Almost There** | Top 5 jogos com ≥50% e <100% das conquistas, ordenados por proximidade, com barra de progresso | `API_GetUserRecentlyPlayedGames` (c=50) | `insights/almost-there.js` |
| **Streaks** | Sequência atual de dias com unlock (tolera "ainda não joguei hoje"), melhor sequência, dias ativos, total de conquistas em 365d | `API_GetAchievementsEarnedBetween` × 4 trimestres | `insights/streaks.js` |
| **Rarest** | Top 5 conquistas recentes por TrueRatio, com o multiplicador `TrueRatio/Points` | `API_GetUserRecentAchievements` (30d) | `insights/rarest.js` |
| **Heatmap 365d** | Grade estilo GitHub, **3 modos combináveis**: 🏆 Achievements / 👑 Mastered / ✅ Beaten | `AchievementsEarnedBetween` + `API_GetUserAwards` | `insights/timeline.js` |
| **Progressão por console** | Distribuição de jogos/masteries por console, filtros `all` / `with progress` / `mastered` | ⚠️ hoje é DOM — migrar para `GetUserCompletionProgress` | `insights/progression.js` |

### 3.2 Novas — o que só faz sentido em app

Ordenadas por *valor ÷ esforço*. As três primeiras são a razão de existir um app em vez de um site.

1. **🔥 Notificação de streak em risco** — "sua sequência de 12 dias acaba em 4h". Uma notificação local diária, agendada, que só dispara se ainda não houve unlock no dia. **É a feature matadora**: retenção real, e impossível num userscript.
2. **📱 Widget de home screen** — streak atual + o jogo mais perto do mastery. O app fica útil sem ser aberto.
3. **✈️ Offline-first** — tudo cacheado em SQLite. Abre no metrô e mostra o último estado, com timestamp de "atualizado há X". Não é feature glamourosa, é o que separa app de webview.
4. **🎯 "O que jogar agora"** — uma recomendação por vez, cruzando *quão perto do mastery* × *quantas conquistas faltam* × *dificuldade real (TrueRatio médio das restantes)*. Combate a paralisia de backlog.
5. **📊 Retrospectiva anual (Wrapped)** — um ano de `AchievementsEarnedBetween` já é buscado para o heatmap. Vira uma sequência de cards: total de pontos, console mais jogado, conquista mais rara, mês mais ativo, maior streak. Altamente compartilhável — é aquisição orgânica de graça.
6. **🖼️ Compartilhar card como imagem** — qualquer conquista/estatística vira PNG pelo share sheet (`RepaintBoundary` → `toImage`). Mesmo efeito de aquisição.
7. **🏅 Metas** — "5 masteries neste mês", "manter streak 30 dias". Progresso local, sem backend.
8. **👥 Comparar com outro usuário** — mesmo jogo, dois perfis lado a lado (`API_GetGameInfoAndUserProgress` por usuário). Bom para quem joga junto com amigos.
9. **🔍 Busca de jogo → "quanto me falta"** — entra pelo jogo, não pelo perfil.
10. **📌 Want to Play / backlog** — `API_GetUserWantToPlayList`, cruzado com o "o que jogar agora".

### 3.3 Backlog (não planejar ainda)
Multi-conta · leaderboards · notificação de novo set publicado para console favorito · exportar CSV/JSON · tema claro · iOS.

---

## 4. Stack

| Camada | Escolha | Por quê |
|---|---|---|
| Framework | **Flutter** (Dart 3, Material 3) | App read-only de listas e gráficos, um codebase. Encaixe certo. |
| Estado | **Riverpod** (`@riverpod` codegen) | Providers assíncronos com cache e invalidação; evita o boilerplate de BLoC num app sem fluxos complexos. |
| HTTP | **dio** + interceptor de rate limit/retry | Precisa de fila e backoff (ver §5). |
| Modelos | **freezed** + **json_serializable** | A API devolve JSON com campos inconsistentes (`"0"` vs `0`); converters explícitos evitam crash. |
| Persistência | **drift** (SQLite) | Offline-first com queries reativas. Escolhido sobre Isar por manutenção ativa. |
| Segredos | **flutter_secure_storage** | Keystore/Keychain para a chave da API. Nunca em SharedPreferences. |
| Navegação | **go_router** | Deep links para perfil/jogo. |
| Gráficos | **fl_chart** + heatmap em `CustomPainter` | fl_chart não faz heatmap de calendário; a grade de 365 células é pintada à mão (mais rápido que 365 widgets). |
| Notificações | **flutter_local_notifications** + **workmanager** | Job diário que checa a streak. |
| Widget | **home_widget** | Android primeiro. |
| Testes | `flutter_test` + **mocktail** + golden tests | Ver §7. |

**Sem backend, sem analytics, sem crash reporting de terceiros na v1.** Se um dia entrar telemetria, tem que ser opt-in explícito.

---

## 5. Contrato com a API

**Base:** `https://retroachievements.org/API/<Endpoint>.php`
**Auth:** `?u=<usuário-alvo>&y=<chave>` — a chave sai de *Settings → Web API Key* no site.

### Regras inegociáveis
1. **A chave é do usuário.** Nunca embutir a minha no binário: seria rate limit compartilhado e a minha conta respondendo pelo abuso de todo mundo.
2. **Onboarding é fricção real.** Tela de login precisa de: link direto para a página de settings do RA, campo de colar, validação imediata com `API_GetUserProfile`, e mensagem de erro que diferencia *chave inválida* de *sem internet*.
3. **Rate limit.** A documentação pede moderação. Todo request passa por uma fila serializada com intervalo mínimo; `429` → backoff exponencial; nunca disparar 8 requests em paralelo como o script faz hoje em `data.js:56-66`.
4. **Cache antes de rede.** Toda tela lê do SQLite e dispara refresh em background. TTL sugerido: perfil 5min, recém-jogados 5min, dados anuais 6h, lista de consoles 30 dias.

### Endpoints por feature
```
Perfil/stats ........ API_GetUserProfile, API_GetUserSummary
Almost There ........ API_GetUserRecentlyPlayedGames (c=50)
Rarest .............. API_GetUserRecentAchievements (m=43200)
Streaks + Heatmap ... API_GetAchievementsEarnedBetween (4 chunks/ano)
                      API_GetUserAwards  (mastered/beaten do heatmap)
Dia do heatmap ...... API_GetAchievementsEarnedOnDay
Progressão .......... API_GetUserCompletionProgress, API_GetConsoleIDs
Jogo ................ API_GetGameInfoAndUserProgress, API_GetGameExtended
Backlog ............. API_GetUserWantToPlayList
```

### Detalhes do domínio que já custaram caro no script — não redescobrir
- **Deduplicar** os 4 chunks anuais por `AchievementID|Date|HardcoreMode` (as bordas dos trimestres se sobrepõem).
- **Prioridade de award** ao consolidar: `mastered(4) > completed(3) > beaten-hardcore(2) > beaten-softcore(1)`.
- `AwardType == "Mastery/Completion"` com `AwardDataExtra == 1` → **mastered**; `== 0` → **completed**.
- **Raridade** = `TrueRatio`, não `Points`. O multiplicador exibido é `TrueRatio / Points`.
- **"softcore" virou "casual"** no vocabulário do site em ago/2026. Usar "casual" na UI e aceitar os dois na desserialização.
- Badges: caminhos relativos precisam de prefixo `https://media.retroachievements.org`.

---

## 6. Arquitetura

```
lib/
  main.dart
  app/                 router, tema, bootstrap
  core/
    api/               dio client, fila de rate limit, interceptors, erros tipados
    db/                drift: tabelas, DAOs, migrations
    auth/              armazenamento e validação da chave
    result.dart        Result<T, AppError> — sem exceção atravessando camada
  domain/              PURO: models freezed + regras de cálculo. Zero Flutter, zero IO.
    insights/          streaks.dart, almost_there.dart, rarity.dart,
                       heatmap.dart, progression.dart, recommendation.dart
  data/                repositories: cache-then-network, mapeamento DTO→domain
  features/            uma pasta por tela: page + widgets + providers
    onboarding/ dashboard/ heatmap/ game/ progression/ compare/ wrapped/ settings/
  ui/                  design system: cards, skeletons, estados de erro/vazio
```

**A regra que sustenta o resto:** `domain/insights/` é Dart puro — recebe listas de modelos e devolve resultados. Nenhum import de Flutter, HTTP ou banco. É onde a lógica do script vive, e é 100% testável sem widget, sem mock de rede, sem emulador.

---

## 7. Estratégia de testes

**Os 219 testes do RA Toolkit são a especificação executável do port.** `tests/user-profile.test.js` já fixa o comportamento de streak, almost-there e raridade contra fixtures reais. Cada teste de insight vira um teste Dart equivalente, com as mesmas entradas e as mesmas saídas esperadas.

Casos que o script já provou importarem — devem existir no Dart desde o primeiro commit:
- streak com **zero** conquistas hoje mas conquistas ontem → sequência continua viva
- streak com buraco no meio → `best` calculado corretamente
- vetor vazio → estado vazio, não crash
- `total == 0` → sem divisão por zero no cálculo de percentual
- conquistas duplicadas nas bordas dos trimestres → deduplicadas
- `TrueRatio` ausente ou `"0"` → item filtrado, não NaN

Pirâmide: unit em `domain/` (a maioria) → repositories com dio mockado → golden tests das telas de insight → um smoke `integration_test` do fluxo onboarding→dashboard.

---

## 8. Passo a passo

Estimativas em **sessões** (~3h de trabalho focado), grosseiras.

### Fase 0 — Fundação · ~4 sessões
1. `flutter create` com org e nome de pacote definitivos (`com.pixelc0d3.rainsights` — decidir antes, renomear depois dói).
2. Git init, `.gitignore`, `analysis_options.yaml` com `flutter_lints` + `strict-casts`.
3. Estrutura de pastas da §6 com um arquivo placeholder por camada.
4. GitHub Actions: `flutter analyze` + `flutter test` em cada push. Mesmo padrão do RA Toolkit.
5. Cliente dio: base URL, injeção de `u`/`y`, **fila serializada com intervalo mínimo**, retry com backoff, `Result<T, AppError>` com erros tipados (`unauthorized`, `network`, `rateLimited`, `parse`).
6. Drift: schema inicial vazio + migration 1.

> **Pronto quando:** `flutter test` verde no CI e um teste de integração do cliente HTTP bate num endpoint real com chave de teste.

### Fase 1 — Onboarding + Dashboard esqueleto · ~4 sessões
7. Tela de chave da API: instruções, link para as settings do RA, colar, validar com `API_GetUserProfile`, salvar em secure storage.
8. Tratar os três erros distintos: chave errada / usuário inexistente / offline.
9. Shell do app: go_router, tema escuro Material 3, bottom nav.
10. Dashboard com **stats cards** (`API_GetUserSummary`) — o primeiro caminho end-to-end completo.
11. Skeleton loaders e estado de erro com retry.

> **Pronto quando:** instalar, colar a chave e ver os próprios pontos e rank.

### Fase 2 — Insights portados · ~6 sessões
12. Portar `domain/insights/streaks.dart` + testes (traduzidos de `streaks.js`).
13. Portar `almost_there.dart` + testes (regra: ≥50%, top 5, ordenado por proximidade).
14. Portar `rarity.dart` + testes (TrueRatio desc, dedupe por `AchievementID`, top 5).
15. Repository dos dados anuais: 4 chunks, dedupe, cache 6h no SQLite.
16. Cards das três features no dashboard, com navegação para detalhe.

> **Pronto quando:** os três cards batem com o que o userscript mostra no mesmo perfil. **Comparar lado a lado — é o teste de aceitação real do port.**

### Fase 3 — Heatmap · ~5 sessões
17. `domain/insights/heatmap.dart`: grade de 365 dias, 3 mapas de dia (achievements/mastered/beaten), buckets de intensidade.
18. `CustomPainter` da grade; scroll horizontal com o mês corrente à direita.
19. Toggles combináveis dos 3 modos, com prioridade de cor `mastered > beaten > achievements` e a trava de "não dá para desmarcar o último".
20. **Tap num dia → bottom sheet** com as conquistas daquele dia (`API_GetAchievementsEarnedOnDay`). Interação que o script não tem.
21. Golden test da grade com dataset fixo.

> **Pronto quando:** o heatmap roda a 60fps num aparelho de entrada.

### Fase 4 — Progressão por console · ~4 sessões
22. **Matar a dívida de scraping:** `GetUserCompletionProgress` + `GetConsoleIDs` produzindo o mesmo shape do `scrapeConsoleBreakdown()`.
23. Paginar e cachear o progresso completo (perfis grandes têm centenas de jogos).
24. UI de lista/barras com os filtros `all` / `with progress` / `mastered`. **Nada de treemap** — não funciona em tela pequena; o bubble/treemap do script era desktop.
25. Drill-down: console → jogos daquele console → jogo.

> **Pronto quando:** `totalGames`/`totalMastered` batem com o site sem tocar em DOM.

### Fase 5 — Aí vira app de verdade · ~6 sessões
26. Offline-first completo: toda tela lê do cache primeiro, refresh em background, "atualizado há X" visível.
27. Pull-to-refresh com invalidação explícita.
28. `workmanager`: job diário que busca as conquistas de hoje.
29. **Notificação de streak em risco**, disparada só se a sequência ≥ 3 dias e ainda não houve unlock hoje. Horário configurável, default 20h.
30. Configurações de notificação, incluindo desligar tudo.
31. Widget de home screen Android: streak + jogo mais perto do mastery.

> **Pronto quando:** o app é útil sem ser aberto.

### Fase 6 — Diferenciação · ~6 sessões
32. "O que jogar agora": heurística sobre almost-there + conquistas restantes + TrueRatio médio.
33. Compartilhar card como imagem (`RepaintBoundary` → `toImage` → share sheet).
34. Retrospectiva anual, reaproveitando os dados anuais já em cache.
35. Metas locais com progresso.
36. Comparar com outro usuário.

### Fase 7 — Publicação · ~4 sessões
37. Ícone, splash, screenshots, descrição da loja.
38. **Política de privacidade** (pode ser uma página no GitHub Pages): sem coleta, sem servidor, chave fica no aparelho.
39. **Deixar explícito que é não-oficial** — nome, ícone e descrição não podem sugerir vínculo com o RetroAchievements. Ler os termos de uso da API e creditar a fonte.
40. Assinatura de release, `--split-per-abi`, teste interno com algumas pessoas.
41. Release na Play Store + APK no GitHub Releases.

**Total grosseiro: ~35-40 sessões até a v1 publicada.** Fases 0-3 já entregam algo que eu usaria todo dia.

---

## 9. Riscos

| Risco | Mitigação |
|---|---|
| Fricção da chave de API derruba a conversão do onboarding | Onboarding de uma tela só, com link direto e validação instantânea. Medir onde as pessoas desistem antes de otimizar qualquer outra coisa. |
| Mudança/rate limit da API oficial | Toda desserialização tolerante a campo faltando; fila de requests desde a Fase 0; testes de contrato com fixtures JSON congeladas (mesma técnica de `tests/fixtures/raweb-source.js` no RA Toolkit). |
| Perfis grandes deixam o app lento | Paginar, cachear, computar insights em `compute()` (isolate) se a grade anual passar de ~15k conquistas. |
| Duplicar esforço com o RA Toolkit | São produtos separados. O que se compartilha é o **domínio**, não código. Manter os cálculos documentados em um lugar só — este arquivo. |
| Store reclamar de uso de marca | Nome próprio, ícone próprio, "não oficial" na descrição. |

---

## 10. Decisões tomadas

- ROM **fora**, definitivo, inclusive fora do APK do GitHub — não vale o risco de ter meu nome associado.
- Sem backend na v1.
- Android primeiro; iOS só se houver demanda (custo de 99 USD/ano por conta de desenvolvedor).
- O app abre no **dashboard de insights**, não numa lista de jogos. Isso é a identidade do produto.
- Progressão por console: lista/barras, não treemap.

## 11. Em aberto

- Nome definitivo e package id.
- A heurística exata do "o que jogar agora" — precisa de tentativa e erro com dados reais.
- Ler os termos de uso da API do RetroAchievements antes da Fase 7 e confirmar que distribuição em loja está ok.
- Multi-conta: vale a pena, ou complica o modelo de dados sem retorno?
