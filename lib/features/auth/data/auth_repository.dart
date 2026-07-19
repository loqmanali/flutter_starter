import 'package:api_kit/api_kit.dart';
import 'package:flutter/foundation.dart';

@immutable
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// The only layer between the HTTP client and the notifier.
///
/// There is no separate datasource and no usecase: both would forward calls
/// unchanged. Parsing is defensive because backends wrap payloads
/// inconsistently — tolerate a `data` envelope or its absence.
class AuthRepository {
  const AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthTokens> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseTokens(response);
    } on ApiException catch (exception) {
      throw ErrorMapper.mapExceptionToFailure(exception);
    }
  }

  AuthTokens _parseTokens(dynamic response) {
    final root = response is Map ? response : const <String, dynamic>{};
    final payload = root['data'] is Map ? root['data'] as Map : root;

    final access = payload['access_token'];
    final refresh = payload['refresh_token'];

    if (access is! String || access.isEmpty) {
      throw const ServerFailure(
        message: 'Sign-in succeeded but no access token was returned.',
      );
    }

    // Sanctum-style backends issue no refresh token; reuse the access token so
    // the storage contract stays satisfied.
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh is String && refresh.isNotEmpty ? refresh : access,
    );
  }
}
