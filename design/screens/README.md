# Telas do RA Insights

Capturas do app rodando no emulador, **1080×2400 px** (Pixel, densidade 420),
um PNG achatado por tela. Atualizado em 10/09/2026, já com a navegação de 4
abas (Início · Jogos · Desafios · Perfil) e as últimas funcionalidades: filtro
de prêmios, mural com link embutido, busca com abas de jogo/jogador, seguir e
mensagem para outro jogador.

Resolução cheia de propósito: dá para dar zoom e medir espaçamento no Figma, e
o arquivo em disco não custa nada.

| # | Arquivo | Tela |
|---|---|---|
| 01 | `01-splash.png` | Splash — logo com glow e "Carregando seu perfil…" |
| 02 | `02-inicio-topo.png` | **Início** — O que jogar agora, Quase lá, topo do card Desafios |
| 03 | `03-inicio-mais-raras.png` | Início — Mais raras, com filtro de período (Tudo/90d/30d) |
| 04 | `04-jogos-recentes.png` | **Jogos** — segmento Recentes |
| 05 | `05-jogos-por-console.png` | Jogos — segmento Por console, com o resumo (jogos/mastered/beaten/taxa) |
| 06 | `06-jogo-detalhe.png` | Jogo — cabeçalho, busca de conquista e filtros (Todas/Obtidas/Faltam) |
| 07 | `07-conquista-sheet.png` | Conquista — bottom sheet com raridade e "Abrir conquista no site" |
| 08 | `08-busca-jogos.png` | Busca — aba Jogos, resultado local (offline) |
| 09 | `09-busca-jogadores.png` | Busca — aba Jogadores, aviso de nome exato |
| 10 | `10-jogador.png` | Perfil de outro jogador — Enviar mensagem, Seguir, Comparação, Mural |
| 11 | `11-desafios-lista.png` | **Desafios** — busca, ordenação (Mais perto/Recentes/Maiores) e filtros |
| 12 | `12-desafio-detalhe.png` | Desafio — cabeçalho, progresso e "O que fazer a seguir" |
| 13 | `13-desafio-proximos-passos.png` | Desafio — próximos passos ordenados por taxa de desbloqueio |
| 14 | `14-perfil-topo.png` | **Perfil** — identidade, Pontuação, Coleção, Atividade |
| 15 | `15-perfil-atividade-heatmap.png` | Perfil — prévia do heatmap com link "Ver atividade completa" |
| 16 | `16-atividade-completa.png` | Atividade — heatmap de 365 dias, 3 modos, lista por dia/jogo |
| 17 | `17-perfil-premios.png` | Perfil — Prêmios com filtro Todos/Mastered/Beaten |
| 18 | `18-perfil-mural.png` | Perfil — Mural, com o próprio comentário do usuário |
| 19 | `19-ajustes.png` | Ajustes — conta, chave da API, idioma, cache, sobre |

## Não capturado

- **Login / onboarding** — exigiria sair da conta no emulador, apagando a
  chave da Web API guardada ali.
- **"Montar um plano"** (bottom sheet do desafio) — não abriu de forma
  reprodutível durante a captura; conferir se o botão está disparando o sheet
  certo antes da próxima rodada.

## Como importar no Figma

*File → Place image* (ou arraste a pasta inteira). Cada PNG vira um frame de
1080×2400.
