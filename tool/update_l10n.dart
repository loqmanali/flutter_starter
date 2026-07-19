// ignore_for_file: avoid_print
import 'dart:io';

/// Runs the full l10n pipeline. Editing an `.arb` file requires BOTH steps —
/// running only `flutter gen-l10n` leaves the forwarders stale.
Future<void> main() async {
  final gen = await Process.run('flutter', ['gen-l10n'], runInShell: true);
  stdout.write(gen.stdout);
  stderr.write(gen.stderr);
  if (gen.exitCode != 0) exit(gen.exitCode);

  final forwarders = await Process.run('dart', [
    'run',
    'tool/generate_l10n_forwarders.dart',
  ], runInShell: true);
  stdout.write(forwarders.stdout);
  stderr.write(forwarders.stderr);
  exit(forwarders.exitCode);
}
