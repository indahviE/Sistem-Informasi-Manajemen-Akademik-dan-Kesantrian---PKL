import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// ============================================================================
// Token warna lokal (disamakan dengan pengaturan_admin_screen.dart)
// ============================================================================

class _BC {
  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFF9D77E);
  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);

  static const greenFg = Color(0xFF166534);
  static const greenBg = Color(0xFFDCFCE7);
  static const amberFg = Color(0xFF92400E);
  static const amberBg = Color(0xFFFEF3C7);
  static const redFg = Color(0xFF991B1B);
  static const redBg = Color(0xFFFEE2E2);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

// ============================================================================
// Screen
// ============================================================================

class BillingTenantScreen extends StatefulWidget {
  const BillingTenantScreen({super.key});

  @override
  State<BillingTenantScreen> createState() => _BillingTenantScreenState();
}

class _BillingTenantScreenState extends State<BillingTenantScreen> {
  List<dynamic> _subs = [];
  List<dynamic> _invs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final subs = await api.get(ApiUrl.subscriptions);
      final invs = await api.get(ApiUrl.invoices);
      if (!mounted) return;
      setState(() {
        _subs = (subs as List);
        _invs = (invs as List);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _rupiah(num v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _tgl(dynamic iso) {
    if (iso is! String || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso.split('T').first;
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  }

  int get _belumLunas => _invs.where((i) {
        final st = (i as Map<String, dynamic>)['status'];
        return st != 'LUNAS' && st != 'BATAL';
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BC.background,
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: RefreshIndicator(
                      color: _BC.primary,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        children: [
                          _header(),
                          const SizedBox(height: 16),
                          _sectionTitle(Icons.workspace_premium_outlined, 'Paket Aktif',
                              subtitle: 'Langganan pondok kamu saat ini'),
                          const SizedBox(height: 10),
                          if (_subs.isEmpty)
                            const _EmptyCard(
                              icon: Icons.workspace_premium_outlined,
                              text: 'Belum ada langganan.',
                            )
                          else
                            for (final s in _subs) ...[
                              _subCard(s as Map<String, dynamic>),
                              const SizedBox(height: 12),
                            ],
                          const SizedBox(height: 6),
                          _sectionTitle(Icons.receipt_long_outlined, 'Tagihan',
                              subtitle: 'Riwayat dan status pembayaran',
                              trailing: _countPill('${_invs.length}')),
                          const SizedBox(height: 10),
                          if (_invs.isEmpty)
                            const _EmptyCard(
                              icon: Icons.receipt_long_outlined,
                              text: 'Belum ada tagihan.',
                            )
                          else
                            for (final i in _invs) ...[
                              _invCard(i as Map<String, dynamic>),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------
  // Header + ringkasan
  // ---------------------------------------------------------------------

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tagihan', style: _t(21, FontWeight.w800, _BC.primary, height: 1.15)),
              const SizedBox(height: 2),
              Text('Paket langganan & riwayat tagihan',
                  style: _t(12, FontWeight.w500, _BC.inkSecondary)),
            ],
          ),
        ),
        _miniStat('Belum Lunas', '$_belumLunas', warn: _belumLunas > 0),
      ],
    );
  }

  Widget _miniStat(String label, String value, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: warn ? _BC.amberBg : _BC.sage,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: _t(14, FontWeight.w800, warn ? _BC.amberFg : _BC.primary)),
          const SizedBox(width: 6),
          Text(label, style: _t(11, FontWeight.w700, warn ? _BC.amberFg : _BC.primary)),
        ],
      ),
    );
  }

  Widget _countPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _BC.surfaceDim,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _BC.line),
      ),
      child: Text(text, style: _t(11, FontWeight.w800, _BC.primary)),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {String? subtitle, Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: _BC.sage, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: _BC.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _t(15.5, FontWeight.w800, _BC.primary, height: 1.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: _t(11.5, FontWeight.w500, _BC.inkSecondary)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Kartu paket
  // ---------------------------------------------------------------------

  Widget _subCard(Map<String, dynamic> s) {
    final p = s['paket'] as Map<String, dynamic>? ?? {};
    final status = (s['status'] ?? '-') as String;
    final aktif = status == 'AKTIF';
    final expired = status == 'EXPIRED';

    final statusBg = aktif ? _BC.mint : (expired ? _BC.amberBg : _BC.redBg);
    final statusFg = aktif ? _BC.primary : (expired ? _BC.amberFg : _BC.redFg);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_BC.primary, _BC.primarySoft],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _BC.primary.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -36, top: -36, child: _ring(150)),
          Positioned(right: 14, top: 14, child: _ring(72)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                        border: Border.all(color: _BC.gold.withOpacity(0.55)),
                      ),
                      child: const Icon(Icons.workspace_premium_outlined, size: 23, color: _BC.gold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(status, style: _t(10.5, FontWeight.w800, statusFg)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  (p['nama'] as String?) ?? '-',
                  style: _t(23, FontWeight.w800, Colors.white, height: 1.15),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _subInfo(Icons.event_outlined, 'Mulai', _tgl(s['tanggalMulai'])),
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _subInfo(
                          Icons.groups_outlined,
                          'Limit',
                          '${p['limitSantri'] ?? '-'} santri',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _t(10.5, FontWeight.w600, Colors.white60)),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(13, FontWeight.w800, Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu tagihan
  // ---------------------------------------------------------------------

  Widget _invCard(Map<String, dynamic> i) {
    final status = (i['status'] ?? '-') as String;
    final lunas = status == 'LUNAS';
    final batal = status == 'BATAL';

    final fg = lunas ? _BC.greenFg : (batal ? _BC.redFg : _BC.amberFg);
    final bg = lunas ? _BC.greenBg : (batal ? _BC.redBg : _BC.amberBg);
    final icon = lunas
        ? Icons.check_circle_outline_rounded
        : (batal ? Icons.cancel_outlined : Icons.schedule_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _BC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _BC.line.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (i['noInvoice'] ?? '-') as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w800, _BC.primary),
                ),
                const SizedBox(height: 3),
                Text(
                  _rupiah((i['jumlah'] as num)),
                  style: _t(16, FontWeight.w800, _BC.primary, height: 1.1),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 12, color: _BC.inkSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Jatuh tempo ${_tgl(i['tanggalJatuhTempo'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(11.5, FontWeight.w500, _BC.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
            child: Text(status, style: _t(10.5, FontWeight.w800, fg)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Empty state
// ============================================================================

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: _BC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _BC.line.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _BC.surfaceDim, shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: _BC.inkSecondary),
          ),
          const SizedBox(height: 10),
          Text(text, style: _t(13, FontWeight.w600, _BC.inkSecondary)),
        ],
      ),
    );
  }
}