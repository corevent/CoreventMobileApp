# Corevent

Aplicativo Flutter para descobrir eventos, comprar ingressos e gerenciar compras e atividades da conta. Desenvolvido com foco em mobile e arquitetura Feature-first + MVVM.

## Targets

- Android.
- Web.

## Stack

- Flutter e Dart.
- Riverpod para estado e injeção de dependências.
- Dio e Retrofit para comunicação com a API.
- Freezed e json_serializable para modelos e serialização.
- go_router para navegação.
- Drift, shared_preferences e flutter_secure_storage para armazenamento.
- qr_flutter, url_launcher e app_links para ingressos e pagamento.
- image_picker, crop_your_image e image para a foto de perfil.
- Plus Jakarta Sans e Remix Icons.
- flutter_test e mocktail para testes.

## Pré-requisitos

- Flutter com Dart compatível com `^3.13.4`.
- Android SDK e emulador ou dispositivo físico para Android.
- Chrome para desenvolvimento Web.

## Como executar

Na raiz do repositório, instale as dependências e gere o código:

```sh
flutter pub get
dart run build_runner build
```

Web:

```sh
flutter run -d chrome
```

Android:

```sh
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

Substitua `ID_DO_DISPOSITIVO` pelo identificador listado em `flutter devices`. A API de produção já está configurada no aplicativo.

## Build

Android:

```sh
flutter build apk --release
flutter build appbundle --release
```

Para distribuição, configure a assinatura e o identificador do aplicativo Android.

Web:

```sh
flutter build web
```

Os arquivos Web ficam em `build/web/`. Sirva o diretório completo, incluindo os recursos do Drift.

## Funcionalidades

- Cadastro com verificação de e-mail, login e recuperação de senha.
- Sessão persistente e logout.
- Descoberta de eventos, busca, categorias e prévia dos detalhes.
- Favoritos e avaliações, com edição quando o identificador está disponível.
- Seleção de ingressos, pagamento externo e acompanhamento de pedidos.
- Listagem de ingressos e visualização do QR Code.
- Perfil, edição de dados pessoais, foto e alteração de senha.
- Interface responsiva, fonte ampliada e animações com respeito a movimento reduzido.

## Verificação

```sh
dart tool/format.dart --check
flutter analyze
flutter test
```

Para aplicar a formatação, execute `dart tool/format.dart`.
