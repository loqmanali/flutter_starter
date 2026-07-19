# Flutter Starter

Opinionated Riverpod starter kit wiring
[`flutter_kits`](https://github.com/loqmanali/flutter_kits) into a running
app. Wiring lives here; capability lives in the kits.

## Quick start

```bash
gh repo create my_app --template loqmanali/flutter_starter --private --clone
cd my_app
dart run tool/rename.dart --name my_app --org com.acme --display "My App"
cp .env.dev.example .env.dev          # then edit BASE_URL
flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

`tool/rename.dart` rewrites every `package:flutter_starter` reference and the
pubspec `name:` field, then renames the Android/iOS bundle id via
`change_app_package_name` (a dev-only dependency). If that step fails — e.g.
before your first `flutter pub get` — it prints the exact files to edit by
hand instead of failing silently.

Plain `flutter run` (no `-t`) deliberately fails: `lib/main.dart` is an
unflavored guard that writes a usage message to stderr and exits `64`. Always
launch a flavored entrypoint, either directly (above) or through `flow` (see
below).

## The boundary rule

**The template owns wiring. The kits own capability.** If code could serve two
apps, it belongs in `flutter_kits`, not here. Kits are pinned to one git tag
(`v1.1.5` as of this writing) via a `git:`/`path:` dependency in
`pubspec.yaml`; bump it deliberately, never float the ref. Bumping a kit can
raise its own transitive requirements — e.g. `force_update_gate` needs
`package_info_plus: ^9.0.0`, which is why this pubspec pins that too.

For local kit development, create a git-ignored `pubspec_overrides.yaml` with
a path override (already in `.gitignore`). The committed `pubspec.yaml` always
stays on the git ref.

## Conventions

| Topic | Rule |
|---|---|
| State | Hand-written Riverpod 3. No `@riverpod`, no `build_runner`. |
| Errors | Repositories throw; `ErrorMapper` maps to `Failure`; notifiers use `AsyncValue.guard`. No `Either`, no `Result<T>`. |
| Layering | `data/` (models + repository) and `presentation/` (providers, screens, widgets). Add `domain/` only for pure logic worth unit-testing without Flutter. No usecase layer, no separate datasource — both would just forward calls unchanged. |
| Sizing | `WidgetKitTokens` and `WidgetKitBreakpoints`. No `flutter_screenutil`. App-owned brand/status colours live in `lib/core/theme/app_tokens.dart`. |
| Routing | Per-feature `*_routes.dart` composed in `app_router.dart`. `AuthGuard.redirect` is pure and unit-tested without a router, a widget tree, or Riverpod. |
| Strings | Edit `.arb`, then run **`dart run tool/update_l10n.dart`** — running only `flutter gen-l10n` leaves the `L10n` forwarders stale. A test asserts the ARB key count matches the forwarder count, so a missed regen fails the gate. `L10n.foo` works without a `BuildContext`. |
| Flavors | Two entrypoints, `lib/main_dev.dart` / `lib/main_production.dart`, each calling `bootstrap(flavor)`, which validates `BUILD_ENV` against the entrypoint (`lib/core/config/env.dart`). Config is compiled in via `--dart-define-from-file`, never bundled where it could be unzipped out of a release APK. Releases are built through the `flow` CLI's **deploy** subsystem (`.flow_deploy.json`), not its flavor subsystem — see "Flavors and builds" below. |

## Flavors and builds

This repo has no native Android product flavors or iOS schemes — only two
Dart-level flavors, distinguished by entrypoint (`lib/main_dev.dart` /
`lib/main_production.dart`) and by `--dart-define-from-file`. `lib/main.dart`
(no flavor) always exits `64`.

### Local development

Run the app directly with Flutter, pointing at the flavor's entrypoint and
env file:

```bash
flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

The flavor-scoped equivalent that a real deploy would use adds `--flavor`:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

**Verified caveat:** `--flavor` requires a matching native Android product
flavor / iOS scheme, and this repo ships none (see `.flow_flavor.json`
below) — `flutter build apk --flavor dev ...` fails today with *"The
android/app/build.gradle.kts file does not define any custom product
flavors. You cannot use the --flavor option."* Until you add native flavors
(`flow flavor init`), drop `--flavor` — the entrypoint and dart-defines above
are all this app actually reads.

### Building a release with `flow deploy`

Install `flow` (the bare `dart pub global activate flow` name resolves to an
unrelated pub.dev package — install from git):

```bash
dart pub global activate --source git https://github.com/loqmanali/flow.git
```

`.flow_deploy.json` declares a `dev` and a `production` profile, each mapped
to its build target and (via the `.env.<flavor>` convention) its env file:

```bash
flow deploy run dev          # or the shortcut: flow dev
flow deploy run production   # or: flow production
```

This resolves to `flutter build ... --flavor <profile> --target
lib/main_<profile>.dart --dart-define-from-file=.env.<profile>` — confirmed
directly against `BuildService.flavorBuildArguments` for both profiles with
real `.env.dev` / `.env.production` files present. `flow deploy` always runs
a **build** (apk/appbundle/ipa), never `flutter run`; for the local edit-run
loop, use the raw command above instead.

**What's verified vs. not:** config loading, profile resolution (flavor,
target, provider, mode), and dart-define-file resolution are all confirmed
against the real `flow` CLI (`flow deploy run dev|production --skip-build`).
Actually publishing (`flow deploy beta|update`, or a full unabridged `flow
deploy run <profile>`) additionally needs the `ios.app_store_connect` /
`*.firebase_app_distribution` placeholders in `.flow_deploy.json` replaced
with real credentials, and — for a real device artifact — native flavors (see
above). Neither was exercised end-to-end here; both fail cleanly and
legibly (not silently) on the placeholder values shipped in this repo.

