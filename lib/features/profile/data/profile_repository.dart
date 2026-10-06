import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/data/auth_providers.dart';

class ProfileRepository {
  const ProfileRepository(this.api);
  final ProfileApi api;

  Future<UserProfile> updateDetails(String name, String phone) async =>
      (await api.update({
        'name': name,
        'phoneNumber': phone.isEmpty ? null : phone,
      })).data;

  Future<UserProfile> updateFields(Map<String, dynamic> changes) async =>
      (await api.update(changes)).data;

  Future<void> changePassword(String current, String next) async {
    await api.changePassword({'currentPassword': current, 'newPassword': next});
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileApiProvider)),
);
