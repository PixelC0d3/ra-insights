# RA Insights — reorganização das telas, melhorias e roadmap

Baseado nas 25 capturas em `design/screens/` e na leitura do código.
Data: 3 de setembro de 2026.

---

## 1. Os quatro problemas que os prints mostram

### 1.1 O mesmo número aparece em três telas

Este é o problema mais grave, e dá para provar comparando os prints:

| Número | `02-insights` | `09/10-perfil` | `07-atividade` |
|---|:--:|:--:|:--:|
| 230 jogos jogados | ✅ card | ✅ Coleção | |
| 7 masteries | ✅ card | ✅ Coleção | |
| 3% taxa de mastery | ✅ card | ✅ Coleção | |
| 5.843 pontos | ✅ card | ✅ Pontuação | |
| streak 2 dias | ✅ card Streak | ✅ Atividade | |
| melhor 13 dias | ✅ card Streak | ✅ Atividade | |
| 96 dias ativos (365d) | ✅ card Streak | ✅ Atividade | ✅ heatmap |
| 435 conquistas (365d) | ✅ card Streak | ✅ Atividade | ✅ heatmap |

Oito números, cada um em duas ou três telas. Isso não é redundância inofensiva:
é **custo de manutenção triplicado** e, pior, uma promessa quebrada — o usuário
navega até o Perfil esperando algo novo e encontra o que já tinha visto.

### 1.2 Desafios, a função mais original do app, está enterrada

Para chegar nela: abrir o app → rolar o dashboard até o **quarto** card → tocar
na seta. Enquanto isso, **Atividade** — um heatmap e uma lista — ocupa uma aba
inteira da barra inferior.

Desafios tem lista com busca, ordenação, quatro filtros, tela de detalhe,
gerador de plano e badges de raridade (prints 11 e 14 a 20). É uma seção
completa, com mais superfície que três das cinco abas atuais. E é o que nenhum
outro app de RetroAchievements faz.

Você chegou a pedir isso: *"pode ser um menu ali embaixo"*. Não foi feito — o
router tem só `/dashboard`, `/recent`, `/activity`, `/progression` e `/profile`.

### 1.3 Duas abas fazem o mesmo trabalho

**Jogos recentes** (print 06) e **Progressão** (print 08) são a mesma coleção
ordenada de dois jeitos: por data e por console. São duas abas para uma tarefa —
"achar um jogo meu".

### 1.4 O perfil dos outros é melhor que o seu

Comparando o código de `players/player_page.dart` com `profile/profile_page.dart`:

| | Outro jogador | Você |
|---|:--:|:--:|
| Cabeçalho com avatar | ✅ | ✅ |
| Mural de recados | ✅ | ❌ |
| Comparação de pontos e ranking | ✅ | — |
| Enviar mensagem | ✅ | — |
| Prêmios / troféus | ❌ | ❌ |

Você consegue ler o mural de um estranho e não o seu. E **nenhuma das duas telas
mostra prêmios**, que é justamente o que o jogador quer exibir.

---

## 2. A proposta: quatro abas em vez de cinco

```
HOJE                             PROPOSTA
├── Insights   (tudo misturado)  ├── Início      ações: o que jogar agora
├── Jogos      (recentes)        ├── Jogos       recentes + console + busca
├── Atividade  (heatmap)         ├── Desafios    promovido
├── Progressão (por console)     └── Perfil      números + heatmap + mural
└── Perfil     (números)
```

Menos abas e mais conteúdo em cada uma. O princípio da divisão:

> **Início responde "o que eu faço agora?". Perfil responde "quem eu sou?".**
> Número que descreve identidade vai para o Perfil. Card que sugere uma ação
> fica no Início.

### 2.1 Início — só o que gera ação

**Sai:** o grid de 4 números (`_StatCard`) e o card de Streak (`_StreakCard`).
Ambos descrevem identidade, não sugerem ação. Vão para o Perfil.

