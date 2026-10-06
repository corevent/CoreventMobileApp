import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_dialog_styles.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../data/rating_dtos.dart';
import 'event_ratings_view_model.dart';
import 'rating_summary.dart';

class EventRatingSection extends ConsumerStatefulWidget {
  const EventRatingSection({super.key, required this.event});
  final RatedEvent event;
  @override
  ConsumerState<EventRatingSection> createState() => _EventRatingSectionState();
}

class _EventRatingSectionState extends ConsumerState<EventRatingSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(eventRatingsViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventRatingsViewModelProvider);
    final own = state.events[widget.event.eventId];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avaliações',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        EventAverageRating(
          value: widget.event.averageRating,
          count: widget.event.ratingCount,
          fontSize: 14,
          iconSize: 22,
        ),
        const SizedBox(height: 12),
        if (own != null) ...[
          Text(
            'Sua nota: ${own.userRating} de 5',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (own.ratingId == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Sua avaliação foi registrada.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          if (own.ratingId != null)
            CoreventTextAction(
              label: 'Editar avaliação',
              onPressed: state.busy.contains(own.eventId)
                  ? null
                  : () => showRatingEditor(context, own),
            ),
        ] else if (state.loaded)
          CoreventTextAction(
            label: 'Avaliar evento',
            onPressed: () => showRatingEditor(context, widget.event),
          )
        else if (state.loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          Text(
            state.error ?? 'Consulte sua avaliação para continuar.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          CoreventTextAction(
            label: 'Tentar novamente',
            onPressed: () =>
                ref.read(eventRatingsViewModelProvider.notifier).load(),
          ),
        ],
      ],
    );
  }
}

Future<void> showRatingEditor(BuildContext context, RatedEvent event) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      elevation: 0,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RatingEditor(event: event),
    );

class _RatingEditor extends ConsumerStatefulWidget {
  const _RatingEditor({required this.event});
  final RatedEvent event;
  @override
  ConsumerState<_RatingEditor> createState() => _RatingEditorState();
}

class _RatingEditorState extends ConsumerState<_RatingEditor> {
  late int selected;
  bool submitting = false;
  @override
  void initState() {
    super.initState();
    selected =
        ref
            .read(eventRatingsViewModelProvider)
            .events[widget.event.eventId]
            ?.userRating ??
        0;
  }

  Future<void> _save() async {
    setState(() => submitting = true);
    final error = await ref
        .read(eventRatingsViewModelProvider.notifier)
        .save(widget.event, selected);
    if (!mounted) return;
    setState(() => submitting = false);
    if (error == null) {
      Navigator.pop(context);
    } else {
      showErrorToast(context, error);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 0,
        backgroundColor: AppColors.surface,
        titleTextStyle: AppDialogStyles.title,
        title: const Text('Remover avaliação?'),
        content: const Text('Sua nota será removida deste evento.'),
        actions: [
          TextButton(
            style: AppDialogStyles.action,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: AppDialogStyles.destructiveAction,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => submitting = true);
    final error = await ref
        .read(eventRatingsViewModelProvider.notifier)
        .remove(widget.event.eventId);
    if (!mounted) return;
    setState(() => submitting = false);
    if (error == null) {
      Navigator.pop(context);
    } else {
      showErrorToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final own = ref
        .watch(eventRatingsViewModelProvider)
        .events[widget.event.eventId];
    final editable = own == null || own.ratingId != null;
    return PopScope(
      canPop: !submitting,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      own == null ? 'Avaliar evento' : 'Sua avaliação',
                      style: AppDialogStyles.title,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar avaliação',
                    onPressed: submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(RemixIcons.close_line),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.event.eventTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 4,
                children: [
                  for (var star = 1; star <= 5; star++)
                    Semantics(
                      selected: selected == star,
                      child: IconButton(
                        tooltip:
                            'Selecionar $star ${star == 1 ? 'estrela' : 'estrelas'}',
                        onPressed: submitting || !editable
                            ? null
                            : () => setState(() => selected = star),
                        iconSize: 34,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        icon: AnimatedSwitcher(
                          duration: AppMotion.duration(
                            context,
                            AppMotion.quick,
                          ),
                          child: Icon(
                            star <= selected
                                ? RemixIcons.star_fill
                                : RemixIcons.star_line,
                            key: ValueKey(star <= selected),
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  selected == 0
                      ? 'Selecione uma nota de 1 a 5.'
                      : 'Sua nota: $selected de 5',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              if (editable)
                CoreventButton(
                  label: 'Salvar avaliação',
                  busy: submitting,
                  onPressed: selected == 0 || selected == own?.userRating
                      ? null
                      : _save,
                ),
              if (own?.ratingId != null)
                TextButton(
                  style: AppDialogStyles.destructiveAction,
                  onPressed: submitting ? null : _remove,
                  child: const Text('Remover avaliação'),
                ),
              if (!editable)
                const Text(
                  'Sua avaliação foi registrada.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
