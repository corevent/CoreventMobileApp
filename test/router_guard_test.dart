import 'package:corevent_mobile_app/app/router.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_repository.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class ControlledSession extends AuthSession {
  ControlledSession(super.repository, super.tokens);

  void setStatus(SessionStatus value) {
    status = value;
    notifyListeners();
  }
}

void main() {
  late TokenStore tokens;
  late ControlledSession session;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    tokens = TokenStore(const FlutterSecureStorage());
    session = ControlledSession(MockAuthRepository(), tokens)
      ..status = SessionStatus.unauthenticated;
    container = ProviderContainer(
      overrides: [authSessionProvider.overrideWithValue(session)],
    );
    router = container.read(routerProvider);
  });

  tearDown(() {
    container.dispose();
    session.dispose();
    tokens.dispose();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rota privada manda sessão ausente para boas-vindas', (
    tester,
  ) async {
    await show(tester);
    router.go('/profile/orders');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Já tenho uma conta'), findsOneWidget);
  });

  testWidgets('rota privada aguarda sessão e preserva o destino', (
    tester,
  ) async {
    session.setStatus(SessionStatus.loading);
    await show(tester);
    router.go('/tickets');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/loading');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['next'],
      '/tickets',
    );
    session.setStatus(SessionStatus.unauthenticated);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('verificação sem dados volta ao formulário correto', (
    tester,
  ) async {
    await show(tester);
    router.go('/verify/register');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/register');
    router.go('/verify/reset');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/forgot-password');
    router.go('/reset-password');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/forgot-password');
  });
}
