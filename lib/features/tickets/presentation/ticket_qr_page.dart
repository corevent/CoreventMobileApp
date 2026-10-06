import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ticket_dtos.dart';
import '../data/tickets_repository.dart';
import 'ticket_status.dart';

Future<void> showTicketQr(
  BuildContext context,
  UserTicket ticket,
  TicketsRepository repository,
) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    builder: (_) => TicketQrPage(ticket: ticket, repository: repository),
  ),
);

class TicketQrPage extends StatefulWidget {
  const TicketQrPage({
    super.key,
    required this.ticket,
    required this.repository,
  });

  final UserTicket ticket;
  final TicketsRepository repository;

  @override
  State<TicketQrPage> createState() => _TicketQrPageState();
}

class _TicketQrPageState extends State<TicketQrPage>
    with WidgetsBindingObserver {
  late UserTicket currentTicket;
  bool refreshing = false;
  bool refreshFailed = false;
  bool ticketMissing = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    currentTicket = widget.ticket;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final request = ++generation;
    setState(() {
      refreshing = true;
      refreshFailed = false;
    });
    try {
      final updated = await widget.repository.refreshTicket(currentTicket);
      if (!mounted || request != generation) return;
      setState(() {
        refreshing = false;
        ticketMissing = updated == null;
        if (updated != null) currentTicket = updated;
      });
    } catch (_) {
      if (!mounted || request != generation) return;
      setState(() {
        refreshing = false;
        refreshFailed = true;
      });
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = !ticketMissing && canShowTicketQr(currentTicket);
    final payload = ticketQrPayload(currentTicket);
    final status = ticketVisualStatus(currentTicket);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final qrSize = (screenWidth - 104).clamp(140.0, 320.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: AppSurfaces.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar aos ingressos',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(RemixIcons.arrow_left_line),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Seu ingresso',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          currentTicket.event.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentTicket.ticketType.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            ticketMissing ? 'Indisponível' : status.label,
                            style: TextStyle(
                              color: allowed
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (allowed && payload != null)
                          Center(
                            child: Semantics(
                              image: true,
                              label:
                                  'QR Code do ingresso de ${currentTicket.event.title}',
                              child: ExcludeSemantics(
                                child: DecoratedBox(
                                  decoration: AppSurfaces.cardDecoration,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: qrSize,
                                      backgroundColor: AppColors.surface,
                                      padding: const EdgeInsets.all(12),
                                      errorStateBuilder: (_, _) => const Text(
                                        'Não foi possível gerar o QR Code.',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          _QrUnavailable(
                            message: allowed
                                ? 'Código indisponível. Atualize para tentar novamente.'
                                : 'Este ingresso não pode ser apresentado na entrada.',
                          ),
                        const SizedBox(height: 20),
                        if (allowed && payload != null)
                          const Text(
                            'Apresente este código na entrada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (refreshing) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        if (refreshFailed) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Não foi possível confirmar o status agora.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: refreshing ? null : _refresh,
                            child: const Text('Atualizar status'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 220),
    decoration: AppSurfaces.cardDecoration,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          RemixIcons.qr_code_line,
          size: 54,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
