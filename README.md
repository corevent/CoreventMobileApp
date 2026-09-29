# Corevent Flutter

Aplicativo para descobrir eventos, comprar ingressos e acompanhar compras e atividades da conta. É o port do cliente .NET MAUI para Flutter, com interface mobile-first e arquitetura Feature-first + MVVM.

O aplicativo atende ao público consumidor. Não inclui painéis de organizador ou colaborador.

## Targets

| Plataforma | Uso |
| --- | --- |
| Android | Aplicativo mobile, em emulador ou dispositivo físico |
| Web | Aplicação responsiva no navegador |

## Stack

| Tecnologia | Finalidade |
| --- | --- |
| Flutter + Dart | Interface e lógica da aplicação |
| Riverpod | Estado e injeção de dependências |
| Dio + Retrofit | Comunicação com a API REST |
| Freezed + json_serializable | Estados, modelos e serialização |
| go_router | Rotas, proteção de acesso e navegação por abas |
| Drift + drift_flutter | Infraestrutura de banco local |
| shared_preferences | Preferências e identificadores não sensíveis |
| flutter_secure_storage | Armazenamento de tokens de autenticação |
| qr_flutter | QR Code do ingresso |
| url_launcher + app_links | Pagamento externo e retorno ao aplicativo |
| image_picker + crop_your_image + image | Seleção, enquadramento e preparação do avatar |
| flutter_test + mocktail | Testes automatizados |
| Plus Jakarta Sans + Remix Icons | Tipografia e ícones |

As versões das dependências estão em [pubspec.yaml](pubspec.yaml) e [pubspec.lock](pubspec.lock).

## Pré-requisitos

- Flutter instalado e disponível no terminal, com Dart compatível com `^3.13.4`, conforme o `pubspec.yaml`.
- Para Android: Android SDK, JDK compatível com o Gradle/Android Gradle Plugin do projeto e um emulador ou aparelho com depuração USB habilitada. Android Studio pode ser usado para configurar o ambiente.
- Para Web: Chrome para execução em desenvolvimento.
- API Corevent acessível pelo dispositivo ou navegador. Upload de avatar e pagamento dependem também dos serviços externos configurados no backend.

Confira o ambiente e os dispositivos disponíveis:

```sh
flutter doctor
flutter devices
```

## Como executar

### 1. Preparar o projeto

Na pasta que contém este repositório:

```sh
cd corevent_mobile_app
flutter pub get
dart run build_runner build
```

Execute os demais comandos abaixo na raiz de `corevent_mobile_app/`.

### 2. Configurar a API

Informe a URL com `--dart-define=COREVENT_API_URL=...` ao executar ou gerar o build.

| Ambiente | Exemplo de URL para API local |
| --- | --- |
| Web na máquina da API | `http://localhost:3000/` |
| Emulador Android padrão | `http://10.0.2.2:3000/` |
| Celular físico na mesma rede | `http://IP_DA_MAQUINA:3000/` |

Substitua `IP_DA_MAQUINA` pelo endereço acessível do computador na rede. `0.0.0.0` é o endereço de escuta do servidor, não um endereço para configurar no aplicativo.

Sem `COREVENT_API_URL`, o fallback atual é `http://192.168.1.7:3000/`, definido em `lib/core/network/network_providers.dart`. Não há seleção automática de URL por plataforma.

O Android de desenvolvimento permite HTTP local. Na Web, a API precisa permitir a origem do aplicativo via CORS; para o armazenamento seguro, sirva o aplicativo em HTTPS ou localhost. O storage de imagens também precisa permitir a origem e o PUT com `Content-Type`.

### 3. Executar na Web

```sh
flutter run -d chrome --dart-define=COREVENT_API_URL=http://localhost:3000/
```

### 4. Executar no Android

Use o identificador listado por `flutter devices` no lugar de `ID_DO_DISPOSITIVO`.

Emulador:

```sh
flutter run -d ID_DO_DISPOSITIVO --dart-define=COREVENT_API_URL=http://10.0.2.2:3000/
```

Celular físico:

```sh
flutter run -d ID_DO_DISPOSITIVO --dart-define=COREVENT_API_URL=http://IP_DA_MAQUINA:3000/
```

## Build

### Android — APK de desenvolvimento

```sh
flutter build apk --debug --dart-define=COREVENT_API_URL=http://IP_DA_MAQUINA:3000/
```

Saída: `build/app/outputs/flutter-apk/app-debug.apk`.

### Android — APK e App Bundle de release

Substitua `https://SUA_API/` pelo endereço do ambiente desejado:

```sh
flutter build apk --release --dart-define=COREVENT_API_URL=https://SUA_API/
flutter build appbundle --release --dart-define=COREVENT_API_URL=https://SUA_API/
```

Saídas: `build/app/outputs/flutter-apk/app-release.apk` e `build/app/outputs/bundle/release/app-release.aab`.

A configuração atual de release usa a assinatura de debug e o identificador `com.example.corevent_mobile_app`. Configure assinatura e identificador de distribuição antes de publicar.

### Web

```sh
flutter build web --dart-define=COREVENT_API_URL=https://SUA_API/
```

Saída: `build/web/`. Sirva o diretório completo, incluindo `drift_worker.js` e `sqlite3.wasm`; o servidor deve responder ao `.wasm` com `Content-Type: application/wasm`. Os binários Web do Drift presentes no projeto correspondem à versão 2.35.0.

## Funcionalidades

### Autenticação

- Welcome, login e sessão persistente.
- Cadastro em quatro etapas: nome/nascimento, pessoa física ou jurídica, documento e credenciais.
- Validação de CPF/CNPJ, senha e código de verificação de e-mail.
- Recuperação e redefinição de senha, com reenvio do código.
- Renovação de tokens e recuperação da sessão após falhas de rede.
- Logout com limpeza dos dados privados da sessão.

