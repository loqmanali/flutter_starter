import 'package:api_kit/api_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:widget_kit/widget_kit.dart';

/// The single place an error becomes UI.
///
/// Takes the raw error because `AsyncValue.error` is typed `Object`; anything
/// that is not a [Failure] is reported with the generic message rather than
/// leaking an exception's `toString()` to users.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is Failure
        ? (error as Failure).message
        : L10n.errorGeneric;

    return Padding(
      padding: const EdgeInsets.all(WidgetKitTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: WidgetKitTokens.spaceMd),
            FilledButton(onPressed: onRetry, child: Text(L10n.retry)),
          ],
        ],
      ),
    );
  }
}
