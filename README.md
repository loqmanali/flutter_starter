# Flutter Starter

Opinionated Riverpod starter kit wiring [`flutter_kits`](https://github.com/loqmanali/flutter_kits) into a running app. Wiring lives here; capability lives in the kits.

[![CI](https://github.com/loqmanali/flutter_starter/actions/workflows/ci.yml/badge.svg)](https://github.com/loqmanali/flutter_starter/actions/workflows/ci.yml)
![Dart SDK](https://img.shields.io/badge/Dart-%5E3.10.0-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/state-Riverpod%203-6741d9)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

```bash
dart pub global activate --source git https://github.com/loqmanali/flow.git
flow create my_app --org com.acme --display "My App"
```

## Table of contents

- [What you get](#what-you-get)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [The boundary rule](#the-boundary-rule)
- [Project structure](#project-structure)
- [Conventions](#conventions)
- [Adding a feature](#adding-a-feature)
- [Localization](#localization)
- [Theming](#theming)
- [Flavors and builds](#flavors-and-builds)
- [Firebase / push notifications](#firebase--push-notifications)
- [Testing](#testing)
- [CI](#ci)
- [The kits](#the-kits)
- [Optional: `@riverpod` code generation](#optional-riverpod-code-generation)
- [Troubleshooting / gotchas](#troubleshooting--gotchas)
- [License](#license)

## What you get

| Concern | Approach |
|---|---|
| State management | Hand-written Riverpod 3 (`flutter_riverpod: ^3.3.2`) — no code generation |
| Networking | [`api_kit`](https://github.com/loqmanali/flutter_kits) — Dio client, typed exceptions, `ErrorMapper` → `Failure` |
| Storage | [`storage_kit`](https://github.com/loqmanali/flutter_kits) — token + locale + theme persistence |
| Logging | [`logging_kit`](https://github.com/loqmanali/flutter_kits) — the one `AppLogger` used everywhere |
| Widgets & sizing | [`widget_kit`](https://github.com/loqmanali/flutter_kits) — `WidgetKitTheme`, `WidgetKitTokens`, `WidgetKitBreakpoints` |
| Localization | [`localization_kit`](https://github.com/loqmanali/flutter_kits) + generated `.arb` + a context-free `L10n` forwarder |
| Navigation | `go_router` (routes) + [`navigation_kit`](https://github.com/loqmanali/flutter_kits) (bottom nav bar) |
| Push notifications | [`notify_kit`](https://github.com/loqmanali/flutter_kits) — Dart side wired; native setup **not** included (see below) |
| Force update | [`force_update_gate`](https://github.com/loqmanali/flutter_kits) — gates the app behind a store-version check |
| Rename tool | `tool/rename.dart` — rewrites package name, org, bundle id, display name |
| Scaffolder | `flow create` — clones + renames in one command |
| Quality gate | `flutter_lints` + `riverpod_lint`, `dart format`, `flutter test`, GitHub Actions CI |

## Requirements

- Dart SDK `^3.10.0` (declared in `pubspec.yaml`; Flutter stable ships a matching Dart)
- Flutter, stable channel
- [`gh`](https://cli.github.com/) — only for the manual template path
- [`flow`](https://github.com/loqmanali/flow) — optional, for `flow create` and `flow deploy`

## Quick start

Two ways to get a new project. Pick one.

### Option A — `flow create` (one command)

`flow` is a separate CLI. Its name collides with an unrelated package already
published on pub.dev, so it must be installed from git, never with the bare
`dart pub global activate flow`:

```bash
dart pub global activate --source git https://github.com/loqmanali/flow.git
```

Then scaffold:

```bash
flow create my_app --org com.acme --bundle-id com.acme.myapp --display "My App"
cd my_app
cp .env.dev.example .env.dev          # then edit BASE_URL
flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

`flow create` clones a template (by default, this repo's `main`), detaches
git history, and rewrites the package name, Android `applicationId`, iOS
`PRODUCT_BUNDLE_IDENTIFIER`, and both platforms' display name — then runs
`flutter pub get` and a scoped `dart fix` for import ordering.

<details>
<summary>Full <code>flow create</code> flags</summary>

| Flag | Default | Meaning |
|---|---|---|
| `<name>` (positional) | — | Required. Project name, `lower_snake_case`. |
| `--org` | `com.example` | Reverse-domain org; bundle id is `<org>.<name>` unless overridden. |
| `--bundle-id` | — | Explicit bundle id, overriding `<org>.<name>`. |
| `--display` | title-cased `<name>` | Human-readable app name (Android label, iOS `CFBundleDisplayName`). |
| `--template` | this repo | Git URL of the template to clone. |
| `--ref` | `main` | Git ref/tag/branch of the template. |
| `--flavors` | — | Comma-separated native Android product flavors, e.g. `dev,production`. Android-only; iOS schemes are **not** generated — run `flow flavor init` or add them by hand. |
| `--output` | cwd | Parent directory to create the project in. |
| `--no-pub-get` | (pub-get runs) | Skip `flutter pub get` + import-order fix after scaffolding. |

</details>

> **Branch note:** `flow create` was developed on `flow`'s
> `fix/dart-define-and-track` branch and has since merged into `main` — the
> plain install command above already includes it. If you're on an older
> clone of `flow` that predates the merge, update it, or pin explicitly:
> `dart pub global activate --source git https://github.com/loqmanali/flow.git --git-ref fix/dart-define-and-track`.

### Option B — GitHub template + manual rename

```bash
gh repo create my_app --template loqmanali/flutter_starter --private --clone
cd my_app
dart run tool/rename.dart --name my_app --org com.acme --display "My App"
cp .env.dev.example .env.dev          # then edit BASE_URL
flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev
```

`tool/rename.dart` does the rewrite by hand, on an existing clone: it rewrites
every `package:flutter_starter` reference and the pubspec `name:` field, then
renames the Android/iOS bundle id via `change_app_package_name` (a dev-only
dependency). Flags: `--name` (required, `lower_snake_case`), `--org`
(required), `--display` (optional). If the bundle-id rename step fails — e.g.
before your first `flutter pub get` — it prints the exact files to edit by
hand instead of failing silently.

### The exit-64 guard

Plain `flutter run` (no `-t`) deliberately fails: `lib/main.dart` is an
unflavored guard that writes a usage message to stderr and exits `64`. Always
launch a flavored entrypoint — `lib/main_dev.dart` or
`lib/main_production.dart` — as shown above.

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

## Project structure

```
lib/
├── app.dart                          # MaterialApp.router, theme/locale wiring
├── app_bootstrap.dart                # bootstrap(flavor): the one startup sequence
├── main.dart                         # unflavored guard — exits 64
├── main_dev.dart                     # bootstrap('dev')
├── main_production.dart              # bootstrap('production')
├── core/
│   ├── bootstrap/app_initialization_error_screen.dart
│   ├── config/env.dart               # compile-time config + validation
│   ├── di/infrastructure_providers.dart
│   ├── error/error_view.dart
│   ├── localization/                 # .arb files, generated l10n, L10n forwarders
│   ├── navigation/                   # app_router.dart, auth_guard.dart, route_paths.dart
│   ├── network/                      # api_kit_setup.dart, app_token_storage.dart
│   ├── notifications/notifications_setup.dart
│   └── theme/                        # app_theme.dart, app_tokens.dart
└── features/
    ├── auth/
    │   ├── data/auth_repository.dart
    │   └── presentation/{auth_providers,auth_routes,sign_in_screen}.dart
    ├── home/presentation/home_screen.dart
    ├── settings/presentation/{settings_screen,theme_mode_provider}.dart
    └── shell/presentation/{shell_routes,shell_screen}.dart
```

`features/auth/` is the smallest complete example: a repository, a
`Notifier<AsyncValue<void>>`, a route list, and a screen — no `widgets/`
folder, because it doesn't have screen-specific widgets worth splitting out
yet. Start there.

## Conventions

| Topic | Rule |
|---|---|
| State | Hand-written Riverpod 3. No `@riverpod`, no `build_runner` (opt-in section below). |
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

**`--flavor` does not work in this repo.** It requires a matching native
Android product flavor / iOS scheme, and none exist here —
`flutter build apk --flavor dev ...` fails with *"The
android/app/build.gradle.kts file does not define any custom product
flavors. You cannot use the --flavor option."* The entrypoint +
`--dart-define-from-file` above are all this app actually reads. Add native
flavors first (`flow flavor init`, or `flow create ... --flavors
dev,production`) if you need `--flavor` to work.

`flow`'s `flavor` subsystem (`flow flavor init/add/build/firebase/...`) bakes
flavor values into a generated Dart config file and is a different,
competing mechanism to this project's actual design (`Env` +
`--dart-define-from-file`, nothing committed). Use it only if you're adding
real native flavor scaffolding — it's unrelated to the `deploy` subsystem
below.

### Building a release with `flow deploy`

`.flow_deploy.json` declares a `dev` and a `production` profile, each mapped
to a build target (`lib/main_<profile>.dart`) and, by convention, an
`.env.<profile>` file:

```bash
flow deploy run dev          # or the shortcut: flow dev
flow deploy run production   # or: flow production
```

This resolves to `flutter build ... --flavor <profile> --target
lib/main_<profile>.dart --dart-define-from-file=.env.<profile>` — verified
against `BuildService.flavorBuildArguments` in `flow`'s source for both
profiles with real `.env.dev` / `.env.production` files present. `flow
deploy` always runs a **build** (apk/appbundle/ipa), never `flutter run`; use
the raw command above for the local edit-run loop.

Actually publishing (`flow deploy beta|update`) additionally needs the
`ios.app_store_connect` / `*.firebase_app_distribution` placeholders in
`.flow_deploy.json` replaced with real credentials, and — for a real device
artifact — native flavors (see above). Neither is exercised in this repo;
both fail cleanly on the placeholder values shipped here.

## Firebase / push notifications

The Dart side is fully wired: `bootstrap()` calls `Firebase.initializeApp()`
and `NotifyKit.init()` (`lib/core/notifications/notifications_setup.dart`),
and `buildNotifyConfig` sets `requestPermissionOnInit: true`. **Native setup
is not done in this repo.** A fresh clone boots fine — the init call is
wrapped in a `try`/`catch` that logs a warning instead of crashing — but push
will not actually arrive until you add, per flavor:

- Google Services config (`google-services.json` / `GoogleService-Info.plist`)
  and the `com.google.gms.google-services` Gradle plugin — neither
  `android/build.gradle.kts` nor `android/app/build.gradle.kts` declares it
  today. `flow flavor firebase` (via the `flutterfire` CLI) can generate and
  wire these, but it needs a valid `.flow_flavor.json` first (`flow flavor
  init`) — this repo ships neither.
- Android 13+ notification permission: `POST_NOTIFICATIONS` in
  `android/app/src/main/AndroidManifest.xml`. Not present today. Required
  because `requestPermissionOnInit: true` asks for it at runtime, and there
  is nothing to grant without the manifest entry. Neither `flow flavor
  firebase` nor `flutterfire configure` adds this — add it by hand.
- iOS: `UIBackgroundModes` → `remote-notification` in `ios/Runner/Info.plist`
  (not present today), plus the Push Notifications capability/entitlement
  (`aps-environment`), added in Xcode. This repo ships no `.entitlements`
  file at all, and neither `flutterfire configure` nor `flow` adds one.

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
widgets worth splitting out — `features/auth/` doesn't need one yet.)

Then add `...orderRoutes` to `routes:` in `lib/core/navigation/app_router.dart`.

## Localization

`.arb` files live in `lib/core/localization/l10n/` (`app_en.arb`, `app_ar.arb`
— the two locales this app ships, see `supportedLocales` in
`localization.dart`). `l10n.yaml` points `flutter gen-l10n` at that directory
and generates `AppLocalizations` there.

Editing a string is **two steps**:

```bash
dart run tool/update_l10n.dart
```

This runs `flutter gen-l10n`, then `tool/generate_l10n_forwarders.dart`, which
parses the generated `abstract class AppLocalizations` and emits
`l10n_forwarders.g.dart` — a static `L10n` class so code with no
`BuildContext` (repositories, interceptors, background isolates) can still
read a string: `L10n.sessionExpired`. Running `flutter gen-l10n` alone leaves
`L10n` stale. `test/core/localization/l10n_forwarders_test.dart` asserts the
ARB message-key count equals the generated accessor count, so a missed
regeneration fails CI.

`L10n.init(context)` is called once, high in the tree (`lib/app.dart`'s
`builder`), to cache the active `AppLocalizations` and locale.

## Theming

`lib/core/theme/app_theme.dart` builds light/dark `ThemeData` from a single
seed color (`AppTokens.seed`) via `ColorScheme.fromSeed`, and registers a
`WidgetKitTheme` extension so `widget_kit` widgets and stock
`TextField`/`FilledButton` share one corner-radius and button-height
decision.

`lib/core/theme/app_tokens.dart` holds colors this app owns: the brand
`seed`, plus `success`/`warning`/`danger`/`info` status colors (unreferenced
today — kept for the first screen that needs a status banner or chip).
Spacing, radius, font sizes, and breakpoints are **not** redefined here —
they come from `WidgetKitTokens` / `WidgetKitBreakpoints` so app code and kit
widgets agree on one scale. There is no `flutter_screenutil` in this stack.

## Testing

```bash
flutter test
```

68 tests across 16 files. Notable ones:

| Test | Covers |
|---|---|
| `test/core/localization/l10n_forwarders_test.dart` | The ARB-vs-forwarder drift check described above |
| `test/core/navigation/auth_guard_test.dart` | `AuthGuard.redirect` as pure logic, no router/widget tree |
| `test/core/config/env_test.dart` | `Env.validateConfig`'s four guards, driven with explicit parameters (compile-time constants are always empty under `flutter test`) |
| `test/core/di/di_graph_test.dart` | The provider graph builds with a fake `StorageAdapter`, no platform channels |
| `test/scaffold_test.dart` | Every kit is importable and its core symbols resolve |
| `test/app_test.dart` | Sign-out redirect, and notification-tap routing (known + unknown routes) end to end |
| `test/tool/rename_test.dart` | `tool/rename.dart`'s package-reference rewrite |

## CI

`.github/workflows/ci.yml` runs on push to `main` and on every pull request:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
dart analyze
flutter test
```

Both `flutter analyze` and `dart analyze` run — see the `riverpod_lint`
gotcha below for why.

## The kits

All eight are pinned to `flutter_kits` tag **`v1.1.5`** via `git:`/`path:` in
`pubspec.yaml`.

| Kit | Purpose |
|---|---|
| `api_kit` | Dio-powered HTTP client — auth-token refresh, language-header injection, typed exceptions, `ErrorMapper` → `Failure` |
| `storage_kit` | Key-value storage facade — `SharedPreferences` or Hive (optionally encrypted) behind one API |
| `logging_kit` | The single `AppLogger` — level filtering, pluggable handler, ANSI console output |
| `widget_kit` | Reusable widgets (buttons, inputs, dialogs, feedback, media, shimmer) plus `WidgetKitTheme`/`WidgetKitTokens`/`WidgetKitBreakpoints` |
| `localization_kit` | Locale state on Riverpod, persisted language, RTL handling |
| `navigation_kit` | The animated bottom navigation bar used in `ShellScreen` |
| `notify_kit` | FCM + local notifications behind one `init()`, unified tap routing |
| `force_update_gate` | Store-version check that gates the app behind an update screen — no backend required |

## Optional: `@riverpod` code generation

<details>
<summary>The default is hand-written providers. Expand only if you're deciding <b>at project start</b> to opt into code generation — never per-feature, or the codebase ends up mixed.</summary>

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

</details>

## Troubleshooting / gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `flutter run` exits 64 immediately | `lib/main.dart` is an unflavored guard, by design | Use `flutter run -t lib/main_dev.dart --dart-define-from-file=.env.dev` |
| `flutter build apk --flavor dev` fails: *"does not define any custom product flavors"* | No native Android flavors / iOS schemes exist in this repo | Drop `--flavor`, or scaffold flavors first (`flow flavor init` / `flow create --flavors ...`) |
| `riverpod_lint` findings never show up | `flutter analyze` does not load `analysis_server_plugin` plugins (only `dart analyze` does) | Run `dart analyze` too — CI runs both |
| Edited an `.arb`, the l10n drift test still fails | Only `flutter gen-l10n` ran; `L10n` forwarders are stale | Run `dart run tool/update_l10n.dart`, not `flutter gen-l10n` alone |
| Push notifications never arrive | Native Firebase/permission setup isn't in this repo (see above) | Add `google-services.json`/`GoogleService-Info.plist`, the Gradle plugin, `POST_NOTIFICATIONS`, and the iOS push entitlement |
| `dart pub global activate flow` installs the wrong thing | `flow` collides with an unrelated package on pub.dev | Install with `--source git https://github.com/loqmanali/flow.git` |

## License

[MIT](LICENSE) © 2026 loqmanali
