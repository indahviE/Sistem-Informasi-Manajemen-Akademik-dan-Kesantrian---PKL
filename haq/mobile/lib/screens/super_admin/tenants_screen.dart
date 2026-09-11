import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
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
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.tenants);
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

  Future<void> _action(Map<String, dynamic> t, String action) async {
    try {
      final api = AppScope.of(context).api;
      await api.post(action == 'approve' ? ApiUrl.tenantApprove : ApiUrl.tenantSuspend,
          {'tenantId': t['id']});
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada tenant terdaftar.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final t = _items[i] as Map<String, dynamic>;
                          final status = t['status'] as String;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(t['namaPondok'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Chip(label: Text(status), visualDensity: VisualDensity.compact),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('Kode: ${t['kodeTenant']}', style: Theme.of(context).textTheme.bodySmall),
                                  Text('User: ${t['jumlahUser']} • Santri: ${t['jumlahSantri']} • Kelas: ${t['jumlahKelas']}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  if (status == 'PENDING') ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.tonal(
                                        onPressed: () => _action(t, 'approve'),
                                        child: const Text('Setujui & Aktifkan'),
                                      ),
                                    ),
                                  ],
                                  if (status == 'AKTIF') ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _action(t, 'suspend'),
                                        child: const Text('Suspend', style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}