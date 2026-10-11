# Corevent Mockups

Plugin local para gerar **todas as telas de usuário do app Flutter** no
Figma Desktop. Usa a Plugin API local, sem MCP, conta da API do Corevent,
chaves de acesso ou requisições de rede durante a execução.

Os arquivos já estão empacotados: **não é necessário instalar Node.js ou
executar um build para importar o plugin**.

## Instalação e uso

1. Abra um arquivo **Figma Design** no Figma Desktop, com permissão de edição.
2. No menu do canvas, vá a **Plugins → Development → Import plugin from manifest…**.
3. Selecione o `manifest.json` desta pasta.
4. Execute **Plugins → Development → Corevent Mockups**.
5. Ajuste o nome ilustrativo, os dias de associação e a saudação.
6. Clique em **Gerar / atualizar mockups**.

O plugin cria **61 frames** de telas, painéis, diálogos e estados, organizados
por fluxo em linhas de até quatro celulares. Os componentes ficam em outro
bloco abaixo, **na página aberta**. Não precisa de uma página adicional.
Se já importou o plugin, basta executá-lo novamente e clicar em
**Gerar / atualizar mockups** para substituir a versão de quatro telas.

Se o Figma solicitar um ID registrado, crie um plugin em **Plugins →
Development → New plugin**, copie o `id` gerado para este `manifest.json`
e importe novamente. Preserve esse ID nas próximas versões: a identificação
privada dos blocos pertence ao ID do plugin.

## Fontes

O Figma precisa disponibilizar **Plus Jakarta Sans** nos estilos Regular,
Medium, SemiBold, Bold e ExtraBold. O plugin verifica os estilos antes de
criar as telas e aceita nomes como `Semi Bold` e `Extra Bold`.

Se informar que a fonte não está disponível, instale Plus Jakarta Sans no
sistema e reinicie o Figma Desktop. A fonte do app fica em
`../../assets/fonts/PlusJakartaSans-VariableFont_wght.ttf`; a família também
está em <https://fonts.google.com/specimen/Plus+Jakarta+Sans>.
Se sua instalação variável não expuser os estilos nomeados, instale uma
distribuição da família que os disponibilize. Não há troca silenciosa de fonte.

## Atualizações e cópias

- **Gerar / atualizar:** substitui os blocos principais criados por este
  plugin na página aberta. Gera e valida os novos blocos antes de remover os
  anteriores. Não substitui os mockups anteriormente criados pelo MCP.
- **Criar uma cópia separada:** adiciona um novo conjunto ao lado do conteúdo
  existente. Essa cópia não é substituída pelo botão de atualização.
- Alterações manuais **dentro dos blocos principais gerados** são substituídas
  na atualização. Para conservar uma versão, crie uma cópia separada.
- Os IDs das telas e componentes são recriados na atualização. Instâncias
  usadas fora dos blocos gerados não recebem atualização automática.
- Se ocorrer erro durante a construção, o plugin remove a construção
  incompleta e conserva os blocos anteriores. Tokens próprios já atualizados
  podem permanecer no arquivo.

## O que é gerado

- Frames Android de **390 × 844**. As abas preservam sua navegação inferior;
  subpáginas e autenticação usam os respectivos layouts. O conteúdo longo
  fica em áreas roláveis no protótipo.
- Textos editáveis, Auto Layout, SVGs Remix e banners como assets de imagem.
- Cards de eventos e ingressos, navegação com quatro variantes, linhas de
  perfil, opções de interesse, campos com estados, botões, seleção de pessoa
  física/jurídica e badges.
- Variáveis de cores com aliases, espaçamentos e raios.
- Fundo e cards brancos nas telas autenticadas; fundo claro da paleta nas
  telas de autenticação, bordas discretas e navegação ativa laranja.
- Nenhuma sombra, gradiente ou glow.

### Telas e variantes

