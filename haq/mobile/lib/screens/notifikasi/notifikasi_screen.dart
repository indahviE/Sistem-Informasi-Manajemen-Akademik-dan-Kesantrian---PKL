import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.notifikasi);
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

  Future<void> _markRead(String id) async {
    try {
      await AppScope.of(context).api.patch('${ApiUrl.notifikasi}/$id/read', {});
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Tidak ada notifikasi.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final n = _items[i] as Map<String, dynamic>;
                          final isRead = n['statusBaca'] == true;
                          return Card(
                            child: ListTile(
                              leading: Icon(_iconFor(n['jenis'] as String), color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary),
                              title: Text(n['pesan'] as String, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                              subtitle: Text('${(n['tanggal'] as String).substring(0, 16).replaceAll('T', ' ')}'),
                              trailing: isRead ? null : const Icon(Icons.circle, size: 10, color: Colors.blue),
                              onTap: () => _markRead(n['id'] as String),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _iconFor(String jenis) {
    switch (jenis) {
      case 'PELANGGARAN': return Icons.gavel;
      case 'KESEHATAN': return Icons.medical_services;
      case 'PERIZINAN': return Icons.exit_to_app;
      case 'NILAI': return Icons.grade;
      case 'ABSENSI': return Icons.checklist;
      case 'DARURAT': return Icons.emergency;
      case 'TENANT_BARU': return Icons.domain;
      case 'TAGIHAN': return Icons.receipt_long;
      case 'KEAMANAN': return Icons.security;
      case 'LAPORAN': return Icons.insights;
      default: return Icons.notifications;
    }
  }
}