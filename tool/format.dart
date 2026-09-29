import 'dart:io';

/// Formats project sources without modifying files maintained by generators.
void main(List<String> arguments) {
  if (arguments.isNotEmpty &&
      (arguments.length != 1 || arguments.single != '--check')) {
    stderr.writeln('Usage: dart tool/format.dart [--check]');
    exitCode = 64;
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final sources = <String>[];
  for (final folder in ['lib', 'test', 'tool']) {
    final directory = Directory('${root.path}/$folder');
    if (!directory.existsSync()) continue;
    for (final entry in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is File &&
          entry.path.endsWith('.dart') &&
          !entry.path.endsWith('.g.dart') &&
          !entry.path.endsWith('.freezed.dart')) {
        sources.add(entry.path);
      }
    }
  }
  sources.sort();
  final result = Process.runSync(Platform.resolvedExecutable, [
    'format',
    if (arguments.contains('--check')) ...[
      '--output=none',
      '--set-exit-if-changed',
    ],
    ...sources,
  ], workingDirectory: root.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exitCode = result.exitCode;
}
