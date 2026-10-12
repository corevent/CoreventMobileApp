import 'dart:async';

import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/auth/presentation/login_view_model.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/events/domain/event_catalog.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_page.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_view_model.dart';
import 'package:corevent_mobile_app/features/profile/presentation/activity_view_model.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_page.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_page.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/live_harness.dart';

void registerReadOnlyTests() {
  setUpAll(() async {
    validateLiveConfiguration(needsEvent: true);
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearLiveSession);
  tearDown(clearLiveSession);

  testWidgets('login real, abas e logout', (tester) async {
    final container = await openLiveApp(tester);
    try {
      await loginLive(tester, container);
      expect(container.read(authSessionProvider).user?.email, e2eEmail);
      for (final tab in ['Explorar', 'Ingressos', 'Perfil', 'Início']) {
        await tapLive(tester, liveLast(find.text(tab)));
        await tester.pumpAndSettle();
      }
      await tapLive(tester, liveLast(find.text('Perfil')));
      await tester.pumpAndSettle();
      await tapLive(
        tester,
        find.text('Sair da conta'),
        scrollable: liveScrollable(ProfilePage),
      );
      await tester.pumpAndSettle();
      await tapLive(tester, liveLast(find.text('Sair')));
      await pumpUntil(
        tester,
        () =>
            container.read(authSessionProvider).status ==
            SessionStatus.unauthenticated,
      );
      expect(find.text('Já tenho uma conta'), findsOneWidget);
    } finally {
      await closeLiveApp(tester, container);
    }
  });

  testWidgets('senha incorreta permite corrigir e entrar', (tester) async {
    final container = await openLiveApp(tester);
    try {
      await openLiveLogin(tester);
      await enterLiveText(tester, find.byType(TextField).at(0), e2eEmail);
      await enterLiveText(
        tester,
        find.byType(TextField).at(1),
        'senha-incorreta-e2e',
      );
      await submitLiveLogin(tester);
      await pumpUntil(tester, () {
        final login = container.read(loginViewModelProvider);
        return !login.busy && login.error != null;
      });
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(
        container.read(authSessionProvider).status,
        SessionStatus.unauthenticated,
      );
      await enterLiveText(tester, find.byType(TextField).at(1), e2ePassword);
      await submitLiveLogin(tester);
      await waitForLiveLogin(tester, container);
    } finally {
      await closeLiveApp(tester, container);
    }
  });

  testWidgets('sessão restaurada e consulta real de eventos', (tester) async {
    var container = await openLiveApp(tester);
    try {
      await loginLive(tester, container);
      final event = await container
          .read(eventsRepositoryProvider)
          .detail(e2eEventId);
      expect(event.id, e2eEventId);
      expect(event.title, isNotEmpty);
      await closeLiveApp(tester, container);
      container = await openLiveApp(tester);
      expect(
        container.read(authSessionProvider).status,
        SessionStatus.authenticated,
      );
      expect(container.read(authSessionProvider).user?.email, e2eEmail);
    } finally {
      await closeLiveApp(tester, container);
    }
  });

  testWidgets('Explorar busca evento real e limpa o filtro', (tester) async {
    final container = await openLiveApp(tester);
    try {
      await loginLive(tester, container);
      final event = await container
          .read(eventsRepositoryProvider)
          .detail(e2eEventId);
      await tapLive(tester, liveLast(find.text('Explorar')));
      await tester.pumpAndSettle();
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(container.read(exploreViewModelProvider).error, isNull);
      await enterLiveText(
        tester,
        liveFirst(find.byType(TextField)),
        event.title,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      final found = container.read(exploreViewModelProvider);
      expect(found.error, isNull);
      expect(
        found.events.any((item) => item.id == e2eEventId),
        isTrue,
        reason: 'O evento de teste precisa estar aberto e pesquisável.',
      );
      final card = liveLast(find.text(event.title));
      await tapLive(tester, card, scrollable: liveScrollable(ExplorePage));
      await tester.pumpAndSettle();
      expect(find.text('Prévia do evento'), findsOneWidget);
      await tapLive(tester, find.byTooltip('Fechar prévia'));
      await tester.pumpAndSettle();
      await tapLive(tester, find.byTooltip('Limpar busca'));
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(container.read(exploreViewModelProvider).search, isEmpty);

      final category = find.widgetWithText(
        ChoiceChip,
        EventCatalog.categoryLabel(event.category),
      );
      await tapLive(tester, category);
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(container.read(exploreViewModelProvider).category, event.category);
      await enterLiveText(
        tester,
        liveFirst(find.byType(TextField)),
        event.title,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(
        container
            .read(exploreViewModelProvider)
            .events
            .any((item) => item.id == e2eEventId),
        isTrue,
      );
      await tapLive(tester, liveLast(find.text('Limpar filtros')));
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(container.read(exploreViewModelProvider).category, isNull);

      final impossible =
          'corevent-e2e-${DateTime.now().microsecondsSinceEpoch}';
      await enterLiveText(
        tester,
        liveFirst(find.byType(TextField)),
        impossible,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      expect(container.read(exploreViewModelProvider).events, isEmpty);
      expect(find.text('Nenhum evento encontrado'), findsOneWidget);
      await tapLive(tester, liveLast(find.text('Limpar filtros')));
      await pumpUntil(
        tester,
        () => !container.read(exploreViewModelProvider).loading,
      );
      final pageBefore = container.read(exploreViewModelProvider).page;
      if (container.read(exploreViewModelProvider).hasMore) {
        await tapLive(
          tester,
          find.text('Carregar mais eventos'),
          scrollable: liveScrollable(ExplorePage),
        );
        await pumpUntil(
          tester,
          () => !container.read(exploreViewModelProvider).loadingMore,
        );
        expect(
          container.read(exploreViewModelProvider).page,
          greaterThan(pageBefore),
        );
      }
    } finally {
      await closeLiveApp(tester, container);
    }
  });

  testWidgets('Pedidos e Ingressos consultam a API real', (tester) async {
    final container = await openLiveApp(tester);
    try {
      await loginLive(tester, container);
      await tapLive(tester, liveLast(find.text('Ingressos')));
      await pumpUntil(
        tester,
        () => !container.read(ticketsViewModelProvider).loading,
      );
      expect(container.read(ticketsViewModelProvider).error, isNull);
      expect(
        container.read(ticketsViewModelProvider).items,
        isNotEmpty,
        reason: 'A conta de E2E precisa ter um ingresso ativo para testar QR.',
      );
      final qrAction = liveFirst(find.text('Ver QR Code'));
      await tapLive(tester, qrAction, scrollable: liveScrollable(TicketsPage));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      await tapLive(tester, find.byTooltip('Voltar aos ingressos'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();
      await tapLive(
        tester,
        find.text('Pedidos'),
        scrollable: liveScrollable(ProfilePage),
      );
      await pumpUntil(
        tester,
        () => !container.read(ordersViewModelProvider).loading,
      );
      expect(container.read(ordersViewModelProvider).error, isNull);
      expect(
        container.read(ordersViewModelProvider).items,
        isNotEmpty,
        reason: 'A conta de E2E precisa ter ao menos um pedido.',
      );
      await tapLive(tester, liveFirst(find.byType(ListTile)));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do pedido'), findsWidgets);
      unawaited(container.read(routerProvider).push('/profile/details'));
      await tester.pumpAndSettle();
      expect(find.text('Dados pessoais'), findsWidgets);
    } finally {
      await closeLiveApp(tester, container);
    }
  });
}
