import 'package:flutter/material.dart';
import 'package:flutter_starter/core/localization/localization.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.home)),
      body: Center(child: Text(L10n.appTitle)),
    );
  }
}
