import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
      final res = await api.get(ApiUrl.users);
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

  Future<void> _add() async {
    final nama = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    String role = 'USTADZ';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama')),
              const SizedBox(height: 8),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 8),
              TwSelect(
                value: role,
                label: 'Role',
                options: const [
                  DropdownOption('ADMIN', 'Admin'),
                  DropdownOption('USTADZ', 'Ustadz / Guru'),
                  DropdownOption('MUSYRIF', 'Musyrif / Pembina'),
                  DropdownOption('PIMPINAN', 'Pimpinan / Mudir'),
                  DropdownOption('WALI_SANTRI', 'Wali Santri'),
                ],
                onChanged: (v) => setLocal(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.users, {
        'nama': nama.text.trim(),
        'email': email.text.trim(),
        'password': pass.text,
        'role': role,
      });
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
        tooltip: 'Tambah User',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : _items.isEmpty
                  ? emptyView('Belum ada user.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final u = _items[i] as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(u['nama'] as String),
                              subtitle: Text('${u['email']} • ${u['role']}'),
                              trailing: Icon(u['status'] == 'AKTIF' ? Icons.check_circle : Icons.pause_circle,
                                  color: u['status'] == 'AKTIF' ? Colors.green : Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}