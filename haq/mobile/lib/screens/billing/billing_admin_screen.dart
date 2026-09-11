import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

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
        appBar: AppBar(
          title: const Text('Billing & Paket'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Paket'),
              Tab(text: 'Langganan'),
              Tab(text: 'Invoice'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PaketTab(),
            _SubscriptionTab(),
            _InvoiceTab(),
          ],
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.paket, {
        'nama': nama.text.trim(),
        'harga': double.tryParse(harga.text.trim()) ?? 0,
        'limitSantri': int.tryParse(limit.text.trim()) ?? 1,
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
      floatingActionButton: FloatingActionButton(
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
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i] as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.card_membership, color: Tw.primary),
                              title: Text(p['nama'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${_rupiah((p['harga'] as num))}/tahun • limit ${p['limitSantri']} santri'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Tw.red),
                                onPressed: () => _hapus(p),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

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
              TwSelect(
                value: tenantId,
                label: 'Pilih Pondok',
                options: [
                  for (final t in _tenants)
                    DropdownOption(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                ],
                onChanged: (v) => setSt(() => tenantId = v),
              ),
              const SizedBox(height: 10),
              TwSelect(
                value: paketId,
                label: 'Pilih Paket',
                options: [
                  for (final p in _pakets) DropdownOption(p['id'] as String, p['nama'] as String),
                ],
                onChanged: (v) => setSt(() => paketId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: tenantId == null || paketId == null
                  ? null
                  : () => Navigator.pop(context, true),
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
      floatingActionButton: FloatingActionButton(
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
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final s = _items[i] as Map<String, dynamic>;
                          final t = s['tenant'] as Map<String, dynamic>? ?? {};
                          final p = s['paket'] as Map<String, dynamic>? ?? {};
                          final status = s['status'] as String;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.workspace_premium, color: Tw.primary),
                              title: Text('${t['namaPondok'] ?? '-'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${p['nama'] ?? '-'} • mulai ${(s['tanggalMulai'] as String).split('T').first}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: twBadge(context, status,
                                  color: status == 'AKTIF' ? Tw.teal : status == 'EXPIRED' ? Tw.amber : Tw.red,
                                  soft: status == 'AKTIF' ? Tw.tealSoft : status == 'EXPIRED' ? Tw.amberSoft : Tw.redSoft),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _InvoiceTab extends StatefulWidget {
  @override
  State<_InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends State<_InvoiceTab> {
  List<dynamic> _items = [];
  List<dynamic> _tenants = [];
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
      final invs = await api.get(ApiUrl.invoices);
      final tenants = await api.get(ApiUrl.tenants);
      if (!mounted) return;
      setState(() {
        _items = (invs as List);
        _tenants = (tenants as List);
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

  Future<void> _buat() async {
    String? tenantId;
    final jumlah = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Buat Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TwSelect(
                value: tenantId,
                label: 'Pilih Pondok',
                options: [
                  for (final t in _tenants)
                    DropdownOption(t['id'] as String, '${t['namaPondok']} (${t['kodeTenant']})'),
                ],
                onChanged: (v) => setSt(() => tenantId = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: jumlah, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: tenantId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.invoices, {
        'tenantId': tenantId,
        'jumlah': double.tryParse(jumlah.text.trim()) ?? 0,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invoice dibuat.')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _tandaiLunas(Map<String, dynamic> inv) async {
    try {
      await AppScope.of(context)
          .api
          .patch('${ApiUrl.invoices}/${inv['id']}', {'status': 'LUNAS'});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invoice ditandai LUNAS.')));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _buat,
        tooltip: 'Buat Invoice',
        child: const Icon(Icons.receipt_long),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada invoice.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final inv = _items[i] as Map<String, dynamic>;
                          final t = inv['tenant'] as Map<String, dynamic>? ?? {};
                          final status = inv['status'] as String;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt, color: Tw.sky),
                              title: Text(inv['noInvoice'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${t['namaPondok'] ?? '-'} • ${_rupiah((inv['jumlah'] as num))}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: status == 'LUNAS'
                                  ? twBadge(context, 'LUNAS', color: Tw.teal, soft: Tw.tealSoft)
                                  : TextButton(
                                      onPressed: () => _tandaiLunas(inv),
                                      child: const Text('Tandai Lunas'),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
