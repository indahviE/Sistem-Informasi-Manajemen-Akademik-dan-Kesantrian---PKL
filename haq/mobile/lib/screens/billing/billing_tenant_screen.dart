import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

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
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      SectionCard(
                        title: 'Paket Aktif',
                        children: _subs.isEmpty
                            ? const [
                                Text('Belum ada langganan.',
                                    style: TextStyle(color: Tw.gray500)),
                              ]
                            : [
                                for (final s in _subs)
                                  _subCard(s as Map<String, dynamic>),
                              ],
                      ),
                      SectionCard(
                        title: 'Tagihan (${_invs.length})',
                        children: _invs.isEmpty
                            ? const [
                                Text('Belum ada tagihan.',
                                    style: TextStyle(color: Tw.gray500)),
                              ]
                            : [
                                for (final i in _invs)
                                  _invCard(i as Map<String, dynamic>),
                              ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _subCard(Map<String, dynamic> s) {
    final p = s['paket'] as Map<String, dynamic>? ?? {};
    final status = s['status'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Tw.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.workspace_premium, color: Tw.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nama'] as String? ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Tw.gray900)),
                Text(
                  'Mulai ${(s['tanggalMulai'] as String).split('T').first} '
                  '• Limit ${p['limitSantri']} santri',
                  style: const TextStyle(fontSize: 12, color: Tw.gray500),
                ),
              ],
            ),
          ),
          twBadge(context, status,
              color: status == 'AKTIF' ? Tw.teal : status == 'EXPIRED' ? Tw.amber : Tw.red,
              soft: status == 'AKTIF' ? Tw.tealSoft : status == 'EXPIRED' ? Tw.amberSoft : Tw.redSoft),
        ],
      ),
    );
  }

  Widget _invCard(Map<String, dynamic> i) {
    final status = i['status'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Tw.skySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt, color: Tw.sky),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['noInvoice'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Tw.gray900)),
                Text(
                  '${_rupiah((i['jumlah'] as num))} • '
                  'Jatuh tempo ${(i['tanggalJatuhTempo'] as String? ?? '').split('T').first}',
                  style: const TextStyle(fontSize: 12, color: Tw.gray500),
                ),
              ],
            ),
          ),
          twBadge(context, status,
              color: status == 'LUNAS' ? Tw.teal : status == 'BATAL' ? Tw.red : Tw.amber,
              soft: status == 'LUNAS' ? Tw.tealSoft : status == 'BATAL' ? Tw.redSoft : Tw.amberSoft),
        ],
      ),
    );
  }
}
