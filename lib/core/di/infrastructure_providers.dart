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
