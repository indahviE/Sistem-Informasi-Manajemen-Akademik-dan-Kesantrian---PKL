import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';
import 'services/app_scope.dart';
import 'services/auth_state.dart';
import 'screens/gate_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isWeb = kIsWeb;

  late final ApiClient api;
  late final AuthState auth;
  api = ApiClient(
    baseUrl: () => ApiConfig.baseUrl,
    getAccessToken: () => auth.getAccessToken(),
    getRefreshToken: () => auth.getRefreshToken(),
    refreshTokens: (rt) => auth.refresh(rt),
    saveTokens: (at, rt) => auth.saveTokens(at, rt),
    clearTokens: () => auth.logout(),
  );
  auth = AuthState(api);
  await auth.init(isWeb: isWeb);

  runApp(App(auth: auth));
}

class App extends StatefulWidget {
  final AuthState auth;
  const App({super.key, required this.auth});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuth);
    if (widget.auth.isLoggedIn) widget.auth.refreshBranding();
  }

  void _onAuth() => setState(() {});

  @override
  void dispose() {
    widget.auth.removeListener(_onAuth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seed = widget.auth.brandingColor ?? Tw.primary;
    return AppScope(
      auth: widget.auth,
      child: MaterialApp(
        title: 'SIM Pesantren',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(seed),
        home: const GateScreen(),
      ),
    );
  }
}
