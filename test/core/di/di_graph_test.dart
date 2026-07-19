import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

/// In-memory adapter so the graph can be built without platform channels.
class FakeStorageAdapter implements StorageAdapter {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Future<void> init() async {}

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<double?> getDouble(String key) async => _values[key] as double?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      _values[key] as List<String>?;

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> clear({Set<String>? allowList}) async {
    _values.clear();
    return true;
  }

  @override
  Future<Set<String>> getKeys() async => _values.keys.toSet();

  @override
  Future<void> reload() async {}

  @override
  Future<void> close() async {}
}

void main() {
  group('DI graph', () {
    test('appStorageProvider throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps the create-callback error in a ProviderException on
      // read; assert on the wrapped UnimplementedError to test the actual
      // seam rather than the framework's wrapping behavior.
      expect(
        () => container.read(appStorageProvider),
        throwsA(
          isA<ProviderException>().having(
            (exception) => exception.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('graph constructs when the async seam is overridden', () async {
      await AppStorage.initializeWithAdapter(FakeStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      final injected = AppStorage.instance;
      final container = ProviderContainer(
        overrides: [appStorageProvider.overrideWithValue(injected)],
      );
      addTearDown(container.dispose);

      final resolved = container.read(appStorageProvider);
      // Identity, not just type: proves the override resolves to the exact
      // instance that was injected rather than merely something AppStorage-
      // shaped.
      expect(resolved, same(injected));

      // Round-trip a value through the provider's AppStorage to prove the
      // seam is wired to a live, working backing store — this would fail if
      // the override pointed at the wrong instance or an unwired fake.
      await resolved.setString('probe', 'graph-seam');
      expect(await resolved.getString('probe'), 'graph-seam');
    });

    test('each test gets a fresh AppStorage instance (regression guard for the '
        'silent re-init no-op)', () async {
      await AppStorage.initializeWithAdapter(FakeStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      // AppStorage.initializeWithAdapter() early-returns if a singleton
      // already exists, so a missing resetForTesting() in the previous
      // test's teardown would silently hand this test the earlier fake
      // adapter — complete with its 'probe' value from the test above.
      final value = await AppStorage.instance.getString('probe');
      expect(value, isNull);
    });

    // The 'api clients construct once the runtime is configured' test used
    // to live here. It moved to test/core/network/api_kit_setup_test.dart
    // because it calls ApiKitRuntime.use(...), which has no reset mechanism
    // and permanently mutates process-wide static state for the rest of
    // this isolate — see that file for the full explanation.
  });
}
