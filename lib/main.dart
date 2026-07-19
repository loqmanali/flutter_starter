import 'dart:io';

/// Unflavored entrypoint — always refuses to run.
///
/// Every launch must go through `flow flavor run <flavor>` so that
/// `--dart-define-from-file` is applied. Exit 64 is the conventional
/// "command line usage error".
void main() {
  stderr.writeln(
    'flutter_starter: no flavor selected.\n'
    'Run one of:\n'
    '  flow flavor run dev\n'
    '  flow flavor run production',
  );
  exit(64);
}
