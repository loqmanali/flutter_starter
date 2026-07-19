import 'package:flutter_test/flutter_test.dart';

import '../../tool/rename.dart';

void main() {
  group('rewritePackageReferences', () {
    test('rewrites package imports', () {
      const source = "import 'package:flutter_starter/app.dart';";

      expect(
        rewritePackageReferences(source, from: 'flutter_starter', to: 'my_app'),
        "import 'package:my_app/app.dart';",
      );
    });

    test('rewrites the pubspec name field', () {
      expect(
        rewritePackageReferences(
          'name: flutter_starter',
          from: 'flutter_starter',
          to: 'my_app',
        ),
        'name: my_app',
      );
    });

    test('leaves unrelated identifiers containing the name alone', () {
      const source = 'const flutter_starter_legacy = 1;';

      expect(
        rewritePackageReferences(source, from: 'flutter_starter', to: 'my_app'),
        source,
      );
    });

    test('is case-sensitive and idempotent', () {
      const source = 'name: flutter_starter';
      final once = rewritePackageReferences(
        source,
        from: 'flutter_starter',
        to: 'my_app',
      );
      final twice = rewritePackageReferences(
        once,
        from: 'flutter_starter',
        to: 'my_app',
      );

      expect(once, twice);
    });
  });
}
