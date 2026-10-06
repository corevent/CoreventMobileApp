import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../core/design_system/app_surfaces.dart';
import '../core/theme/app_colors.dart';

class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: shell.currentIndex == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && shell.currentIndex != 0) shell.goBranch(0);
    },
    child: Scaffold(
      backgroundColor: AppColors.surface,
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: AppSurfaces.outline),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: AppColors.surface,
              indicatorColor: Colors.transparent,
              elevation: 0,
              height: 66,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) => shell.goBranch(index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(RemixIcons.home_line),
                  selectedIcon: Icon(RemixIcons.home_fill),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(RemixIcons.compass_3_line),
                  selectedIcon: Icon(RemixIcons.compass_3_fill),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(RemixIcons.ticket_line),
                  selectedIcon: Icon(RemixIcons.ticket_fill),
                  label: 'Ingressos',
                ),
                NavigationDestination(
                  icon: Icon(RemixIcons.user_line),
                  selectedIcon: Icon(RemixIcons.user_fill),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
