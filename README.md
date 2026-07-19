# Flutter Starter

Opinionated Riverpod starter kit wiring
[`flutter_kits`](https://github.com/loqmanali/flutter_kits) into a running
app. Wiring lives here; capability lives in the kits.

## Quick start

```bash
gh repo create my_app --template loqmanali/flutter_starter --private --clone
cd my_app
dart run tool/rename.dart --name my_app --org com.acme --display "My App"
cp .env.example .env          # then edit BASE_URL
flow flavor run dev           # install the flow CLI yourself; this repo doesn't vendor it
```

`tool/rename.dart` rewrites every `package:flutter_starter` reference and the
pubspec `name:` field, then renames the Android/iOS bundle id via
`change_app_package_name` (a dev-only dependency). If that step fails — e.g.
before your first `flutter pub get` — it prints the exact files to edit by
hand instead of failing silently.

## The boundary rule

**The template owns wiring. The kits own capability.** If code could serve two
apps, it belongs in `flutter_kits`, not here. Kits are pinned to one git tag
(`v1.1.4` as of this writing) via a `git:`/`path:` dependency in
`pubspec.yaml`; bump it deliberately, never float the ref. Bumping a kit can
raise its own transitive requirements — e.g. `force_update_gate@v1.1.4` needs
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
| Flavors | `flow flavor run\|build <flavor>`, configured by `.flow_flavor.json`. This repo vendors no build scripts. `.env` is git-ignored and never a Flutter asset — config is compiled in via `--dart-define-from-file`, not bundled where it could be unzipped out of a release APK. |

## Adding a feature

```
lib/features/orders/
├── data/
│   ├── order.dart              # model, hand-written fromJson
│   └── order_repository.dart   # HTTP + defensive parsing; throws Failure
└── presentation/
    ├── order_providers.dart    # repository provider + notifiers
    ├── order_routes.dart       # this feature's List<RouteBase>
    ├── orders_screen.dart
    └── widgets/
```

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
