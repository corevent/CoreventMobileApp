import 'dart:async';

import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/data/profile_repository.dart';
import 'package:corevent_mobile_app/features/profile/domain/profile_formatters.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_forms_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements ProfileRepository {}

class MockSession extends Mock implements AuthSession {}

void main() {
  const user = UserProfile(
    id: 'u1',
    name: 'Ana Silva',
    email: 'ana@example.com',
    phoneNumber: '+5511999999999',
  );
  late MockRepository repository;
  late MockSession session;
  late ProviderContainer container;
  setUp(() {
    repository = MockRepository();
    session = MockSession();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWithValue(session),
      ],
    );
    container.read(detailsViewModelProvider.notifier).edit(user);
  });
  tearDown(() => container.dispose());
  setUpAll(() => registerFallbackValue(user));

  test('formatos do telefone não criam alteração falsa', () {
    final model = container.read(detailsViewModelProvider.notifier);
    expect(container.read(detailsViewModelProvider).dirty, false);
    model.changePhone('(11) 99999-9999');
    expect(container.read(detailsViewModelProvider).dirty, false);
    expect(formatDocument('52998224725'), '529.982.247-25');
    expect(normalizePhone('(11) 3333-4444'), '+551133334444');
    final value = BrazilianPhoneFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '11912345678',
        selection: TextSelection.collapsed(offset: 11),
      ),
    );
    expect(value.text, '(11) 91234-5678');
    expect(value.selection.extentOffset, value.text.length);
  });

  test('envia somente nome alterado e atualiza sessão', () async {
    final model = container.read(detailsViewModelProvider.notifier);
    model.changeName('Ana Souza');
    const updated = UserProfile(
      id: 'u1',
      name: 'Ana Souza',
      email: 'ana@example.com',
      phoneNumber: '+5511999999999',
    );
    when(() => repository.updateFields({'name': 'Ana Souza'}))
        .thenAnswer((_) async => updated);
    expect(await model.save(), true);
    verify(() => repository.updateFields({'name': 'Ana Souza'})).called(1);
    verify(() => session.updateUser(updated)).called(1);
  });

  test('telefone pode ser removido e erro mantém o rascunho', () async {
    final model = container.read(detailsViewModelProvider.notifier);
    model.changePhone('');
    when(() => repository.updateFields({'phoneNumber': null}))
        .thenThrow(Exception('offline'));
    expect(await model.save(), false);
    final state = container.read(detailsViewModelProvider);
    expect(state.editing, true);
    expect(state.phone, '');
    expect(state.error, isNotNull);
    expect(state.dirty, true);
  });

  test('bloqueia envio inválido e chamadas simultâneas', () async {
    final model = container.read(detailsViewModelProvider.notifier);
    model.changePhone('11');
    expect(await model.save(), false);
    expect(container.read(detailsViewModelProvider).phoneError, isNotNull);
    model.changePhone('(11) 99999-9999');
    model.changeName('Ana Souza');
    final response = Completer<UserProfile>();
    when(() => repository.updateFields(any()))
        .thenAnswer((_) => response.future);
    final save = model.save();
    expect(container.read(detailsViewModelProvider).busy, true);
    expect(await model.save(), false);
    response.complete(user);
    await save;
    verify(() => repository.updateFields(any())).called(1);
  });
}
