import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import 'event_favorites_view_model.dart';

class EventFavoriteButton extends ConsumerStatefulWidget {
  const EventFavoriteButton({
    super.key,
    required this.eventId,
    this.withLabel = false,
  });
  final String eventId;
  final bool withLabel;
  @override
  ConsumerState<EventFavoriteButton> createState() =>
      _EventFavoriteButtonState();
}

class _EventFavoriteButtonState extends ConsumerState<EventFavoriteButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(eventFavoritesViewModelProvider.notifier).load();
    });
  }

  Future<void> _toggle() async {
    final error = await ref
        .read(eventFavoritesViewModelProvider.notifier)
        .toggle(widget.eventId);
    if (mounted && error != null) showErrorToast(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventFavoritesViewModelProvider);
    final saved = state.ids.containsKey(widget.eventId);
    final known = state.known(widget.eventId);
    final busy =
        state.busy.contains(widget.eventId) || (!known && state.loading);
    final label = !known
        ? 'Consultar favorito'
        : saved
        ? 'Favoritado'
        : 'Favoritar';
    final icon = AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.quick),
      child: busy
          ? const SizedBox(
              key: ValueKey('busy'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.pink,
              ),
            )
          : Icon(
              saved ? RemixIcons.heart_fill : RemixIcons.heart_line,
              key: ValueKey(saved),
              color: known ? AppColors.pink : AppColors.textSecondary,
            ),
    );
    if (widget.withLabel) {
      return TextButton.icon(
        onPressed: busy ? null : _toggle,
        style: TextButton.styleFrom(foregroundColor: AppColors.pink),
        icon: icon,
        label: Text(label),
      );
    }
    return IconButton(
      tooltip: label,
      onPressed: busy ? null : _toggle,
      icon: icon,
    );
  }
}