**Fica:** O que jogar agora · Quase lá · Mais raras · um resumo curto de
Desafios (2 linhas + "ver todos").

**Ganho:** hoje o Início precisa de **4 rolagens** para ser visto inteiro
(prints 02 a 05). Sem os dois cards de números, cabe em duas.

### 2.2 Jogos — funde Recentes e Progressão

Uma aba com segmented control no topo:

```
[ Recentes ]  [ Por console ]        🔍
```

- **Recentes** = tela 06 de hoje, mas com rolagem infinita no lugar da
  paginação com "Mostrar 5" (paginação numerada é padrão de web, não de app).
- **Por console** = tela 08 de hoje, intacta.
- A **lupa** deixa de ser um detalhe da app bar do Início e ganha lugar fixo
  aqui, que é onde procurar jogo faz sentido.

### 2.3 Desafios — promovido a aba

Sem mudança de conteúdo. Só deixa de exigir rolagem e um toque em seta para ser
encontrado. Lista, detalhe e plano já estão prontos (prints 11, 14, 15, 16).

### 2.4 Perfil — vira um perfil de verdade

Recebe tudo que descreve o jogador:

1. Cabeçalho: avatar, nome, "membro desde", ranking
2. **Os 4 números** vindos do Início (jogos, masteries, taxa, pontos)
3. **Streak** vindo do Início
4. **O heatmap** vindo da aba Atividade — ele é a visualização do seu ano,
   não um destino próprio
5. **Prêmios / troféus** — não existe hoje em lugar nenhum, e o endpoint
   `GetUserAwards` já está implementado no repositório
6. **Seu mural** — hoje só visível no perfil dos outros
7. Botão "abrir meu perfil no site" e a engrenagem de Ajustes

Isso mata a aba Atividade sem perder nada, e o Perfil deixa de ser planilha.

---

## 3. Melhorias pequenas, alto retorno

Em ordem de esforço crescente:

1. **Título truncado nos desafios.** "Challenge League 7 Wond…" aparece cortado
   em todos os prints de 14 a 20. Deixar duas linhas no `AppBar` ou reduzir a
   fonte — o nome do evento é a única pista de contexto naquela tela.
2. **Busca dentro das conquistas de um jogo.** A CL7W tem **291** conquistas
   (prints 17 a 20). Rolar 291 linhas para achar uma é inviável. O
   `_FilterChips` já existe em `game_page.dart:151`; falta um campo de texto do
   lado.
3. **Skeleton longo demais.** O print `13-desafio-carregando` não foi acidente:
   em desafios grandes ele fica vários segundos. Renderizar primeiro o cabeçalho
   com os dados que já vieram do catálogo (título, ícone, total) e só depois a
   lista — o usuário vê que abriu a coisa certa enquanto espera.
4. **Nomes de subset poluídos.** "Metroid [Subset - Bonus]",
   "Super Mario Bros. [Subset - Sub 20-Minute W…]" (prints 05, 21, 22). Extrair
   o que está entre colchetes para um chip pequeno abaixo do título.
5. **Rolagem infinita** no lugar da paginação em Jogos recentes.
6. **Ordenação na Progressão**: por % de conclusão, por pontos, por último
   jogado. Hoje só existem os filtros Todos / Com progresso / Mastered.
7. **Indicador de dados velhos.** O "atualizado agora" do rodapé (print 05)
   deveria virar um aviso visível quando o app está offline com cache antigo —
   o app se vende como offline-first, mas não diz o quanto está desatualizado.

---

## 4. Funcionalidades futuras

Ordenadas por (valor ÷ esforço). Todas cabem no modelo sem servidor.

### 4.1 Alta prioridade

**Comparar-se com outro jogador.** A busca já tem a aba Jogadores e a
`player_page` já calcula "à frente / atrás" em pontos e ranking. Falta a
comparação lado a lado das coleções: quais jogos vocês dois têm, onde ele está
na frente. É o gancho social mais barato de construir aqui.

