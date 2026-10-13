import 'dart:convert';
import 'dart:io';

/// Converts relative or absolute Windows/Linux LCOV paths to project paths.
String normalizeSource(String source) {
  final path = source.trim().replaceAll('\\', '/');
  if (path.startsWith('lib/')) return path;
  final index = path.lastIndexOf('/lib/');
  if (index >= 0) return path.substring(index + 1);
  throw FormatException('Source is outside lib/: $source');
}

/// Merges duplicate records by source and line; LF/LH are not authoritative.
Map<String, Map<int, int>> parseLcov(String input) {
  final sources = <String, Map<int, int>>{};
  String? source;
  for (final raw in const LineSplitter().convert(input)) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      if (source != null) {
        throw const FormatException('Missing end_of_record');
      }
      source = normalizeSource(line.substring(3));
      sources.putIfAbsent(source, () => <int, int>{});
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final number = int.tryParse(parts.first);
      final hits = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      if (source == null ||
          parts.length < 2 ||
          parts.length > 3 ||
          number == null ||
          number <= 0 ||
          hits == null ||
          hits < 0) {
        throw FormatException('Invalid coverage line: $line');
      }
      final lines = sources[source]!;
      lines[number] = (lines[number] ?? 0) + hits;
    } else if (line == 'end_of_record') {
      if (source == null) throw const FormatException('Unexpected record end');
      source = null;
    }
  }
  if (source != null) throw const FormatException('Unterminated LCOV record');
  if (sources.isEmpty || sources.values.every((lines) => lines.isEmpty)) {
    throw const FormatException('LCOV has no measured lines');
  }
  return sources;
}

class CoverageRule {
  CoverageRule(this.name, String pattern, this.minimum)
    : pattern = RegExp(pattern) {
    if (name.trim().isEmpty ||
        !minimum.isFinite ||
        minimum < 0 ||
        minimum > 100) {
      throw const FormatException('Invalid coverage rule');
    }
  }

  final String name;
  final RegExp pattern;
  final double minimum;
}

class CoverageResult {
  CoverageResult(this.rule, this.covered, this.total);

  final CoverageRule rule;
  final int covered;
  final int total;
  double? get percentage => total == 0 ? null : covered * 100 / total;
  // Compare counts before rounding to avoid passing just below the threshold.
  bool get passed => total > 0 && covered * 100 >= rule.minimum * total;

  Map<String, Object?> toJson() => {
    'name': rule.name,
    'covered': covered,
    'total': total,
    'percentage': percentage,
    'minimum': rule.minimum,
    'passed': passed,
  };
}

List<CoverageResult> evaluateCoverage(
  Map<String, Map<int, int>> sources,
  List<CoverageRule> rules,
  List<String> excludedSuffixes,
) => rules.map((rule) {
  var covered = 0;
  var total = 0;
  for (final entry in sources.entries) {
    if (excludedSuffixes.any(entry.key.endsWith) ||
        !rule.pattern.hasMatch(entry.key)) {
      continue;
    }
    total += entry.value.length;
    covered += entry.value.values.where((hits) => hits > 0).length;
  }
  return CoverageResult(rule, covered, total);
}).toList();

void main(List<String> arguments) {
  if (arguments.length > 1) {
    stderr.writeln('Usage: dart tool/check_coverage.dart [coverage/lcov.info]');
    exitCode = 64;
    return;
  }
  final reports = Directory('reports')..createSync(recursive: true);
  try {
    final inputPath = arguments.isEmpty
        ? 'coverage/lcov.info'
        : arguments.single;
    final config = jsonDecode(
      File('tool/coverage_rules.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final groups = config['groups'] as List<dynamic>;
    final rules = groups.map((value) {
      final group = value as Map<String, dynamic>;
      return CoverageRule(
        group['name'] as String,
        group['pattern'] as String,
        (group['minimum'] as num).toDouble(),
      );
    }).toList();
    if (rules.isEmpty ||
        rules.map((rule) => rule.name).toSet().length != rules.length) {
      throw const FormatException('Rules must be nonempty and uniquely named');
    }
    final excluded = (config['excludeSuffixes'] as List<dynamic>)
        .cast<String>();
    final sources = parseLcov(File(inputPath).readAsStringSync());
    final results = evaluateCoverage(sources, rules, excluded);
    final passed = results.every((result) => result.passed);
    final summary = StringBuffer()
      ..writeln('# Line coverage')
      ..writeln()
      ..writeln('Result: ${passed ? 'PASS' : 'FAIL'}')
      ..writeln()
      ..writeln('| Area | Covered / measured | Coverage | Minimum | Result |')
      ..writeln('| --- | ---: | ---: | ---: | --- |');
    for (final result in results) {
      final percentage = result.percentage?.toStringAsFixed(2) ?? 'N/A';
      summary.writeln(
        '| ${result.rule.name} | ${result.covered}/${result.total} | '
        '$percentage% | ${result.rule.minimum}% | ${result.passed ? 'PASS' : 'FAIL'} |',
      );
    }
    summary
      ..writeln()
      ..writeln(
        'Generated files are excluded. Only lines present in LCOV are measured.',
      )
      ..writeln('Feature and layer groups overlap; do not sum their totals.')
      ..writeln('Branch/function coverage is not evaluated by this gate.');
    File('${reports.path}/coverage-summary.md').writeAsStringSync('$summary');
    File('${reports.path}/coverage-summary.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'input': inputPath,
        'passed': passed,
        'excludedSuffixes': excluded,
        'groups': results.map((result) => result.toJson()).toList(),
      }),
    );
    stdout.write(summary);
    exitCode = passed ? 0 : 1;
  } on Object catch (error) {
    final message = 'Coverage check failed: $error';
    stderr.writeln(message);
    File('${reports.path}/coverage-summary.md')
        .writeAsStringSync('# Line coverage\n\nFAIL: $message\n');
    File('${reports.path}/coverage-summary.json').writeAsStringSync(
      jsonEncode({'schemaVersion': 1, 'passed': false, 'error': '$error'}),
    );
    exitCode = 1;
  }
}
