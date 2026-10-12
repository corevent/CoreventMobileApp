import 'package:corevent_mobile_app/features/auth/domain/auth_validation.dart';
import 'package:corevent_mobile_app/features/profile/data/profile_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/profile_forms_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ProfileRepository {}

void main() {
  test(
    'alteração de senha usa símbolos da API e permite correção do formulário',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final model = container.read(securityViewModelProvider.notifier);
      expect(
        await model.change('Atual!123', 'Forte_123', 'Forte_123'),
        isFalse,
      );
      expect(
        container.read(securityViewModelProvider).error,
        passwordRequirementsMessage,
      );
      verifyNever(() => repository.changePassword(any(), any()));
      when(() => repository.changePassword(any(), any()))
          .thenAnswer((_) async {});
      expect(
        await model.change('Atual!123', 'Forte_123!', 'Forte_123!'),
        isTrue,
      );
      verify(() => repository.changePassword('Atual!123', 'Forte_123!'))
          .called(1);
      expect(container.read(securityViewModelProvider).success, isTrue);
    },
  );
}
