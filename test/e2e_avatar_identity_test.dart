import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e/support/avatar_identity.dart';

void main() {
  const object =
      'https://storage.googleapis.com/corevent-staging-bucket/avatars/user/photo.jpg';

  test('avatar stays the same when its signed access parameters change', () {
    const first =
        '$object?X-Goog-Date=20261010T100000Z&X-Goog-Signature=first&X-Goog-Expires=900';
    const refreshed =
        '$object?X-Goog-Date=20261010T110000Z&X-Goog-Signature=second&X-Goog-Expires=1800';
    expect(avatarObjectIdentity(first), isNotNull);
    expect(avatarObjectIdentity(first), avatarObjectIdentity(refreshed));
    expect(avatarObjectIdentity(first), avatarObjectIdentity(object));
  });

  test('a newly uploaded object differs even with the same signing parameters', () {
    expect(
      avatarObjectIdentity('$object?X-Goog-Signature=same'),
      isNot(
        avatarObjectIdentity(
          '${object.replaceFirst('photo.jpg', 'new-photo.jpg')}?X-Goog-Signature=same',
        ),
      ),
    );
  });

  test('bucket, host, protocol and port remain part of the identity', () {
    final identity = avatarObjectIdentity(object);
    for (final other in [
      object.replaceFirst('corevent-staging-bucket', 'another-bucket'),
      object.replaceFirst('storage.googleapis.com', 'another.example.com'),
      object.replaceFirst('https:', 'http:'),
      object.replaceFirst(
        'storage.googleapis.com',
        'storage.googleapis.com:8443',
      ),
    ]) {
      expect(avatarObjectIdentity(other), isNot(identity), reason: other);
    }
  });

  test('missing or invalid URLs cannot pass as an uploaded avatar', () {
    for (final url in [
      null,
      '',
      '   ',
      'not-a-url',
      '/avatars/photo.jpg',
      'file:///avatars/photo.jpg',
      'https://',
      'https://storage.googleapis.com',
      'https://storage.googleapis.com/',
    ]) {
      expect(avatarObjectIdentity(url), isNull, reason: '$url');
    }
  });
}
