import 'package:api_kit/api_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_kit/storage_kit.dart';

/// App-wide infrastructure graph.
///
/// [appStorageProvider] is the async-init seam: `AppStorage.initialize()` must
/// complete before the graph is read, so the provider throws by construction
/// and `bootstrap()` supplies the initialized instance through a
/// `ProviderScope` override. This keeps async dependencies out of the graph
/// without making the graph itself async.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError(
    'appStorageProvider must be overridden in bootstrap() with an '
    'already-initialized AppStorage instance.',
  ),
);

/// Client for endpoints requiring the user's bearer token.
final apiClientProvider = Provider<ApiClient>(
  (ref) => DioApiClient.authenticated(),
);

/// Client for endpoints that take no auth (sign-in, public config).
final publicApiClientProvider = Provider<ApiClient>(
  (ref) => DioApiClient.public(),
);
