import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/features/welcome/presentation/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../integration_test/e2e/support/live_harness.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('opens login from the real Welcome at 320x640, scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const WelcomePage()),
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('Bem-vindo de volta!'),
                    TextField(),
                    TextField(),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [routerProvider.overrideWithValue(router)],
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Já tenho uma conta'), findsOneWidget);
      expect(find.text('Já tenho uma conta').hitTestable(), findsNothing);
      await openLiveLogin(tester);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  }

  testWidgets('fills offscreen inputs with keyboard inset and taps submit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: const EdgeInsets.only(bottom: 260)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 650),
                TextField(controller: email),
                const SizedBox(height: 100),
                TextField(controller: password, obscureText: true),
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () => submitted = true,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(TextField).first.hitTestable(), findsNothing);
    await enterLiveText(
      tester,
      find.byType(TextField).at(0),
      'e2e@example.com',
    );
    await enterLiveText(tester, find.byType(TextField).at(1), 'password');
    await tapLive(tester, find.text('Entrar'));
    expect(email.text, 'e2e@example.com');
    expect(password.text, 'password');
    expect(submitted, isTrue);
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .every((field) => !field.focusNode.hasFocus),
      isTrue,
    );
  });

  testWidgets('reveals a lazy panel action without scrolling the page behind', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final background = ScrollController();
    addTearDown(background.dispose);
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ListView(
              controller: background,
              children: [
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      builder: (_, controller) => ListView.builder(
                        controller: controller,
                        itemCount: 25,
                        itemBuilder: (_, index) => index == 24
                            ? TextButton(
                                onPressed: () => tapped = true,
                                child: const Text('Favoritar'),
                              )
                            : const SizedBox(height: 100),
                      ),
                    ),
                  ),
                  child: const Text('Abrir prévia'),
                ),
                const SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      ),
    );
    await tapLive(tester, find.text('Abrir prévia'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritar'), findsNothing);
    await tapLive(
      tester,
      liveFirst(find.text('Favoritar')),
      scrollable: liveScrollable(DraggableScrollableSheet),
    );
    expect(tapped, isTrue);
    expect(background.offset, 0);
  });

  testWidgets('waits for a control before selecting its last match', (
    tester,
  ) async {
    var appeared = false;
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) => Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                  setState(() => appeared = true);
                },
                child: const Text('Abrir'),
              ),
              if (appeared)
                TextButton(
                  onPressed: () => tapped = true,
                  child: const Text('Continuar'),
                ),
            ],
          ),
        ),
      ),
    );
    final action = liveLast(find.text('Continuar'));
    expect(action, findsNothing);
    await tapLive(tester, find.text('Abrir'));
    await tapLive(tester, action);
    expect(tapped, isTrue);
  });
}
