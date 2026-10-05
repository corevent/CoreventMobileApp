import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'persistent_scenarios.dart';
import 'read_only_scenarios.dart';
import 'reversible_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Each group owns its setup and cleanup; only this file is a test target.
  group('Persistentes', registerPersistentTests);
  group('Somente leitura', registerReadOnlyTests);
  group('Reversíveis', registerReversibleTests);
}
