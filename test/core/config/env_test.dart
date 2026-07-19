import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Env.load', () {
    test('throws EnvException when BUILD_ENV does not match the entrypoint', () {
      // No --dart-define values are present under `flutter test`, so BUILD_ENV
      // is the empty string and can never equal 'dev'.
      expect(
        () => Env.load(expectedFlavor: 'dev'),
        throwsA(
          isA<EnvException>().having(
            (e) => e.message,
            'message',
            contains('BUILD_ENV'),
          ),
        ),
      );
    });

    test('EnvException carries a readable message', () {
      const exception = EnvException('BASE_URL is required');
      expect(exception.toString(), contains('BASE_URL is required'));
    });
  });
}
