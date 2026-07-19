// ignore_for_file: avoid_print
import 'dart:io';

/// Rewrites `from` to `to` where it appears as a whole package identifier.
///
/// Word boundaries matter: `flutter_starter_legacy` must survive untouched,
/// so the match requires a non-word character (or string end) on both sides.
String rewritePackageReferences(
  String source, {
  required String from,
  required String to,
}) {
  final pattern = RegExp('(?<!\\w)${RegExp.escape(from)}(?!\\w)');
  return source.replaceAll(pattern, to);
}

const _oldName = 'flutter_starter';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tool/rename.dart --name <package_name> '
      '--org <com.example> [--display "App Name"]',
    );
    exit(64);
  }

  final (:name, :org, :display) = options;

  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    stderr.writeln('--name must be lower_snake_case, got "$name".');
    exit(65);
  }

  var touched = 0;
  for (final entity in Directory.current.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!_isRewritable(entity.path)) continue;

    final original = entity.readAsStringSync();
    final updated = rewritePackageReferences(
      original,
      from: _oldName,
      to: name,
    );
    if (updated != original) {
      entity.writeAsStringSync(updated);
      touched++;
    }
  }
  print('Rewrote package references in $touched files.');

  // change_app_package_name is a dev_dependency (see pubspec.yaml) purely for
  // this one-time step: it correctly rewrites AndroidManifest.xml (main,
  // debug, profile), build.gradle(.kts), moves the MainActivity Kotlin/Java
  // file to its new package directory, and rewrites every
  // PRODUCT_BUNDLE_IDENTIFIER in the iOS pbxproj. Reimplementing that by hand
  // here would be a much larger, more fragile surface than depending on the
  // single-purpose package that already does it.
  final rename = await Process.run('dart', [
    'run',
    'change_app_package_name:main',
    '$org.$name',
  ], runInShell: true);
  stdout.write(rename.stdout);
  stderr.write(rename.stderr);
  if (rename.exitCode != 0) {
    print(
      'Bundle id rename failed (dart run change_app_package_name:main '
      '$org.$name exited ${rename.exitCode}). Run `flutter pub get` first '
      'if this is a fresh clone, or set "$org.$name" by hand: '
      'android/app/build.gradle.kts (applicationId), '
      'android/app/src/{main,debug,profile}/AndroidManifest.xml (package), '
      'and PRODUCT_BUNDLE_IDENTIFIER in '
      'ios/Runner.xcodeproj/project.pbxproj.',
    );
  }

  // A pure text substitution can silently break `directives_ordering`: import
  // lines don't move, but the new package name can sort differently than
  // `flutter_starter` did relative to the other imports in the same file
  // (verified: renaming to a name starting before 'f' does exactly this).
  // `pub get` first, so `package:$name/...` resolves under the new pubspec
  // name; then a scoped `dart fix` only touches that one lint, nothing else.
  final pubGet = await Process.run('flutter', ['pub', 'get'], runInShell: true);
  stdout.write(pubGet.stdout);
  stderr.write(pubGet.stderr);
  if (pubGet.exitCode == 0) {
    final fix = await Process.run('dart', [
      'fix',
      '--apply',
      '--code=directives_ordering',
    ], runInShell: true);
    stdout.write(fix.stdout);
    stderr.write(fix.stderr);
  } else {
    print(
      'flutter pub get failed, so import ordering was not auto-fixed. Run '
      '`flutter pub get && dart fix --apply --code=directives_ordering` '
      'yourself once dependencies resolve.',
    );
  }

  if (display != null) {
    print('Set APP_NAME=$display in .env and .env.production.');
  }
  print('Done. Next: cp .env.example .env && flow flavor run dev');
}

bool _isRewritable(String path) {
  if (path.contains('/.git/') || path.contains('/build/')) return false;
  if (path.contains('/.dart_tool/')) return false;
  return path.endsWith('.dart') ||
      path.endsWith('.yaml') ||
      path.endsWith('.md');
}

({String name, String org, String? display})? _parseArgs(List<String> args) {
  String? name;
  String? org;
  String? display;

  for (var i = 0; i < args.length - 1; i++) {
    switch (args[i]) {
      case '--name':
        name = args[i + 1];
      case '--org':
        org = args[i + 1];
      case '--display':
        display = args[i + 1];
    }
  }

  if (name == null || org == null) return null;
  return (name: name, org: org, display: display);
}
