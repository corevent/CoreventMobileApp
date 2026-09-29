import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/presentation/event_preview_sheet.dart';
import '../../events/presentation/event_widgets.dart';
import '../../profile/presentation/profile_form_pages.dart';
import '../data/rating_dtos.dart';
import 'event_ratings_view_model.dart';
import 'rating_widgets.dart';

class RatingsPage extends ConsumerStatefulWidget {
  const RatingsPage({super.key});
  @override
  ConsumerState<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends ConsumerState<RatingsPage> {
  final opening = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eventRatingsViewModelProvider.notifier).load(refresh: true);
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(eventRatingsViewModelProvider.notifier).load(refresh: true);
    if (!mounted) return;
    final error = ref.read(eventRatingsViewModelProvider).error;
    if (error != null) showErrorToast(context, error);
  }

  Future<void> _open(RatedEvent rating) async {
    if (opening.contains(rating.eventId)) return;
    setState(() => opening.add(rating.eventId));
    try {
      final repository = ref.read(eventsRepositoryProvider);
      final event = await repository.detail(rating.eventId);
      if (!mounted) return;
      unawaited(
        showEventPreview(
          context,
          repository,
          EventSummary(
            id: event.id,
            title: event.title,
            startDate: event.startDate,
            endDate: event.endDate,
            category: event.category,
            isAdultOnly: event.isAdultOnly,
            locationName: event.locationName,
            organizer: event.organizer,
            bannerUrl: event.bannerUrl,
            locationType: event.locationType,
            averageRating: event.averageRating,
            ratingCount: event.ratingCount,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showErrorToast(
          context,
          'Não foi possível abrir este evento. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => opening.remove(rating.eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventRatingsViewModelProvider);
    return ProfileSubpage(
      title: 'Avaliações',
      child: RefreshIndicator(
        color: AppColors.primary,
        elevation: 0,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (state.loading && state.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.events.isEmpty) ...[
              const SizedBox(height: 32),
              Text(
                state.error ?? 'Você ainda não avaliou eventos.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (state.error != null)
                TextButton(
                  onPressed: _refresh,
                  child: const Text('Tentar novamente'),
                ),
            ] else
              for (final rating in state.events.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    shape: AppSurfaces.cardShape,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: opening.contains(rating.eventId)
                          ? null
                          : () => _open(rating),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: EventArtwork(
                                    url: rating.bannerUrl,
                                    radius: 10,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rating.eventTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Sua nota: ${rating.userRating} de 5',
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (opening.contains(rating.eventId))
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    RemixIcons.arrow_right_s_line,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                            if (rating.ratingId != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: state.busy.contains(rating.eventId)
                                    ? null
                                    : () => showRatingEditor(context, rating),
                                icon: const Icon(
                                  RemixIcons.edit_line,
                                  size: 18,
                                ),
                                label: const Text('Editar avaliação'),
                              ),
                            ],
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
