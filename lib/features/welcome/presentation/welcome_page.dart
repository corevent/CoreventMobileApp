import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/theme/app_colors.dart';
import 'welcome_view_model.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(welcomeViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 40 : 24,
                      vertical: wide ? 48 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: wide
                          ? _WideWelcome(viewModel: viewModel)
                          : _NarrowWelcome(viewModel: viewModel),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NarrowWelcome extends StatelessWidget {
  const _NarrowWelcome({required this.viewModel});

  final WelcomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: _Logo(width: 180)),
        const SizedBox(height: 54),
        const _EventArtwork(height: 250),
        const SizedBox(height: 46),
        const _WelcomeCopy(centered: true),
        const SizedBox(height: 46),
        _WelcomeActions(viewModel: viewModel),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _WideWelcome extends StatelessWidget {
  const _WideWelcome({required this.viewModel});

  final WelcomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.backgroundSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Logo(width: 210),
                  const SizedBox(height: 108),
                  const _WelcomeCopy(centered: false),
                  const SizedBox(height: 48),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _WelcomeActions(viewModel: viewModel),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: ColoredBox(
              color: AppColors.orangeSoft,
              child: Center(child: _EventArtwork(height: 340)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo_corevent_full.png',
    width: width,
    fit: BoxFit.contain,
    semanticLabel: 'Corevent',
  );
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final heading = centered
        ? Theme.of(context).textTheme.headlineMedium!
        : Theme.of(context).textTheme.headlineLarge!;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'Descubra '),
              TextSpan(
                text: 'eventos incríveis',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: ' perto de você.'),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: heading,
        ),
        const SizedBox(height: 18),
        Text(
          'Encontre experiências para viver e garanta seu ingresso de forma rápida e segura.',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.viewModel});

  final WelcomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: viewModel.openRegister,
          child: const Text('Criar conta'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: viewModel.openLogin,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: Colors.transparent,
            overlayColor: Colors.transparent,
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Já tenho uma conta'),
        ),
      ],
    );
  }
}

class _EventArtwork extends StatelessWidget {
  const _EventArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * .82,
            height: height * .82,
            decoration: const BoxDecoration(
              color: AppColors.pinkSoft,
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.12,
            child: Container(
              width: height * .62,
              height: height * .66,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.backgroundSecondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          RemixIcons.ticket_fill,
                          color: AppColors.primary,
                          size: 72,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: height * .36,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    width: height * .24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: height * .2,
            child: const _ArtworkBadge(icon: RemixIcons.heart_fill),
          ),
          Positioned(
            left: 1,
            bottom: height * .2,
            child: const _ArtworkBadge(icon: RemixIcons.ticket_fill),
          ),
        ],
      ),
    );
  }
}

class _ArtworkBadge extends StatelessWidget {
  const _ArtworkBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: const BoxDecoration(
      color: AppColors.surface,
      shape: BoxShape.circle,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.backgroundSecondary),
      ),
    ),
    child: Icon(icon, color: AppColors.pink),
  );
}
