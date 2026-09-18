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

  // PERBAIKAN: default-nya, kalau ada widget yang lempar exception saat
  // build, Flutter Web (terutama build release/profile) kadang cuma
  // menampilkan area kosong tanpa keterangan apa pun — persis gejala
  // "halaman detail tenant blank, cuma bottom bar yang tampil". Override
  // ErrorWidget.builder supaya area yang gagal build itu selalu menampilkan
  // kotak merah kecil berisi pesan errornya, di semua mode build.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    return Container(
      color: const Color(0xFFFEE2E2),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Terjadi error saat menampilkan bagian ini:\n${details.exceptionAsString()}',
        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  };

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