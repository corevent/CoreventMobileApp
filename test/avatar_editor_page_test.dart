import 'dart:async';
import 'dart:typed_data';

import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/data/avatar_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/avatar_editor_page.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:remixicon/remixicon.dart';

class MockRepository extends Mock implements AvatarRepository {}

class MockSession extends Mock implements AuthSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(1));
    registerFallbackValue((double progress) {});
  });
  testWidgets(
    'foto requer prévia e envio explícito, bloqueia voltar e permite tentar novamente',
    (tester) async {
      final repository = MockRepository();
      final session = MockSession();
      final upload = Completer<String>();
      final prepared = Completer<Uint8List>();
      when(() => repository.upload(any(), any()))
          .thenAnswer((_) => upload.future);
      when(() => repository.confirm('key')).thenThrow(Exception('offline'));
      final bytes = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 40, height: 40)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarRepositoryProvider.overrideWithValue(repository),
            authSessionProvider.overrideWithValue(session),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: AvatarEditorPage(
              image: bytes,
              prepareImage: (_) => prepared.future,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Ajustar foto'), findsOneWidget);
      verifyNever(() => repository.upload(any(), any()));
      final crop = tester.widget<Crop>(find.byType(Crop));
      crop.onCropped(CropSuccess(bytes));
      await tester.pump();
      expect(find.text('Prévia da foto'), findsNothing);
      prepared.complete(bytes);
      await tester.pump();
      await tester.pump();
      expect(find.text('Prévia da foto'), findsOneWidget);
      verifyNever(() => repository.upload(any(), any()));
      await tester.tap(find.text('Salvar foto'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, RemixIcons.arrow_left_line),
            )
            .onPressed,
        isNull,
      );
      upload.complete('key');
      await tester.pump();
      await tester.pump();
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(
        find.text(
          'A foto foi enviada, mas a confirmação falhou. Tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ajustar recorte'), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();
      verify(() => repository.upload(any(), any())).called(1);
      verify(() => repository.confirm('key')).called(2);
    },
  );
}
