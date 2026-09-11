import 'package:flutter/widgets.dart';
import '../services/auth_state.dart';

class AppScope extends InheritedNotifier<AuthState> {
  const AppScope({super.key, required AuthState auth, required super.child})
      : super(notifier: auth);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree');
    return scope!.notifier!;
  }

  static AuthState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
}
