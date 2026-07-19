import 'package:api_kit/api_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../di/di_graph_test.dart' show FakeStorageAdapter;

// ApiKitRuntime is process-wide mutable static state with no reset
// mechanism: `ApiKitRuntime.use(...)` only merges non-null values, so a
// field set once stays set for the rest of the isolate's life. Calling it
// here permanently configures the runtime's baseUrl for every other test
// that happens to run afterward in the same isolate.
//
// `flutter test` gives each *file* its own isolate, so this can't leak into
// other test files — but it would silently become an ordering dependency
// for any other test added to *this* file later. This file is deliberately
// kept to a single test for that reason: don't add unrelated tests here.
void main() {
  test('api clients construct once the runtime is configured', () async {
    ApiKitRuntime.use(baseUrl: 'https://api.test.local');
    await AppStorage.initializeWithAdapter(FakeStorageAdapter());
    addTearDown(AppStorage.resetForTesting);

    final container = ProviderContainer(
      overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
    );
    addTearDown(container.dispose);

    expect(container.read(apiClientProvider), isA<ApiClient>());
    expect(container.read(publicApiClientProvider), isA<ApiClient>());
  });
}