### `.flow_flavor.json`: removed

The version this repo previously shipped didn't match `flow`'s real schema
(`flavors` must be a `List<String>`, plus several other required root keys —
see `config_validator.dart` in `flow`'s source) and would throw immediately.
It's deleted rather than fixed: `flow flavor`'s config bakes flavor values into
a generated Dart file at `app_config_path`, which is a different, competing
mechanism to this project's actual design (`Env` + `--dart-define-from-file`,
values never committed). If you want real native Android/iOS flavor
scaffolding (per-flavor app icons, bundle-id suffixes, Xcode schemes), run
`flow flavor init` to generate a fresh, valid `.flow_flavor.json` and apply
it — just know it manages a separate concern from `.flow_deploy.json`.

### Firebase / push notifications

The Dart side is fully wired: `bootstrap()` calls `Firebase.initializeApp()`
and `NotifyKit.init()` (see `lib/core/notifications/notifications_setup.dart`),
and `buildNotifyConfig` sets `requestPermissionOnInit: true`. **Native setup
is not done in this repo.** A fresh clone boots fine — Firebase/`NotifyKit`
init is wrapped in a `try`/`catch` that logs a warning instead of crashing —
but push will not actually arrive until you add, per flavor:

- Google Services config (`google-services.json` / `GoogleService-Info.plist`)
  and the `com.google.gms.google-services` Gradle plugin, which
  `android/build.gradle.kts` and `android/app/build.gradle.kts` do not declare
  today. `flow flavor firebase` (via the `flutterfire` CLI) generates and
  wires these — but it first needs a valid `.flow_flavor.json`, which this
  repo does not ship (see above); run `flow flavor init` first.
- Android 13+ notification permission: `POST_NOTIFICATIONS` in
  `android/app/src/main/AndroidManifest.xml`. Required because
  `requestPermissionOnInit: true` asks for it at runtime, and there is no
  permission to grant without the manifest entry. Neither `flow flavor
  firebase` nor `flutterfire configure` adds this — you add it by hand.
- iOS: `UIBackgroundModes` → `remote-notification` in `ios/Runner/Info.plist`,
  plus the Push Notifications capability/entitlement (`aps-environment`),
  added in Xcode. This repo ships no `.entitlements` file at all, and neither
  `flutterfire configure` nor `flow` adds one.

## Adding a feature

```
lib/features/orders/
├── data/
│   └── order_repository.dart   # model(s) + HTTP + defensive parsing; throws Failure
└── presentation/
    ├── order_providers.dart    # repository provider + notifiers
    ├── order_routes.dart       # this feature's List<RouteBase>
    └── orders_screen.dart
```

(`widgets/` is a reasonable addition once a feature has screen-specific
widgets worth splitting out — `features/auth/`, the worked example below,
doesn't need one yet.)

Then add `...orderRoutes` to `routes:` in `lib/core/navigation/app_router.dart`.

`lib/features/auth/` is the worked example — start there.

## Optional: `@riverpod` code generation

The default is hand-written providers, matching every kit in `flutter_kits`.
To opt in, decide **at project start** — never per-feature, or the codebase
ends up mixed.

Add to `dev_dependencies`: `build_runner: ^2.4.14`, `riverpod_generator:
^4.0.4`; add `riverpod_annotation: ^4.0.3` to `dependencies`. Then:

1. Sealed state classes become `AsyncValue<T>`.
2. `ref.watch` only in `build()`; `ref.read` in methods and callbacks.
3. `if (!ref.mounted) return;` after every `await` in a notifier method.
4. Generated providers are `autoDispose` by default, so global state needs
   `@Riverpod(keepAlive: true)`. Any notifier that `ref.read`s a list provider
   and refreshes it **after an `await`** must be `keepAlive` — otherwise it is
   disposed mid-flight and throws `UnmountedRefException`.
5. Every `keepAlive: true` carries a comment saying why.

## Quality gate

```bash
dart format --set-exit-if-changed . && flutter analyze && flutter test
```

CI (`.github/workflows/ci.yml`) runs exactly this on push to `main` and on
every pull request.
