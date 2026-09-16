import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;

class PerizinanScreen extends StatefulWidget {
  const PerizinanScreen({super.key});

  @override
  State<PerizinanScreen> createState() => _PerizinanScreenState();
}

class _PerizinanScreenState extends State<PerizinanScreen> {
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
      // di backend (KesantrianService.findAllPerizinan), jadi di sini
      // tidak perlu filter tambahan di sisi klien.
      final res = await api.get(ApiUrl.perizinan);
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
    final alasan = TextEditingController();
    String? santriId = _santris.isEmpty ? null : _santris.first['id'] as String;
    String jenis = 'KELUAR';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => TwFormDialog(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Ajukan Perizinan',
          fields: [
            TwSelect(
              value: santriId,
              label: 'Santri',
              options: [for (final s in _santris) DropdownOption(s['id'] as String, s['nama'] as String)],
              onChanged: (v) => setLocal(() => santriId = v),
            ),
            TwSelect(
              value: jenis,
              label: 'Jenis',
              options: const [
                DropdownOption('KELUAR', 'Izin Keluar'),
                DropdownOption('PULANG', 'Pulang'),
              ],
              onChanged: (v) => setLocal(() => jenis = v!),
            ),
            _PDialogField(controller: alasan, label: 'Alasan'),
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
              child: const Text('Ajukan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.post(ApiUrl.perizinan, {
        'santriId': santriId,
        'jenis': jenis,
        'alasan': alasan.text.trim(),
        'tanggalKeluar': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.primary, content: const Text('Perizinan diajukan.')),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: PColors.errorText, content: Text(e.message)),
      );
    }
  }

  Future<void> _action(Map<String, dynamic> p, String status) async {
    try {
      final api = AppScope.of(context).api;
      final now = DateTime.now();
      await api.patch('${ApiUrl.perizinan}/${p['id']}', {
        'statusApproval': status,
        if (status == 'KEMBALI' || status == 'TELAT')
          'tanggalKembali': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      _load();
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
              tooltip: 'Ajukan Izin',
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
                              ? emptyView('Belum ada perizinan.')
                              : RefreshIndicator(
                                  color: PColors.primary,
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                    itemCount: _items.length,
                                    itemBuilder: (ctx, i) {
                                      final p = _items[i] as Map<String, dynamic>;
                                      final santri = (p['santri'] as Map?) ?? {};
                                      final status = p['statusApproval'] as String;
                                      return _PerizinanTile(
                                        nama: santri['nama']?.toString() ?? '',
                                        jenis: p['jenis']?.toString() ?? '',
                                        alasan: p['alasan'] as String,
                                        tanggal: (p['tanggalKeluar'] as String).substring(0, 10),
                                        status: status,
                                        showActions: !isWali,
                                        onApprove: status == 'DIAJUKAN' ? () => _action(p, 'DISETUJUI') : null,
                                        onReject: status == 'DIAJUKAN' ? () => _action(p, 'DITOLAK') : null,
                                        onReturn: status == 'DISETUJUI' ? () => _action(p, 'KEMBALI') : null,
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

class _StatusStyle {
  const _StatusStyle(this.bg, this.fg, this.border);
  final Color bg;
  final Color fg;
  final Color border;
}

_StatusStyle _statusStyleFor(String status) {
  switch (status) {
    case 'DIAJUKAN':
      return const _StatusStyle(PColors.pendingBg, PColors.pendingText, PColors.pendingBorder);
    case 'DISETUJUI':
      return const _StatusStyle(PColors.successBg, PColors.successText, PColors.successBorder);
    case 'DITOLAK':
      return const _StatusStyle(PColors.errorBg, PColors.errorText, PColors.errorBorder);
    case 'TELAT':
      return const _StatusStyle(PColors.errorBg, PColors.errorText, PColors.errorBorder);
    default:
      return const _StatusStyle(PColors.infoBg, PColors.infoText, PColors.infoBorder);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = _statusStyleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: s.border),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.02,
          color: s.fg,
        ),
      ),
    );
  }
}

class _PerizinanTile extends StatelessWidget {
  const _PerizinanTile({
    required this.nama,
    required this.jenis,
    required this.alasan,
    required this.tanggal,
    required this.status,
    required this.showActions,
    this.onApprove,
    this.onReject,
    this.onReturn,
  });

  final String nama;
  final String jenis;
  final String alasan;
  final String tanggal;
  final String status;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReturn;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('$nama • $jenis', style: PText.labelLg.copyWith(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(alasan, style: PText.bodyMd.copyWith(color: PColors.ink)),
          const SizedBox(height: 4),
          Text(tanggal, style: PText.bodySm),
          if (showActions && (onApprove != null || onReject != null || onReturn != null)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: _POutlinedButton(
                      label: 'Setujui',
                      color: PColors.successText,
                      onPressed: onApprove!,
                    ),
                  ),
                if (onApprove != null && onReject != null) const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(
                    child: _POutlinedButton(
                      label: 'Tolak',
                      color: PColors.errorText,
                      onPressed: onReject!,
                    ),
                  ),
                if (onReturn != null)
                  Expanded(
                    child: _POutlinedButton(
                      label: 'Tandai Kembali',
                      color: PColors.primary,
                      onPressed: onReturn!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _POutlinedButton extends StatelessWidget {
  const _POutlinedButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700),
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