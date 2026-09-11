import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import 'landing_screen.dart';
import 'shell_screen.dart';

class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context);
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isLoggedIn ? const ShellScreen() : const LandingScreen();
  }
}