| Grupo                  | Frames | Conteúdo                                                                                                                                                                                                                                                                  |
| ---------------------- | -----: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Navegação principal    |      4 | Início, Explorar, Ingressos e Perfil                                                                                                                                                                                                                                      |
| Entrada e autenticação |     18 | Splash com somente a logo; Welcome; login normal, erro e envio; quatro etapas de cadastro, com alternativas PF/PJ; verificação de cadastro e código inválido; recuperação, verificação de recuperação e redefinição; login após redefinir; falha na restauração da sessão |
| Descoberta e prévia    |      3 | Prévia do evento, falha nos detalhes e resultados de busca                                                                                                                                                                                                                |
| Compra e ingressos     |      7 | Escolher ingressos; pedido pendente, confirmado e cancelado; detalhes do ingresso; QR disponível e indisponível                                                                                                                                                           |
| Conta e atividade      |     10 | Pedidos, detalhes do pedido, favoritos, avaliações, dados pessoais e edição, recorte da foto, prévia e envio da foto, segurança                                                                                                                                           |
| Avaliar e confirmar    |      8 | Avaliação nova, edição e somente leitura; confirmações de logout, remover favorito, remover avaliação, descartar edição e política de idade                                                                                                                               |
| Estados e feedback     |     11 | Início vazio/erro; Explorar sem resultados/erro; Ingressos vazio/erro; pedidos, favoritos e avaliações vazios; validação do campo de login; toast de erro ao atualizar                                                                                                    |

O [catálogo completo](screen-catalog.json) relaciona cada frame ao arquivo
Flutter e, quando existe, à rota. O build lê `lib/app/router.dart` e confere
as **20 rotas públicas**; a geração também confere os 61 frames e suas
referências. A galeria `/design-system`, disponível apenas em debug, é uma
ferramenta interna; seus componentes são representados na biblioteca local.
Não há telas de organizador ou colaborador.

O cadastro mantém topo e rodapé fixos e nascimento em dia/mês/ano. A Splash
não contém texto adicional nem indicador de carregamento. Diálogos usam
títulos e ações em negrito; ações destrutivas são vermelhas. Falhas ao
atualizar preservam os dados e aparecem em toast vermelho, sem card extra.

É uma reprodução visual das telas, não uma conversão automática
do Dart nem um aplicativo funcional dentro do Figma. Nome, eventos, datas,
ingressos, notas e imagens são ilustrativos. O QR codifica apenas
`COREVENT-MOCKUP-NOT-A-TICKET`: **não é um ingresso válido**. A foto usada no
recorte e na prévia é uma ilustração vetorial editável. A navegação entre telas, compra
e chamadas da API não são executadas pelo plugin.

## Alterar os mockups

- `sample-data.json`: dados ilustrativos da conta e dos eventos.
- `renderer.js`: composição, componentes base e layouts das abas.
- `flows.js`: componentes adicionais, telas dos fluxos, painéis e estados.
- `screen-catalog.json`: inventário das telas com referências ao Flutter.
- `runtime.js`: validação, fontes, tokens, atualização e comunicação com o painel.
- `ui.html`: painel do plugin.
- `assets/`: SVGs Remix, QR ilustrativo e os dois banners.
- `build.mjs`: lê a paleta, as rotas e a logo do Flutter e empacota tudo em `code.js`.
- `code.js`: arquivo pronto que o Figma executa; não edite diretamente.

Depois de editar a fonte do plugin, use **Node.js 18 ou superior**, na raiz
do repositório:

```sh
node design/figma-plugin/build.mjs
```

Não há `npm install`, dependências de build, servidor local ou comandos
específicos de Windows. Reabra ou execute novamente o plugin no Figma.
O build confere dados, assets, arquivos de referência, rotas e sintaxe
JavaScript. Durante a geração, o plugin confere inventário, tamanho dos
frames, fonte e ausência de efeitos antes de substituir os blocos anteriores.
A composição final deve ser verificada no Figma Desktop.

## Referências e assets

A composição segue `lib/app/authenticated_shell.dart`, as rotas de
`lib/app/router.dart` e as telas de `lib/features/`. Os caminhos específicos
estão no catálogo. Nenhum código de produção do Flutter é alterado pelo plugin.

- [Plugin API do Figma](https://developers.figma.com/docs/plugins/).
- [Remix Icon](https://github.com/Remix-Design/RemixIcon): SVGs oficiais;
  licença incluída em `assets/REMIX-LICENSE.txt`.
- Banners ilustrativos Unsplash: [evento](https://images.unsplash.com/photo-1492684223066-81342ee5ff30)
  e [microfone](https://images.unsplash.com/photo-1516280440614-37939bbacd81).
  Os arquivos estão incluídos para evitar downloads durante a execução.
