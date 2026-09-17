import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

// Design Colors
const Color _primaryColor = Color(0xFF0F3A2E);
const Color _surfaceColor = Color(0xFFFAF9F5);
const Color _borderColor = Color(0xFFEAE6DC);
const Color _gray600 = Color(0xFF697278);

class BillingAdminScreen extends StatefulWidget {
  const BillingAdminScreen({super.key});

  @override
  State<BillingAdminScreen> createState() => _BillingAdminScreenState();
}

class _BillingAdminScreenState extends State<BillingAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _surfaceColor,
        appBar: AppBar(
          title: const Text('Billing & Paket'),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Paket'),
              Tab(text: 'Langganan'),
              Tab(text: 'Invoice'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: TabBarView(
              children: [
                _PaketTab(),
                _SubscriptionTab(),
                _InvoiceTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaketTab extends StatefulWidget {
  @override
  State<_PaketTab> createState() => _PaketTabState();
}

class _PaketTabState extends State<_PaketTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  bool _initialized = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _initialized = true;
    _load();
  }
}

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final res = await AppScope.of(context).api.get(ApiUrl.paket);
    if (!mounted) return;
    setState(() {
      _items = (res as List);
      _loading = false;
    });
  } on ApiException catch (e) {
    if (mounted) setState(() {
      _error = e.message;
      _loading = false;
    });
  } catch (e, st) {
    debugPrint('Load paket error: $e\n$st');
    if (mounted) setState(() {
      _error = 'Terjadi kesalahan: $e';
      _loading = false;
    });
  }
}

  String _rupiah(num v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  Future<void> _add() async {
    final nama = TextEditingController();
    final harga = TextEditingController();
    final limit = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Paket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Paket')),
            const SizedBox(height: 8),
            TextField(controller: harga, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga per tahun (Rp)')),
            const SizedBox(height: 8),
            TextField(controller: limit, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Limit Santri')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.paket, {
        'nama': nama.text,
        'harga': int.parse(harga.text),
        'limitSantri': int.parse(limit.text),
      });
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hapus(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Paket'),
        content: Text('Hapus paket "${p['nama']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tw.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.paket}/${p['id']}');
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: _add,
        tooltip: 'Tambah Paket',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada paket.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            Text(
                              'Katalog Paket',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Struktur tier paket untuk masing-masing platform',
                              style: TextStyle(
                                fontSize: 13,
                                color: _gray600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Paket Cards
                            ..._items.map((item) {
                              final p = item as Map<String, dynamic>;
                              final nama = p['nama'] as String? ?? '';
                              final harga = p['harga'] as num? ?? 0;
                              final limit = p['limitSantri'] as num? ?? 0;
                              
                              return PaketCard(
                                nama: nama,
                                harga: harga,
                                limit: limit,
                                rupiah: _rupiah(harga),
                                onDelete: () => _hapus(p),
                              );
                            }).toList(),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class PaketCard extends StatefulWidget {
  final String nama;
  final num harga;
  final num limit;
  final String rupiah;
  final VoidCallback onDelete;

  const PaketCard({
    required this.nama,
    required this.harga,
    required this.limit,
    required this.rupiah,
    required this.onDelete,
  });

  @override
  State<PaketCard> createState() => _PaketCardState();
}

class _PaketCardState extends State<PaketCard> {
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limit ${widget.limit.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} santri',
                      style: TextStyle(
                        fontSize: 12,
                        color: _gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.rupiah,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  Text(
                    '/tahun',
                    style: TextStyle(
                      fontSize: 11,
                      color: _gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Features List
          Text(
            'Fitur Paket',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Semua Fitur Paket ${widget.nama}\n• Unlimited Access\n• Priority Support',
            style: TextStyle(
              fontSize: 12,
              color: _gray600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Tw.red,
                    side: const BorderSide(color: Tw.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Hapus Paket'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit Paket'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'Paket ${_isActive ? 'Aktif' : 'Nonaktif'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isActive ? const Color(0xFF1B5E20) : Tw.red,
                  ),
                ),
              ),
              Switch(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: _primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Subscription Tab
class _SubscriptionTab extends StatefulWidget {
  @override
  State<_SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<_SubscriptionTab> {
  List<dynamic> _items = [];
  List<dynamic> _pakets = [];
  List<dynamic> _tenants = [];
  bool _loading = true;
  String? _error;

  bool _initialized = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _initialized = true;
    _load();
  }
}

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final api = AppScope.of(context).api;
    final subs = await api.get(ApiUrl.subscriptions);
    final pakets = await api.get(ApiUrl.paket);
    final tenants = await api.get(ApiUrl.tenants);
    if (!mounted) return;
    setState(() {
      _items = (subs as List);
      _pakets = (pakets as List);
      _tenants = (tenants as List);
      _loading = false;
    });
  } on ApiException catch (e) {
    if (mounted) setState(() {
      _error = e.message;
      _loading = false;
    });
  } catch (e, st) {
    debugPrint('Load subscription error: $e\n$st');
    if (mounted) setState(() {
      _error = 'Terjadi kesalahan: $e';
      _loading = false;
    });
  }
}

  Future<void> _assign() async {
    String? tenantId;
    String? paketId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Assign Paket ke Pondok'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tenantId,
                decoration: const InputDecoration(labelText: 'Pilih Pondok'),
                items: [
                  for (final t in _tenants)
                    DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['namaPondok']} (${t['kodeTenant']})'),
                    ),
                ],
                onChanged: (v) => setSt(() => tenantId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: paketId,
                decoration: const InputDecoration(labelText: 'Pilih Paket'),
                items: [
                  for (final p in _pakets)
                    DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['nama'] as String),
                    ),
                ],
                onChanged: (v) => setSt(() => paketId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: tenantId == null || paketId == null ? null : () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context)
          .api
          .post(ApiUrl.subscriptions, {'tenantId': tenantId, 'paketId': paketId});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Langganan dibuat (1 tahun).')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: _assign,
        tooltip: 'Assign Paket',
        child: const Icon(Icons.assignment_ind),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada langganan.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          children: [
                            ..._items.map((item) {
                              final s = item as Map<String, dynamic>;
                              final t = s['tenant'] as Map<String, dynamic>? ?? {};
                              final p = s['paket'] as Map<String, dynamic>? ?? {};
                              final status = s['status'] as String;
                              final startDate = (s['tanggalMulai'] as String?)?.split('T').first ?? '-';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.workspace_premium, color: _primaryColor, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t['namaPondok'] as String? ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${p['nama'] ?? '-'} • mulai $startDate',
                                            style: TextStyle(fontSize: 12, color: _gray600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'AKTIF'
                                            ? const Color(0xFFE8F5E9)
                                            : status == 'EXPIRED'
                                                ? const Color(0xFFFFF8E1)
                                                : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: status == 'AKTIF'
                                              ? const Color(0xFF1B5E20)
                                              : status == 'EXPIRED'
                                                  ? const Color(0xFFB78103)
                                                  : const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

// Invoice Tab
class _InvoiceTab extends StatefulWidget {
  @override
  State<_InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends State<_InvoiceTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  bool _initialized = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _initialized = true;
    _load();
  }
}

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });
  try {
    final api = AppScope.of(context).api;
    final invoices = await api.get(ApiUrl.invoices);
    if (!mounted) return;
    setState(() {
      _items = (invoices as List);
      _loading = false;
    });
  } on ApiException catch (e) {
    if (mounted) setState(() {
      _error = e.message;
      _loading = false;
    });
  } catch (e, st) {
    debugPrint('Load invoice error: $e\n$st');
    if (mounted) setState(() {
      _error = 'Terjadi kesalahan: $e';
      _loading = false;
    });
  }
}

  String _rupiah(num v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada invoice.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          children: [
                            ..._items.map((item) {
                              final inv = item as Map<String, dynamic>;
                              final tenant = inv['tenant'] as Map<String, dynamic>? ?? {};
                              final amount = inv['nominal'] as num? ?? 0;
                              final status = inv['status'] as String? ?? 'PENDING';
                              final dueDate = (inv['tanggalJatuhTempo'] as String?)?.split('T').first ?? '-';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long, color: _primaryColor, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tenant['namaPondok'] as String? ?? 'Invoice',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                'Jatuh tempo: $dueDate',
                                                style: TextStyle(fontSize: 12, color: _gray600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'LUNAS'
                                                ? const Color(0xFFE8F5E9)
                                                : const Color(0xFFFFF8E1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: status == 'LUNAS'
                                                  ? const Color(0xFF1B5E20)
                                                  : const Color(0xFFB78103),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _rupiah(amount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }
}