**Notificação local de streak.** "Você está há 2 dias seguidos — jogue hoje para
não perder." Zero backend: `flutter_local_notifications` agendando às 20h, e o
próprio app cancela quando detecta conquista no dia. Ataca diretamente a
retenção, que é o ponto fraco de um app sem contas.

**Prêmios e troféus.** `GetUserAwards` já está no repositório e não é exibido em
lugar nenhum. É a informação mais "vitrine" que a API oferece.

**Achievement of the Week em destaque.** É semanal e recorrente — o print 14
mostra que ele já é um dos primeiros desafios da lista. Merece um card fixo no
Início durante a semana corrente.

### 4.2 Média prioridade

**Metas pessoais.** "Chegar a 10 masteries", "1.000 pontos neste mês". Guardado
no drift local, com barra de progresso no Perfil. Dá um propósito de médio prazo
que hoje não existe.

**Compartilhar uma conquista rara.** Gerar uma imagem (badge + raridade + %) do
sheet do print 23 e abrir o share do Android. Divulgação orgânica sem custo.

**Histórico próprio.** O app já grava cache em SQLite; guardar um snapshot
semanal de pontos e conquistas permite um gráfico de evolução — algo que **o
site não mostra**. É o argumento mais forte para o app existir.

**Widget na tela inicial.** Streak e pontos. Barato e mantém o app visível.

### 4.3 Baixa prioridade, mas vale registrar

**Tema claro.** `theme.dart` não tem nenhuma referência a `ThemeMode` — o app é
só escuro. Combina com o público, mas exclui quem usa o celular no sol.

**Deep links.** Abrir `retroachievements.org/game/123` direto no app.

**Mais idiomas.** A infraestrutura ARB/gen_l10n já está pronta e testada
(`l10n_test.dart` valida paridade de chaves). Espanhol é o próximo óbvio pelo
tamanho da comunidade de retro.

**Acessibilidade — verificar.** Durante a captura destes prints, um
`uiautomator dump` não retornou nenhum nó de texto. Isso **não prova** um
defeito: o Flutter só constrói a árvore de semântica quando há um leitor de tela
ativo. Mas vale abrir o TalkBack uma vez e percorrer as telas — badges de
raridade e barras de progresso costumam ficar mudos se ninguém colocou
`Semantics` neles.

---

## 5. O que eu **não** recomendo

**Não adicione uma aba de "Estatísticas".** Seria repetir o erro de 1.1 com
outro nome. Os números pertencem ao Perfil.

**Não transforme a busca em aba.** Busca é ação, não destino. Ela cabe na app
bar de Jogos.

**Não mexa na barra inferior sem mover o conteúdo junto.** Promover Desafios e
manter os 8 números duplicados só troca o problema de lugar — a reorganização
das seções (item 2.4) é o que faz a mudança valer.

**Não persiga paridade com o site.** O site já é o site. O que o app tem de
próprio é o cruzamento de desafios com a sua biblioteca e o plano de ataque;
é aí que vale investir.

---

## 6. Ordem sugerida

| Fase | O quê | Por quê primeiro |
|---|---|---|
| 1 | Mover os 4 números e o Streak do Início para o Perfil | Corrige o problema mais grave e não quebra navegação |
| 2 | Fundir Recentes + Progressão na aba Jogos | Libera um slot da barra |
| 3 | Promover Desafios ao slot liberado | Só possível depois da fase 2 |
| 4 | Absorver o heatmap no Perfil e remover a aba Atividade | Fecha a barra em 4 abas |
| 5 | Mural próprio + prêmios no Perfil | Dá substância ao destino que acabou de crescer |
| 6 | Busca nas conquistas do jogo + título de duas linhas | Correções pontuais, independentes |
| 7 | Notificação de streak, comparação, metas | Funcionalidades novas, sobre a base já arrumada |

As fases 1 a 4 são **movimentação de widgets já existentes** entre arquivos.
Nenhuma delas exige endpoint novo, modelo novo ou mudança no cache.
