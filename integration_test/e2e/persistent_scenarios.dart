import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/checkout/presentation/checkout_page.dart';
import 'package:corevent_mobile_app/features/checkout/presentation/checkout_view_model.dart';
import 'package:corevent_mobile_app/features/profile/data/avatar_picker.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_details_page.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_page.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/live_harness.dart';

class _AssetAvatarPicker extends AvatarPicker {
  _AssetAvatarPicker() : super(ImagePicker());

  @override
  Future<Uint8List?> pick() async =>
      (await rootBundle.load('assets/images/logo_corevent_full.png')).buffer
          .asUint8List();

  @override
  Future<bool> recover() async => false;
}

void registerPersistentTests() {
  setUpAll(() async {
    validateLiveConfiguration(needsEvent: true, needsFreeTicket: true);
    await initializeDateFormatting('pt_BR');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
  setUp(clearLiveSession);
  tearDown(clearLiveSession);

  testWidgets('ingresso gratuito real gera pedido e QR', (tester) async {
    final container = await openLiveApp(tester);
    try {
      await loginLive(tester, container);
      container.read(routerProvider).go('/events/$e2eEventId/checkout');
      await pumpUntil(
        tester,
        () => !container.read(checkoutViewModelProvider).loading,
      );
      final state = container.read(checkoutViewModelProvider);
      expect(state.error, isNull);
      final freeTypes = state.types.where(
        (type) => type.name == e2eFreeTicketName && type.price == 0,
      );
      expect(freeTypes, hasLength(1));
      final free = freeTypes.single;
      expect(free.availableQuantity, greaterThan(0));
      await tapLive(
        tester,
        find.byTooltip('Adicionar ${free.name}'),
        scrollable: liveScrollable(CheckoutPage),
      );
      await tester.pumpAndSettle();
      expect(container.read(checkoutViewModelProvider).count, 1);
      await tapLive(tester, find.text('Continuar'));
      await pumpUntil(
        tester,
        () =>
            container.read(checkoutViewModelProvider).order != null ||
            container.read(checkoutViewModelProvider).error != null,
      );
      expect(container.read(checkoutViewModelProvider).error, isNull);
      final created = container.read(checkoutViewModelProvider).order!;
      final tickets = await container
          .read(ticketsRepositoryProvider)
          .list(page: 1);
      expect(
        tickets.data.any((ticket) => ticket.order.id == created.orderId),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('Pedido confirmado'), findsOneWidget);
      await tapLive(tester, find.text('Ver meus ingressos'));
      await tester.pumpAndSettle();
      await pumpUntil(
        tester,
        () => !container.read(ticketsViewModelProvider).loading,
      );
      expect(container.read(ticketsViewModelProvider).error, isNull);
      await tapLive(
        tester,
        liveFirst(find.text('Ver QR Code')),
        scrollable: liveScrollable(TicketsPage),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    } finally {
      await closeLiveApp(tester, container);
    }
  });

  testWidgets('foto real é enviada e aparece no perfil', (tester) async {
    final container = await openLiveApp(
      tester,
      providedContainer: ProviderContainer(
        overrides: [
          avatarPickerProvider.overrideWith((ref) => _AssetAvatarPicker()),
        ],
      ),
    );
    try {
      await loginLive(tester, container);
      final before = container.read(authSessionProvider).user?.avatarUrl;
      container.read(routerProvider).go('/profile/details');
      await tester.pumpAndSettle();
      await tapLive(
        tester,
        find.text('Alterar foto'),
        scrollable: liveScrollable(ProfileDetailsPage),
      );
      await pumpUntil(
        tester,
        () => find.text('Continuar').evaluate().isNotEmpty,
      );
      await tapLive(tester, find.text('Continuar'));
      await pumpUntil(
        tester,
        () => find.text('Salvar foto').evaluate().isNotEmpty,
      );
      await tapLive(tester, find.text('Salvar foto'));
      await pumpUntil(
        tester,
        () =>
            container.read(authSessionProvider).user?.avatarUrl != before ||
            find
                .text('Não foi possível enviar a foto. Tente novamente.')
                .evaluate()
                .isNotEmpty,
        timeout: const Duration(seconds: 90),
      );
      final after = container.read(authSessionProvider).user?.avatarUrl;
      expect(after, isNotNull);
      expect(after, isNot(before));
      await container.read(authSessionProvider).refreshProfile();
      expect(container.read(authSessionProvider).user?.avatarUrl, after);
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/profile/details');
      await tester.pumpAndSettle();
      expect(find.text('Foto de perfil'), findsOneWidget);
    } finally {
      await closeLiveApp(tester, container);
    }
  });
}
