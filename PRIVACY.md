# Política de Privacidade — RA Insights

**Última atualização:** 1 de setembro de 2026
**Contato:** welington.rmonteiro@gmail.com

RA Insights é um aplicativo **não oficial** que lê o seu próprio perfil público
no [RetroAchievements](https://retroachievements.org) e o apresenta em forma de
análise. Não é feito, mantido nem endossado pela equipe do RetroAchievements.

## Resumo

**Não existe servidor deste aplicativo.** Não há backend, banco de dados nem
serviço de análise. O desenvolvedor não recebe, não armazena e não tem qualquer
acesso aos seus dados. O aplicativo fala exclusivamente com a API pública do
RetroAchievements, direto do seu aparelho.

## Quais dados o aplicativo trata

| Dado | Onde fica | Para quê |
|---|---|---|
| Seu nome de usuário do RetroAchievements | No aparelho | Identificar qual perfil consultar |
| Sua chave da Web API do RetroAchievements | No aparelho, em `EncryptedSharedPreferences` (Android Keystore) | Autenticar as chamadas à API |
| Cópia do seu perfil, jogos, conquistas e progresso | No aparelho, em banco SQLite local | Fazer o aplicativo funcionar offline e evitar chamadas repetidas |

Nada disso sai do aparelho, **exceto** o nome de usuário e a chave, que são
enviados ao `retroachievements.org` por HTTPS a cada consulta — é assim que a
API deles autentica você. Esse é o mesmo trajeto que ocorre quando você usa o
site.

## O que o aplicativo NÃO faz

- Não coleta identificadores de publicidade, localização, contatos, câmera,
  microfone, arquivos ou lista de aplicativos instalados.
- Não exibe anúncios e não integra nenhuma SDK de terceiros para publicidade,
  rastreamento ou telemetria.
- Não faz cópia de segurança na nuvem: `allowBackup` está desligado, e a
  transferência entre aparelhos também. Ao trocar de celular você refaz o login.
- Não pede nenhuma permissão além de `INTERNET`.

## Permissões

- `android.permission.INTERNET` — única permissão declarada, necessária para
  consultar a API do RetroAchievements.

## Retenção e exclusão

Todos os dados vivem no armazenamento privado do aplicativo. Para apagar tudo:

1. **Sair** dentro do aplicativo, que remove a chave e o nome de usuário; ou
2. Android → *Configurações* → *Aplicativos* → *RA Insights* → *Armazenamento* →
   *Limpar dados*; ou
3. Desinstalar o aplicativo.

Qualquer uma das opções apaga a chave e o cache local de forma definitiva. Como
o desenvolvedor nunca recebeu esses dados, não há nada a solicitar a ele.

## Sua chave da API

A chave é sua e é obtida por você em
`retroachievements.org/settings` → *Keys* → *Web API Key*. Ela dá acesso de
**leitura** à API. Se você suspeitar de vazamento, gere uma nova nessa mesma
página — a antiga deixa de valer imediatamente.

## Serviços de terceiros

- **RetroAchievements.org** — destino de todas as consultas. Política de
  privacidade: https://retroachievements.org/privacy
- **Google Play** — a distribuição pela loja é regida pelas políticas do Google.

## Crianças

O aplicativo não é direcionado a menores de 13 anos e não coleta dados
conscientemente de crianças.

## Mudanças

Alterações relevantes serão publicadas neste arquivo com nova data no topo.
