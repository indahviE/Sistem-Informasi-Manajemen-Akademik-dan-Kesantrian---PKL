import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;

class PelanggaranScreen extends StatefulWidget {
  const PelanggaranScreen({super.key});

  @override
  State<PelanggaranScreen> createState() => _PelanggaranScreenState();
}

class _PelanggaranScreenState extends State<PelanggaranScreen> {
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _santris = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      // Catatan: filter "hanya anak sendiri" untuk Wali sudah ditangani
      // di backend (KesantrianService.findAllPelanggaran), jadi di sini
      // tidak perlu filter tambahan di sisi klien.
      final res = await api.get(ApiUrl.pelanggaran);
      if (!mounted) return;
      setState(() {
        _items = (res as List);
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

  Future<void> _add() async {
    if (_santris.isEmpty) {
      try {
        final api = AppScope.of(context).api;
        final s = await api.get(ApiUrl.santri, query: {'perPage': '100'});
        if (mounted) setState(() => _santris = ((s['items'] as List? ?? []) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    final jenis = TextEditingController();
    final poin = TextEditingController();
    final tindak = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.gavel_rounded,
          title: 'Catat Pelanggaran',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            _PDialogField(controller: jenis, label: 'Jenis Pelanggaran'),
            _PDialogField(controller: poin, label: 'Poin', keyboardType: TextInputType.number),
            _PDialogField(controller: tindak, label: 'Tindak Lanjut'),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: PColors.inkSecondary),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: PColors.primary,
                foregroundColor: PColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.pelanggaran, {
        'santriId': santriId,
        'jenisPelanggaran': jenis.text.trim(),
        'poin': int.tryParse(poin.text) ?? 0,
        'tindakLanjut': tindak.text.trim().isEmpty ? null : tindak.text.trim(),
        'tanggal': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PColors.primary,
          content: const Text('Pelanggaran dicatat. Wali mendapat notifikasi.'),
        ),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.errorText, content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWali = AppScope.of(context).user?.isWali == true;
    return Scaffold(
      backgroundColor: PColors.background,
      floatingActionButton: isWali
          ? null
          : FloatingActionButton(
              onPressed: _add,
              tooltip: 'Catat Pelanggaran',
              backgroundColor: PColors.primary,
              foregroundColor: PColors.gold,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : _items.isEmpty
                              ? emptyView('Belum ada pelanggaran.')
                              : RefreshIndicator(
                                  color: PColors.primary,
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                    itemCount: _items.length,
                                    itemBuilder: (ctx, i) {
                                      final p = _items[i] as Map<String, dynamic>;
                                      final santri = (p['santri'] as Map?) ?? {};
                                      return _PelanggaranTile(
                                        jenis: p['jenisPelanggaran'] as String,
                                        nama: santri['nama']?.toString() ?? '',
                                        tanggal: (p['tanggal'] as String).substring(0, 10),
                                        poin: (p['poin'] as num).toInt(),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Themed building blocks (matches SignupScreen's design system)
// ===========================================================================

class _PelanggaranTile extends StatelessWidget {
  const _PelanggaranTile({
    required this.jenis,
    required this.nama,
    required this.tanggal,
    required this.poin,
  });

  final String jenis;
  final String nama;
  final String tanggal;
  final int poin;

  Color get _poinColor {
    if (poin >= 50) return PColors.errorText;
    if (poin >= 20) return PColors.pendingText;
    return PColors.infoText;
  }

  Color get _poinBg {
    if (poin >= 50) return PColors.errorBg;
    if (poin >= 20) return PColors.pendingBg;
    return PColors.infoBg;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F3A2E),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: PColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel, color: PColors.errorText, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jenis, style: PText.labelLg.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text('$nama • $tanggal', style: PText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _poinBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              '$poin poin',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _poinColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PDialogField extends StatelessWidget {
  const _PDialogField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: PText.bodyMd.copyWith(color: PColors.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: PText.bodyMd,
          filled: true,
          fillColor: PColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}