### Descoberta de eventos

- Abas Início, Explorar, Ingressos e Perfil.
- Home com saudação fixa, destaque, categorias, favoritos, fim de semana, eventos online e demais experiências, conforme o conteúdo disponível.
- Busca e filtros no Explorar, com paginação e critérios recebidos dos atalhos da Home.
- Cards com banner superior, categoria, favorito, título, data, local e avaliação quando disponível.
- Prévia do evento com detalhes carregados sob demanda.
- Exclusão de eventos encerrados da descoberta e restrição de eventos +18 quando a maioridade não é confirmada.
- Atualização por swipe, com dados preservados durante o carregamento e erros apresentados em toast.

### Favoritos e avaliações

- Favoritar pela Home, Explorar e prévia do evento.
- Listagem de favoritos com filtros por estado do evento e confirmação de remoção.
- Avaliação de uma a cinco estrelas na prévia e histórico de avaliações na conta.
- Edição e remoção de avaliações quando o identificador é fornecido.

### Compra e pedidos

- Seleção de tipos e quantidades de ingressos.
- Revalidação de preço, disponibilidade, estado do evento e restrição etária antes de criar o pedido.
- Pedidos separados para ingressos gratuitos e pagos e aceite de política etária quando exigido.
- Pagamento externo pelo link retornado pela API.
- Acompanhamento do pedido, atualização ao retomar o app e retorno Android via `corevent://orders`.
- Consulta a Pedidos quando a criação tem resultado incerto, evitando repetição automática do envio.

### Ingressos

- Listagem paginada de ingressos reais, com evento, tipo e status.
- Detalhes do ingresso e QR Code a partir do token retornado pela API.
- Consulta do status ao abrir o código; sua validação no check-in ocorre no servidor.
- QR Code disponível conforme as regras de status do ingresso e pagamento, sem persistir o token no dispositivo.

### Conta e perfil

- Cabeçalho fixo com avatar, nome e tempo de associação quando disponível.
- Acesso a Pedidos, Favoritos, Avaliações, Dados pessoais e Segurança.
- Visualização dos dados pessoais e edição de nome e telefone.
- Alteração de senha.
- Foto de perfil com seleção, enquadramento, prévia, upload e confirmação.
- Confirmação ao descartar alterações e sair da conta.

## Interface

A interface usa Plus Jakarta Sans, Remix Icons, superfícies claras, bordas sutis e a paleta Corevent. Não usa sombras, gradientes, glow ou shimmer. A splash contém somente a logo durante o carregamento.

Os layouts consideram teclado aberto e fonte ampliada. O cadastro mantém topo e rodapé fixos, com formulário rolável; as etapas trocam por fade-out seguido de fade-in. As animações respeitam a preferência do sistema por movimento reduzido.

Em desenvolvimento, `/design-system` permite conferir os componentes. Essa rota não é incluída no build de produção.

## Estrutura do projeto

```text
lib/
  app/              # Inicialização, rotas e navegação principal
  core/             # Tema, componentes, rede, armazenamento e banco
  features/         # Features com apresentação, dados e domínio
test/               # Testes automatizados
assets/             # Logo e fonte
android/            # Target Android
web/                # Target Web e recursos do Drift
```

ViewModels Riverpod coordenam os estados e ações; repositórios concentram o acesso aos dados. As convenções detalhadas para desenvolvimento e agentes estão no [AGENTS.md](AGENTS.md).

## Testes e análise

### Lint e formatação

O projeto usa flutter_lints com checagens estritas de tipos e regras adicionais para estilo, futures e recursos. A configuração está em `analysis_options.yaml`. O [formatter oficial do Dart](https://dart.dev/tools/dart-format) usa 80 colunas; `.editorconfig` padroniza UTF-8, LF e indentação com dois espaços, e `.gitattributes` preserva LF no Git para Dart, YAML, JSON e Markdown. O VS Code formata arquivos Dart ao salvar, usando a extensão Dart recomendada pelo projeto.

Para formatar os arquivos fonte ou conferir a formatação sem alterar arquivos:

```sh
dart tool/format.dart
dart tool/format.dart --check
```

O comando inclui `lib/`, `test/` e `tool/` e exclui arquivos gerados `*.g.dart` e `*.freezed.dart`. Em modo `--check`, retorna um código de erro quando há arquivos fora do padrão. Arquivos gerados são atualizados com build_runner.

### Verificações

```sh
flutter analyze
flutter test
```

Para executar um arquivo específico:

```sh
flutter test test/home_redesign_test.dart
```

Os testes usam flutter_test e mocktail para validações, repositórios, ViewModels e widgets, incluindo paginação, erros, checkout, QR Code, avatar e fonte ampliada. Ao alterar modelos ou clientes gerados, execute novamente `dart run build_runner build`.

Testes com mocks e builds não substituem a conferência em navegador/dispositivo com API e serviços configurados, especialmente para persistência de sessão, upload de foto, pagamento e check-in.

## Limitações atuais

- O cadastro ainda envia telefone e avatar técnicos fixos, isolados em `lib/features/auth/domain/registration_draft.dart` por compatibilidade com o contrato existente.
- A listagem de avaliações não fornece `ratingId` no contrato atual. Avaliações sem esse identificador são somente consultadas; as criadas na sessão podem usar o identificador retornado pela criação para edição e remoção.
- A descoberta ordena os eventos carregados, sem garantia de ordenação global da API. Não apresenta popularidade ou personalização que o backend não fornece.
