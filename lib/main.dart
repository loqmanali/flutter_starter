import 'dart:io';

/// Unflavored entrypoint — always refuses to run.
///
/// Every launch must go through a flavored entrypoint with
/// `--dart-define-from-file` applied (directly, or via `flow deploy run`
/// for a named profile — see the README). Exit 64 is the conventional
/// "command line usage error".
void main() {
  stderr.writeln(
    'flutter_starter: no flavor selected.\n'
    'Run one of:\n'
    '  flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev\n'
    '  flutter run -t lib/main_production.dart --dart-define-from-file=.env.production',
  );
  exit(64);
}
