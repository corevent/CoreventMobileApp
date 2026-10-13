import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_coverage.dart';

void main() {
  test('normalizes relative and absolute Windows/Linux paths', () {
    for (final path in [
      r'lib\features\auth\login.dart',
      r'C:\project\lib\features\auth\login.dart',
      '/home/runner/project/lib/features/auth/login.dart',
      './lib/features/auth/login.dart',
    ]) {
      expect(normalizeSource(path), 'lib/features/auth/login.dart');
    }
  });

  test('deduplicates lines across records with different path separators', () {
    final sources = parseLcov(
      'SF:lib/a.dart\nDA:1,0\nDA:2,1\nLF:999\nLH:999\nend_of_record\n'
      'SF:lib\\a.dart\nDA:1,2,checksum\nDA:2,0\nend_of_record\n',
    );
    final result = evaluateCoverage(sources, [
      CoverageRule('All', '^lib/', 100),
    ], []).single;
    expect(result.total, 2);
    expect(result.covered, 2);
    expect(result.passed, isTrue);
  });

  test('excludes generated sources and matches overlapping groups', () {
    final sources = {
      'lib/features/auth/data/repository.dart': {1: 1, 2: 0},
      'lib/features/auth/data/model.g.dart': {1: 0},
      'lib/features/auth/data/model.freezed.dart': {1: 0},
      'lib/core/config.dart': {1: 1},
    };
    final results = evaluateCoverage(
      sources,
      [
        CoverageRule('All', '^lib/', 50),
        CoverageRule('Auth', '^lib/features/auth/', 50),
        CoverageRule('Data', '^lib/features/[^/]+/data/', 50),
      ],
      ['.g.dart', '.freezed.dart'],
    );
    expect(results.map((result) => result.total), [3, 2, 2]);
    expect(results.every((result) => result.passed), isTrue);
  });

  test('compares unrounded coverage and rejects absent groups', () {
    final rule = CoverageRule('All', '^lib/', 82.5);
    expect(CoverageResult(rule, 33, 40).passed, isTrue);
    expect(
      CoverageResult(rule, 82499, 100000).percentage!.toStringAsFixed(2),
      '82.50',
    );
    expect(CoverageResult(rule, 82499, 100000).passed, isFalse);
    expect(CoverageResult(rule, 0, 0).passed, isFalse);
    expect(CoverageResult(rule, 0, 0).percentage, isNull);
  });

  test('rejects empty, malformed and incomplete LCOV', () {
    for (final input in [
      '',
      'SF:lib/a.dart\nend_of_record',
      'DA:1,1',
      'SF:lib/a.dart\nDA:0,1\nend_of_record',
      'SF:lib/a.dart\nDA:1,-1\nend_of_record',
      'SF:lib/a.dart\nDA:1,abc\nend_of_record',
      'SF:lib/a.dart\nDA:1\nend_of_record',
      'SF:lib/a.dart\nDA:1,1',
      'SF:lib/a.dart\nSF:lib/b.dart\nDA:1,1\nend_of_record',
      'SF:test/a.dart\nDA:1,1\nend_of_record',
    ]) {
      expect(() => parseLcov(input), throwsFormatException, reason: input);
    }
  });
}
