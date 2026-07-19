import 'package:api_kit/api_kit.dart';
import 'package:flutter_starter/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a canned payload or throws a canned exception.
class _StubApiClient implements ApiClient {
  _StubApiClient({this.response, this.error});

  final Object? response;
  final Object? error;

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? bearerTokenOverride,
  }) async {
    if (error != null) throw error!;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not needed for these tests');
}

void main() {
  group('AuthRepository.signIn', () {
    test('parses a token pair from a data-wrapped payload', () async {
      final repository = AuthRepository(
        _StubApiClient(
          response: {
            'data': {'access_token': 'a-token', 'refresh_token': 'r-token'},
          },
        ),
      );

      final tokens = await repository.signIn(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(tokens.accessToken, 'a-token');
      expect(tokens.refreshToken, 'r-token');
    });

    test('parses an unwrapped payload too', () async {
      final repository = AuthRepository(
        _StubApiClient(
          response: {'access_token': 'a-token', 'refresh_token': 'r-token'},
        ),
      );

      final tokens = await repository.signIn(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(tokens.accessToken, 'a-token');
      expect(tokens.refreshToken, 'r-token');
    });

    test(
      'falls back to the access token when no refresh token is returned',
      () async {
        final repository = AuthRepository(
          _StubApiClient(
            response: {
              'data': {'access_token': 'a-token'},
            },
          ),
        );

        final tokens = await repository.signIn(
          email: 'user@example.com',
          password: 'secret',
        );

        expect(tokens.accessToken, 'a-token');
        expect(tokens.refreshToken, 'a-token');
      },
    );

    test('converts an ApiException into a Failure', () async {
      final repository = AuthRepository(
        _StubApiClient(error: const UnauthorizedException('Bad credentials')),
      );

      await expectLater(
        repository.signIn(email: 'user@example.com', password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            'Bad credentials',
          ),
        ),
      );
    });

    test('throws ServerFailure when the payload has no access token', () async {
      final repository = AuthRepository(_StubApiClient(response: {'data': {}}));

      await expectLater(
        repository.signIn(email: 'user@example.com', password: 'secret'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test(
      'throws ServerFailure when the response is not a Map at all',
      () async {
        final repository = AuthRepository(
          _StubApiClient(response: 'not-a-map'),
        );

        await expectLater(
          repository.signIn(email: 'user@example.com', password: 'secret'),
          throwsA(isA<ServerFailure>()),
        );
      },
    );

    test('throws ServerFailure when data is present but not a Map', () async {
      final repository = AuthRepository(
        _StubApiClient(response: {'data': 'not-a-map'}),
      );

      await expectLater(
        repository.signIn(email: 'user@example.com', password: 'secret'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test(
      'throws ServerFailure when the access token is an empty string',
      () async {
        final repository = AuthRepository(
          _StubApiClient(
            response: {
              'data': {'access_token': '', 'refresh_token': 'r-token'},
            },
          ),
        );

        await expectLater(
          repository.signIn(email: 'user@example.com', password: 'secret'),
          throwsA(isA<ServerFailure>()),
        );
      },
    );

    test(
      'throws ServerFailure when the access token has the wrong type',
      () async {
        final repository = AuthRepository(
          _StubApiClient(
            response: {
              'data': {'access_token': 12345, 'refresh_token': 'r-token'},
            },
          ),
        );

        await expectLater(
          repository.signIn(email: 'user@example.com', password: 'secret'),
          throwsA(isA<ServerFailure>()),
        );
      },
    );
  });
}
