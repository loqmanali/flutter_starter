import 'package:flutter/material.dart';
import 'package:flutter_starter/core/config/env.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Booted: ${Env.flavor}'))),
    );
  }
}
