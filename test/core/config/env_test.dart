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

  group('Env.validateConfig', () {
    test('throws EnvException when flavor does not match expectedFlavor', () {
      expect(
        () => Env.validateConfig(
          flavor: 'dev',
          expectedFlavor: 'production',
          baseUrl: 'https://api.example.com',
          appName: 'Example',
        ),
        throwsA(
          isA<EnvException>().having(
            (e) => e.message,
            'message',
            contains('BUILD_ENV'),
          ),
        ),
      );
    });

    test('throws EnvException when baseUrl is empty', () {
      expect(
        () => Env.validateConfig(
          flavor: 'dev',
          expectedFlavor: 'dev',
          baseUrl: '',
          appName: 'Example',
        ),
        throwsA(
          isA<EnvException>().having(
            (e) => e.message,
            'message',
            contains('BASE_URL is required'),
          ),
        ),
      );
    });

    test(
      'throws EnvException when baseUrl is not an absolute http/https URL',
      () {
        expect(
          () => Env.validateConfig(
            flavor: 'dev',
            expectedFlavor: 'dev',
            baseUrl: 'api.example.com',
            appName: 'Example',
          ),
          throwsA(
            isA<EnvException>().having(
              (e) => e.message,
              'message',
              contains('must be an absolute URL'),
            ),
          ),
        );
      },
    );

    test('throws EnvException when appName is empty', () {
      expect(
        () => Env.validateConfig(
          flavor: 'dev',
          expectedFlavor: 'dev',
          baseUrl: 'https://api.example.com',
          appName: '',
        ),
        throwsA(
          isA<EnvException>().having(
            (e) => e.message,
            'message',
            contains('APP_NAME is required'),
          ),
        ),
      );
    });

    test('returns normally when all values are valid', () {
      expect(
        () => Env.validateConfig(
          flavor: 'dev',
          expectedFlavor: 'dev',
          baseUrl: 'https://api.example.com',
          appName: 'Example',
        ),
        returnsNormally,
      );
    });
  });
}
