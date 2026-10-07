import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class SessionLoadingPage extends ConsumerWidget {
  const SessionLoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.status == SessionStatus.networkError
          ? _SessionRecovery(onRetry: session.restore)
          : const _SessionSplash(),
    );
  }
}

class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Image.asset(
        'assets/images/logo_corevent_full.png',
        width: 220,
        semanticLabel: 'Corevent',
      ),
    ),
  );
}

class _SessionRecovery extends StatelessWidget {
  const _SessionRecovery({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_corevent_full.png',
                width: 200,
                semanticLabel: 'Corevent',
              ),
              const SizedBox(height: 40),
              const Text(
                'Não foi possível restaurar sua sessão.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
