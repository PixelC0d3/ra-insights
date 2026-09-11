# RA Insights — Wiki

Guia de telas do app, tela por tela e ponto por ponto. Serve tanto para quem
vai testar quanto para lembrar, meses depois, por que cada coisa está do jeito
que está.

**Não é a documentação de código** — para isso, `README.md` (arquitetura,
como rodar, como buildar) e `RELEASE.md` (publicação na Play Store) na raiz do
projeto. Aqui é telas e comportamento.

App **não oficial**, sem vínculo com o RetroAchievements. Lê o perfil público
do usuário pela Web API oficial; não existe servidor, cada pessoa usa a
própria chave.

## Navegação

4 abas fixas na parte de baixo:

| Aba | Página desta wiki | O que responde |
|---|---|---|
| 🏠 Início | [Inicio](Inicio.md) | "o que eu jogo agora?" |
| 🎮 Jogos | [Jogos](Jogos.md) | "como estou indo, jogo a jogo e console a console?" |
| 🏆 Desafios | [Desafios](Desafios.md) | "quais events do RA eu ainda não terminei?" |
| 👤 Perfil | [Perfil](Perfil.md) | "qual é o meu retrato completo na plataforma?" |

Fora da barra, alcançáveis por um ícone de busca ou por um toque num nome de
usuário:

- [Busca e Jogadores](Busca-e-Jogadores.md) — achar um jogo já jogado ou o
  perfil de outra pessoa
- [Ajustes](Ajustes.md) — conta, chave da API, idioma, cache

## Como as imagens foram capturadas

Emulador Android, 1080×2400 (Pixel, densidade 420), PNG cheio por tela — sem
recorte, para poder medir espaçamento se precisar. Ficam em `wiki/img/` (cópia
independente do índice de design em `design/screens/`, que é a fonte "viva"
usada para Figma).
