# Publicar o RA Insights na Google Play

Passo a passo do que está pronto no repositório e do que só você pode fazer.

---

## 1. Gerar a chave de upload (uma vez)

```bash
tool/make_keystore.sh
```

O script pergunta a senha — **escolha uma você**, ela não é gerada nem gravada em
nenhum lugar além de `android/key.properties`, que está no `.gitignore`.

Ele cria `~/.keys/ra-insights-upload.jks` (RSA 4096, validade ~27 anos) e escreve
o `key.properties` correspondente.

> **Faça backup do `.jks` e da senha fora desta máquina.** Perder a chave de
> upload significa não conseguir mais publicar atualizações nesta ficha. Ative o
> **Play App Signing** ao criar o app no console — ele guarda a chave de
> *assinatura* e permite trocar a de *upload* caso você perca a sua; sem ele não
> há recuperação nenhuma.

Conferir depois:
```bash
keytool -list -v -keystore ~/.keys/ra-insights-upload.jks -alias upload
```

## 2. Gerar o pacote

```bash
export JAVA_HOME=~/toolchain/jdk        # este ambiente não define isso sozinho
export PATH=$JAVA_HOME/bin:~/toolchain/flutter/bin:$PATH

flutter build appbundle --release
```

Saída: `build/app/outputs/bundle/release/app-release.aab` — é este arquivo que
sobe para a Play, não um APK.

Sem `android/key.properties`, o build **cai para a chave de debug** de propósito,
para que um clone novo ainda compile. Um `.aab` assinado em debug é rejeitado
pela loja; confira antes de subir:

```bash
$JAVA_HOME/bin/keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```
O emissor tem que ser o seu, não `CN=Android Debug`.

### Sobre os 60 MB do `.aab`

Não se assuste: **~50 MB são símbolos de depuração** (`BUNDLE-METADATA/...
debugsymbols/*.sym`) e o mapa do R8. A Play remove tudo isso e entrega ao
aparelho apenas a fatia da arquitetura dele — o download real fica na casa dos
15 MB. Confira a estimativa em *Versões → Detalhes* depois do upload.

### Mapeamento de ofuscação
O R8 está ligado (`isMinifyEnabled = true`). O Gradle gera
`build/app/outputs/mapping/release/mapping.txt`; o `flutter build appbundle` já
embute o mapeamento no `.aab`, então os stack traces do Play Console chegam
legíveis sem upload manual.

## 3. Criar o app no Play Console

- Nome: **RA Insights**
- Nome do pacote: **com.pixelc0d3.rainsights** (igual ao `applicationId`; não muda depois de publicado)
- Idioma padrão: **Inglês (EUA)** — decisão tomada; adicionar **Português (Brasil)** como tradução
- Tipo: App · Gratuito
- Textos: `store/pt-BR/listing.md` e `store/en-US/listing.md`
- Ícone 512×512: `store/graphics/icon-512.png`
- Gráfico de destaque 1024×500: `store/graphics/feature-1024x500.png`
- Segurança dos dados: `store/data-safety.md`

---

## O que ainda depende de você

Nada abaixo é código — são decisões e contas que só você pode resolver.

### 🔴 1. Acesso do app para a revisão (bloqueante)

O revisor do Google abre o app e trava na tela de login: ele não tem conta no
RetroAchievements nem Web API Key. **Uma revisão que não consegue passar da
primeira tela é reprovada.**

Em *Política do app → Acesso ao app*, escolher **"Todas as funcionalidades
exigem credenciais"** e fornecer usuário e chave. Duas opções:

- **Criar uma conta descartável** no retroachievements.org só para revisão, jogar
  alguma coisa para o perfil não ficar vazio, e entregar a chave dela. **É o que
  eu recomendo** — a chave é de leitura, mas é sua identidade no site.
- Entregar a sua própria conta e chave. Funciona, mas expõe a sua chave a um
  processo de revisão; se fizer isso, gere uma nova chave depois de aprovado.

Nas instruções, escreva também que a chave sai de
`retroachievements.org/settings → Keys → Web API Key`, porque o revisor não vai
saber disso sozinho.

### 🟢 2. URL da política de privacidade — resolvido

O repositório `PixelC0d3/ra-insights` é público, então o próprio arquivo serve:

```
https://github.com/PixelC0d3/ra-insights/blob/main/PRIVACY.md
```

Cole em *Política do app → Política de Privacidade*. Se quiser uma página mais
limpa, ligue o GitHub Pages (Settings → Pages → branch `main`, pasta raiz) e use
`https://pixelc0d3.github.io/ra-insights/PRIVACY` — a URL de `blob` já é aceita.

### 🟡 3. Teste fechado de 14 dias

Contas de desenvolvedor **pessoais** criadas depois de novembro de 2023 precisam
rodar um teste fechado com **pelo menos 12 testadores por 14 dias seguidos**
antes de liberar produção. Vale a pena confirmar no seu console qual regra se
aplica à sua conta antes de planejar a data de lançamento — se ela se aplicar,
some duas semanas ao cronograma.

### 🟡 4. Marca "RetroAchievements"

O nome do app evita a marca (é "RA Insights"), e as fichas dizem em letras
maiúsculas que ele é **não oficial** — que é o que a política de propriedade
intelectual do Google exige. Ainda assim:

- Não use o logotipo do RetroAchievements no ícone nem nas capturas.
- Vale avisar a equipe do RA (fórum ou Discord) antes de publicar. Uma
  reclamação de marca depois da publicação derruba a ficha; um aviso antes
  costuma render só um "beleza".

### 🟡 5. Decisão ainda em aberto: chave por usuário

Hoje cada pessoa informa a própria chave. O outro app do gênero embute a chave do
desenvolvedor no APK — foi possível extraí-la com `unzip` e `grep`. **Continuo
recomendando manter a chave por usuário:** embutir a sua significa que qualquer
um extrai, e todo o tráfego do app passa a responder pela sua conta, incluindo
eventual banimento por abuso.

O custo é real e é o item 1 desta lista: uma barreira na primeira tela. Se um dia
quiser derrubá-la, o caminho honesto é um proxy próprio — o que contradiz o
"sem servidor" da ficha e da política de privacidade.

### 🟢 6. Capturas de tela

Ainda faltam. A Play pede no mínimo **2** por formato (telefone: 16:9 ou 9:16,
lado menor ≥ 320px, maior ≤ 3840px). Sugestão de 6, na ordem em que contam a
história: Painel · Raridade num jogo · Mais raras · Desafios · Plano de desafio ·
Perfil.

Do emulador, já no tamanho certo:
```bash
adb exec-out screencap -p > store/graphics/phone-01.png
```

### 🟢 7. Versão

`pubspec.yaml` está em `version: 0.1.0+1` → `versionName 0.1.0`, `versionCode 1`.
A Play recusa reenvio de um `versionCode` já usado: **incremente o `+N` a cada
upload**, mesmo em teste interno.
