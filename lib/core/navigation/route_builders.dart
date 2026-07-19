import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builders that keep `state.extra` and path params type-safe without
/// codegen. A stale deep link or a hot reload that drops `extra` degrades to
/// [NotFoundScreen] instead of crashing on a bad cast.
abstract final class RouteBuilders {
  static GoRouterWidgetBuilder withExtra<T>(Widget Function(T extra) build) {
    return (context, state) {
      final extra = state.extra;
      return extra is T ? build(extra) : const NotFoundScreen();
    };
  }

  static GoRouterWidgetBuilder withIntParam(
    String name,
    Widget Function(int value) build,
  ) {
    return (context, state) {
      final raw = state.pathParameters[name];
      final value = raw == null ? null : int.tryParse(raw);
      return value == null ? const NotFoundScreen() : build(value);
    };
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404')));
  }
}
