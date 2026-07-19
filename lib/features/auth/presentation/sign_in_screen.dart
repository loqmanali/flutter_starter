import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/error/error_view.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_starter/features/auth/presentation/auth_providers.dart';
import 'package:widget_kit/widget_kit.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    unawaited(
      ref
          .read(signInControllerProvider.notifier)
          .submit(email: _email.text.trim(), password: _password.text),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? L10n.fieldRequired : null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);

    ref.listen<AsyncValue<void>>(signInControllerProvider, (_, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorView.messageFor(error))));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Constraint-based, not screenutil: the form stops growing once
            // the window is wider than a phone.
            constraints: const BoxConstraints(
              maxWidth: WidgetKitBreakpoints.compact,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WidgetKitTokens.spaceLg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      L10n.appTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: WidgetKitTokens.spaceXl),
                    TextFormField(
                      key: const Key('sign_in_email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: L10n.email),
                      validator: _required,
                    ),
                    const SizedBox(height: WidgetKitTokens.spaceMd),
                    TextFormField(
                      key: const Key('sign_in_password'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: L10n.password),
                      validator: _required,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: WidgetKitTokens.spaceLg),
                    FilledButton(
                      key: const Key('sign_in_submit'),
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(L10n.signIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
