import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import 'santri_detail_screen.dart';
import 'santri_form_screen.dart';

/// Palet sama persis dengan `_WC` di dashboard_screen.dart
/// (Deep Emerald Forest + Antique Gold di atas kanvas ivory).
class _SC {
  _SC._();

  static const primary = Color(0xFF0F3A2E);
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.santri, query: {'search': q ?? '', 'perPage': '50'});
      if (!mounted) return;
      setState(() {
        _items = (res['items'] as List? ?? []);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _hapus(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _SC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Santri',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _SC.ink)),
        content: Text(
          'Hapus "${s['nama']}" (NIS ${s['nis']}) beserta semua datanya?',
          style: const TextStyle(fontSize: 13, color: _SC.inkSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _SC.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _SC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _SC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.santri}/${s['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Santri dihapus')));
      _load(q: _search.text);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _tambah() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SantriFormScreen()),
    );
    if (created == true) _load(q: _search.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Sama seperti dashboard: dibatasi 480 supaya di web tetap proporsional.
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Column(
                children: [
                  _searchBar(),
                  if (!_loading && _error == null) _countHeader(),
                  Expanded(child: _body()),
                ],
              ),
              // Posisi relatif ke kolom 480px, bukan ke layar, jadi di web
              // tombol tetap nempel di kanan-bawah konten.
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _tambah,
                  tooltip: 'Tambah Santri',
                  backgroundColor: _SC.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Santri Baru',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}), // supaya tombol clear muncul/hilang
        onSubmitted: (v) => _load(q: v),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13.5, color: _SC.ink),
        decoration: InputDecoration(
          hintText: 'Cari nama / NIS',
          hintStyle: const TextStyle(fontSize: 13.5, color: _SC.inkSecondary),
          prefixIcon: const Icon(Icons.search, size: 20, color: _SC.inkSecondary),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _SC.inkSecondary),
                  onPressed: () {
                    _search.clear();
                    _load();
                  },
                ),
          filled: true,
          fillColor: _SC.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: _SC.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: _SC.primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _countHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Data Santri',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _SC.ink)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _SC.sage, borderRadius: BorderRadius.circular(999)),
            child: Text('${_items.length} Terdaftar',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _SC.primary)),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, () => _load(q: _search.text));
    if (_items.isEmpty) return emptyView('Belum ada data santri.');
    return RefreshIndicator(
      color: _SC.primary,
      onRefresh: () => _load(q: _search.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final s = _items[i] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _santriCard(s),
          );
        },
      ),
    );
  }

  Widget _santriCard(Map<String, dynamic> s) {
    final nama = (s['nama'] as String?)?.trim() ?? '-';
    final nis = s['nis']?.toString() ?? '-';
    final kelas = (s['kelas'] as Map?)?['namaKelas']?.toString();
    final status = s['status'] is String ? (s['status'] as String) : null;
    final inisial = nama.isNotEmpty && nama != '-' ? nama[0].toUpperCase() : '?';

    return Material(
      color: _SC.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: s['id'] as String)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _SC.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _SC.sage, shape: BoxShape.circle),
                child: Text(inisial,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _SC.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _SC.ink)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('NIS $nis', style: const TextStyle(fontSize: 11.5, color: _SC.inkSecondary)),
                        if (kelas != null) _pill(kelas, _SC.mint, _SC.primary),
                        if (status != null) _statusPill(status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: _SC.errorText),
                tooltip: 'Hapus',
                onPressed: () => _hapus(s),
              ),
              const Icon(Icons.chevron_right, size: 18, color: _SC.inkSecondary),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _statusPill(String status) {
    final up = status.toUpperCase();
    if (up == 'AKTIF') return _pill('Aktif', _SC.successBg, _SC.successText);
    if (up == 'NONAKTIF' || up == 'KELUAR' || up == 'LULUS') {
      return _pill(status, _SC.errorBg, _SC.errorText);
    }
    return _pill(status, _SC.pendingBg, _SC.pendingText);
  }
}