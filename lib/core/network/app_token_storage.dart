import 'package:api_kit/api_kit.dart';
import 'package:storage_kit/storage_kit.dart';

/// Bridges api_kit's [AuthTokenStorageAdapter] contract onto storage_kit's
/// [AppStorage], which already owns the token keys.
class AppTokenStorage implements AuthTokenStorageAdapter {
  const AppTokenStorage(this._storage);

  final AppStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> clearAuthData() async {
    await _storage.clearAuthData();
  }
}
