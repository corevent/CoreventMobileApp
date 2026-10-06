import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/ticket_dtos.dart';

typedef TicketVisualStatus = ({String label, Color color, Color background});

TicketVisualStatus ticketVisualStatus(UserTicket ticket) =>
    switch ((ticket.status.toLowerCase(), ticket.order.status.toLowerCase())) {
      ('cancelled' || 'canceled' || 'refunded', _) ||
      (_, 'cancelled' || 'canceled' || 'refunded') => (
        label: 'Cancelado',
        color: AppColors.error,
        background: AppColors.backgroundSecondary,
      ),
      ('used' || 'checked_in', _) => (
        label: 'Utilizado',
        color: AppColors.textSecondary,
        background: AppColors.backgroundSecondary,
      ),
      (_, 'paid') => (
        label: 'Disponível',
        color: AppColors.success,
        background: AppColors.backgroundSecondary,
      ),
      (_, 'pending') => (
        label: 'Aguardando pagamento',
        color: AppColors.primaryDark,
        background: AppColors.orangeSoft,
      ),
      _ => (
        label: ticket.status,
        color: AppColors.textSecondary,
        background: AppColors.backgroundSecondary,
      ),
    };

bool canShowTicketQr(UserTicket ticket) =>
    ticket.status.toLowerCase() == 'pending' &&
    ticket.order.status.toLowerCase() == 'paid';

final _qrTokenPattern = RegExp(r'^[0-9a-fA-F]{64}$');

String? ticketQrPayload(UserTicket ticket) =>
    canShowTicketQr(ticket) && _qrTokenPattern.hasMatch(ticket.qrToken)
    ? ticket.qrToken
    : null;
