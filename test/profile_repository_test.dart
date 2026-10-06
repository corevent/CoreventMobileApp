import 'package:corevent_mobile_app/features/auth/data/auth_api.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/profile/data/activity_api.dart';
import 'package:corevent_mobile_app/features/profile/data/activity_dtos.dart';
import 'package:corevent_mobile_app/features/profile/data/activity_repository.dart';
import 'package:corevent_mobile_app/features/profile/data/profile_repository.dart';
import 'package:corevent_mobile_app/features/profile/domain/membership.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileApi extends Mock implements ProfileApi {}

class MockActivityApi extends Mock implements ActivityApi {}

void main() {
  test('tempo de associação usa dias do calendário local', () {
    final today = DateTime(2026, 9, 27, 18);
    expect(
      membershipLabel(DateTime(2026, 9, 27, 1), today),
      'Membro desde hoje',
    );
    expect(
      membershipLabel(DateTime(2026, 9, 26, 23), today),
      'Membro há 1 dia',
    );
    expect(membershipLabel(DateTime(2026, 9, 17), today), 'Membro há 10 dias');
    expect(membershipLabel(null, today), 'Membro Corevent');
    expect(membershipLabel(DateTime(2026, 10, 1), today), 'Membro Corevent');
  });

  test('perfil interpreta createdAt e os dados exibidos', () {
    final user = UserProfile.fromJson({
      'id': 'u1',
      'name': 'Ana Silva',
      'email': 'ana@exemplo.com',
      'createdAt': '2026-09-20T12:00:00.000Z',
      'phoneNumber': '+5511999999999',
      'documentType': 'cpf',
      'document': '12345678900',
    });
    expect(user.createdAt, DateTime.utc(2026, 9, 20, 12));
    expect(user.phoneNumber, '+5511999999999');
    final invalidDate = UserProfile.fromJson({
      'id': 'u2',
      'name': 'João',
      'email': 'joao@exemplo.com',
      'createdAt': 'data inválida',
    });
    expect(invalidDate.createdAt, isNull);
  });

  test('edição envia apenas os campos aceitos pela API', () async {
    final api = MockProfileApi();
    const user = UserProfile(id: 'u1', name: 'Ana', email: 'ana@exemplo.com');
    when(() => api.update(any()))
        .thenAnswer((_) async => const ProfileResponse(user));
    final result = await ProfileRepository(api)
        .updateDetails('Ana', '+5511999999999');
    expect(result, same(user));
    verify(() => api.update({'name': 'Ana', 'phoneNumber': '+5511999999999'}))
        .called(1);
  });

  test('pedidos e avaliações leem as páginas da conta', () async {
    final api = MockActivityApi();
    final orders = OrderPage.fromJson({
      'data': [
        {
          'id': 'o1',
          'event': {
            'id': 'e1',
            'title': 'Festival',
            'startDate': '2026-10-01T10:00:00Z',
          },
          'totalAmount': 85,
          'status': 'paid',
          'createdAt': '2026-09-20T10:00:00Z',
        },
      ],
      'meta': {'currentPage': 1, 'totalPages': 1},
    });
    when(() => api.orders(1, 20)).thenAnswer((_) async => orders);
    expect(
      (await ActivityRepository(api).orders(1)).data.single.event.title,
      'Festival',
    );
    verify(() => api.orders(1, 20)).called(1);

    final ratings = RatingsPage.fromJson({
      'data': [
        {
          'eventId': 'e1',
          'eventTitle': 'Festival',
          'userRating': 5,
          'averageRating': 4.5,
        },
      ],
      'meta': {'currentPage': 1, 'totalPages': 1},
    });
    when(() => api.ratings(1, 20)).thenAnswer((_) async => ratings);
    expect(
      (await ActivityRepository(api).ratings(1)).data.single.userRating,
      5,
    );
  });
}
