import 'dart:async';

import 'package:corevent_mobile_app/features/tickets/data/ticket_dtos.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/ticket_qr_page.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/ticket_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockTicketsRepository extends Mock implements TicketsRepository {}

final token = List.filled(64, 'a').join();

UserTicket makeTicket({String status = 'pending', String? qrToken}) =>
    UserTicket(
      id: 'ticket-1',
      status: status,
      qrToken: qrToken ?? token,
      ticketType: const UserTicketType(
        id: 'type-1',
        name: 'Inteira',
        price: 50,
      ),
      event: const UserTicketEvent(id: 'event-1', title: 'Festival'),
      order: const UserTicketOrder(id: 'order-1', status: 'paid'),
    );

void main() {
  testWidgets('codifica o token e oculta o QR após check-in', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = MockTicketsRepository();
    final original = makeTicket();
    expect(ticketQrPayload(original), token);
    final updated = Completer<UserTicket?>();
    when(() => repository.refreshTicket(original))
        .thenAnswer((_) => updated.future);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: TicketQrPage(ticket: original, repository: repository),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);

    updated.complete(makeTicket(status: 'checked_in'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Utilizado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha de rede mantém o QR carregado', (tester) async {
    final repository = MockTicketsRepository();
    final original = makeTicket();
    when(() => repository.refreshTicket(original))
        .thenAnswer((_) async => throw Exception('offline'));
    await tester.pumpWidget(
      MaterialApp(
        home: TicketQrPage(ticket: original, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text('Não foi possível confirmar o status agora.'),
      findsOneWidget,
    );
  });

  testWidgets('token ausente apresenta erro sem gerar QR', (tester) async {
    final repository = MockTicketsRepository();
    final original = makeTicket(qrToken: '');
    when(() => repository.refreshTicket(original))
        .thenAnswer((_) async => original);
    await tester.pumpWidget(
      MaterialApp(
        home: TicketQrPage(ticket: original, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(
      find.text('Código indisponível. Atualize para tentar novamente.'),
      findsOneWidget,
    );
  });
}
