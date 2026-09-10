# Formulário de Segurança dos Dados (Play Console)

Respostas para a seção *Política do app → Segurança dos dados*. Elas descrevem o
comportamento real do código; se algo mudar no app, **este arquivo tem que mudar
junto** — divergência aqui é motivo de remoção da loja.

> Aviso honesto: não sou advogado e o Google reserva a interpretação final. As
> respostas abaixo são deliberadamente **conservadoras** — declarar a mais é
> seguro, declarar a menos derruba o app.

## O app coleta ou compartilha algum dos tipos de dados exigidos?

**Sim.** Não porque exista um servidor do desenvolvedor (não existe), mas porque
o nome de usuário e a chave da API **saem do aparelho** rumo ao
`retroachievements.org`. Pela definição do Google, dado que trafega para fora do
dispositivo é "coletado", e para um terceiro é "compartilhado".

## Tipos de dados

### Informações pessoais → IDs do usuário
- Coletado: **Sim**
- Compartilhado: **Sim** (com o retroachievements.org, o serviço que o usuário
  escolheu consultar)
- Obrigatório ou opcional: **Obrigatório** — sem o nome de usuário não há o que
  analisar
- Finalidades: **Funcionalidade do app**
- Usado para rastreamento de usuários em apps/sites de terceiros: **Não**

### Informações pessoais → Outras informações (chave da Web API)
- Coletado: **Sim**
- Compartilhado: **Sim** (enviado ao retroachievements.org para autenticar)
- Obrigatório: **Sim**
- Finalidades: **Funcionalidade do app** / **Autenticação**
- Rastreamento: **Não**

### Todos os demais tipos
**Não coletados.** Sem localização, sem contatos, sem fotos, sem arquivos, sem
mensagens, sem áudio, sem informações financeiras, sem histórico de navegação,
sem lista de apps instalados, sem identificadores de publicidade, sem
diagnóstico ou telemetria de qualquer espécie.

## Práticas de segurança

- **Os dados são criptografados em trânsito?** **Sim** — todo o tráfego é HTTPS
  para `retroachievements.org`.
- **Existe forma de o usuário solicitar exclusão dos dados?** **Sim** — sair do
  app, limpar os dados nas configurações do Android ou desinstalar. Como nada
  chega ao desenvolvedor, não há solicitação a fazer a ele.
- **O app segue a Política de Famílias do Google Play?** Não é direcionado a
  crianças.
- **Passou por revisão de segurança independente?** **Não.**

## Anúncios, compras e conteúdo

- Contém anúncios: **Não**
- Compras no app: **Não**
- Público-alvo: **13 anos ou mais**
- Classificação indicativa (questionário IARC): sem violência, sem conteúdo
  sexual, sem linguagem imprópria, sem jogos de azar, sem interação entre
  usuários dentro do app, sem compartilhamento de localização. Resultado
  esperado: **Livre / Everyone**.
  ⚠️ O app *exibe* comentários do mural do perfil, escritos por outros usuários
  no site do RetroAchievements. Isso é conteúdo gerado por usuário vindo de fora.
  Ao responder o questionário, declarar que o app **exibe** conteúdo de usuários
  mas **não permite** que usuários interajam ou publiquem por dentro dele.

## Coleta de dados: resumo em uma frase para a ficha

> O app não possui servidor próprio. Nome de usuário e chave de API ficam
> criptografados no aparelho e são enviados apenas ao retroachievements.org, por
> HTTPS, para autenticar as consultas ao seu próprio perfil.
