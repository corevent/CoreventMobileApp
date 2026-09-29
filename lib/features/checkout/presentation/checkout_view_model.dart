import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_session.dart';
import '../../events/data/event_dtos.dart';
import '../../events/domain/event_visibility.dart';
import '../data/checkout_dtos.dart';
import '../data/checkout_repository.dart';

class CheckoutState {
  const CheckoutState({
    this.eventId,
    this.event,
    this.types = const [],
    this.quantities = const {},
    this.loading = true,
    this.submitting = false,
    this.error,
    this.notice,
    this.uncertain = false,
    this.order,
  });
  final String? eventId;
  final EventDetail? event;
  final List<CheckoutTicketType> types;
  final Map<String, int> quantities;
  final bool loading;
  final bool submitting;
  final String? error;
  final String? notice;
  final bool uncertain;
  final CreatedOrder? order;

  int quantity(String id) => quantities[id] ?? 0;
  double get total =>
      types.fold(0, (sum, type) => sum + type.price * quantity(type.id));
  int get count => quantities.values.fold(0, (sum, amount) => sum + amount);
}

class CheckoutViewModel extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> load(String eventId) async {
    state = CheckoutState(eventId: eventId, loading: true);
    try {
      final catalog = await ref
          .read(checkoutRepositoryProvider)
          .catalog(eventId);
      if (!ref.mounted || state.eventId != eventId) return;
      final user = ref.read(authSessionProvider).user;
      if ((catalog.event.status != null && catalog.event.status != 'opened') ||
          !catalog.event.endDate.toLocal().isAfter(DateTime.now())) {
        state = CheckoutState(
          eventId: eventId,
          event: catalog.event,
          loading: false,
          error: 'Este evento não está disponível para compra.',
        );
        return;
      }
      if (catalog.event.isAdultOnly &&
          !isAdult(user?.birthDate, DateTime.now())) {
        state = CheckoutState(
          eventId: eventId,
          event: catalog.event,
          loading: false,
          error: 'Este evento exige idade mínima de 18 anos.',
        );
        return;
      }
      state = CheckoutState(
        eventId: eventId,
        event: catalog.event,
        types: catalog.types,
        loading: false,
      );
    } catch (_) {
      if (ref.mounted && state.eventId == eventId) {
        state = CheckoutState(
          eventId: eventId,
          loading: false,
          error: 'Não foi possível carregar os ingressos.',
        );
      }
    }
  }

  void setQuantity(CheckoutTicketType type, int quantity) {
    if (state.submitting || state.order != null || state.uncertain) return;
    final max = type.price == 0 ? 1 : type.availableQuantity;
    final next = quantity.clamp(0, max).toInt();
    final selected = Map<String, int>.from(state.quantities);
    final otherKindSelected = state.types.any(
      (item) =>
          item.id != type.id &&
          (selected[item.id] ?? 0) > 0 &&
          (item.price == 0) != (type.price == 0),
    );
    if (next > 0 && otherKindSelected) {
      selected.clear();
    }
    if (next == 0) {
      selected.remove(type.id);
    } else {
      selected[type.id] = next;
    }
    state = CheckoutState(
      eventId: state.eventId,
      event: state.event,
      types: state.types,
      quantities: selected,
      loading: false,
      notice: next > 0 && otherKindSelected
          ? 'Ingressos gratuitos e pagos precisam de pedidos separados.'
          : null,
    );
  }

  Future<AgePolicy?> submit({bool policyAccepted = false}) async {
    if (state.submitting ||
        state.loading ||
        state.uncertain ||
        state.order != null ||
        state.count == 0) {
      return null;
    }
    final eventId = state.eventId;
    if (eventId == null) return null;
    state = CheckoutState(
      eventId: eventId,
      event: state.event,
      types: state.types,
      quantities: state.quantities,
      loading: false,
      submitting: true,
    );
    try {
      final latest = await ref
          .read(checkoutRepositoryProvider)
          .catalog(eventId);
      if (!ref.mounted || state.eventId != eventId) return null;
      final now = DateTime.now();
      final user = ref.read(authSessionProvider).user;
      if (latest.event.status != null && latest.event.status != 'opened' ||
          !latest.event.endDate.toLocal().isAfter(now)) {
        _stop('Este evento não está disponível para compra.', latest);
        return null;
      }
      if (latest.event.isAdultOnly && !isAdult(user?.birthDate, now)) {
        _stop('Este evento exige idade mínima de 18 anos.', latest);
        return null;
      }
      final current = {for (final type in latest.types) type.id: type};
      for (final entry in state.quantities.entries) {
        final oldType = state.types
            .where((type) => type.id == entry.key)
            .firstOrNull;
        final newType = current[entry.key];
        if (oldType == null ||
            newType == null ||
            newType.price != oldType.price ||
            newType.availableQuantity < entry.value) {
          _stop(
            'A disponibilidade ou o preço mudou. Revise sua seleção.',
            latest,
          );
          return null;
        }
      }
      if (latest.event.isAdultOnly && !policyAccepted) {
        final policy = await ref
            .read(checkoutRepositoryProvider)
            .requiredAgePolicy();
        if (policy != null) {
          state = CheckoutState(
            eventId: eventId,
            event: latest.event,
            types: latest.types,
            quantities: state.quantities,
            loading: false,
          );
          return policy;
        }
      }
      await _create(eventId, latest);
    } catch (_) {
      if (ref.mounted && state.eventId == eventId) {
        _stop('Não foi possível verificar os ingressos. Tente novamente.');
      }
    }
    return null;
  }

  Future<void> acceptAndSubmit() async {
    if (state.submitting) return;
    final eventId = state.eventId;
    if (eventId == null) return;
    state = CheckoutState(
      eventId: eventId,
      event: state.event,
      types: state.types,
      quantities: state.quantities,
      loading: false,
      submitting: true,
    );
    try {
      await ref.read(checkoutRepositoryProvider).acceptAgePolicy();
      if (!ref.mounted) return;
      state = CheckoutState(
        eventId: eventId,
        event: state.event,
        types: state.types,
        quantities: state.quantities,
        loading: false,
      );
      await submit(policyAccepted: true);
    } catch (_) {
      if (ref.mounted) {
        _stop('Não foi possível registrar o aceite. Tente novamente.');
      }
    }
  }

  Future<void> _create(String eventId, CheckoutCatalog latest) async {
    try {
      final order = await ref
          .read(checkoutRepositoryProvider)
          .create(eventId, state.quantities);
      if (!ref.mounted) return;
      final userId = ref.read(authSessionProvider).user?.id;
      if (userId != null) {
        try {
          await ref
              .read(pendingCheckoutStoreProvider)
              .save(userId, order.orderId);
        } catch (_) {}
      }
      state = CheckoutState(
        eventId: eventId,
        event: latest.event,
        types: latest.types,
        quantities: state.quantities,
        loading: false,
        order: order,
      );
    } on DioException catch (error) {
      if (!ref.mounted) return;
      final uncertain =
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          (error.response?.statusCode ?? 0) >= 500;
      state = CheckoutState(
        eventId: eventId,
        event: latest.event,
        types: latest.types,
        quantities: state.quantities,
        loading: false,
        uncertain: uncertain,
        error: uncertain
            ? 'Não foi possível confirmar se o pedido foi criado. Consulte Pedidos antes de tentar novamente.'
            : 'Não foi possível criar o pedido. Revise a disponibilidade.',
      );
    } catch (_) {
      if (ref.mounted) {
        state = CheckoutState(
          eventId: eventId,
          event: latest.event,
          types: latest.types,
          quantities: state.quantities,
          loading: false,
          uncertain: true,
          error: 'Não foi possível confirmar se o pedido foi criado. Consulte Pedidos antes de tentar novamente.',
        );
      }
    }
  }

  void _stop(String error, [CheckoutCatalog? latest]) {
    state = CheckoutState(
      eventId: state.eventId,
      event: latest?.event ?? state.event,
      types: latest?.types ?? state.types,
      quantities: state.quantities,
      loading: false,
      error: error,
    );
  }
}

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
