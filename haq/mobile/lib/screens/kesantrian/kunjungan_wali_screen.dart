import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';

/// Kunjungan Wali: catatan orang tua / wali yang menjenguk santri.
/// Alur: catat kunjungan (status BERLANGSUNG) → tandai selesai dijenguk (status SELESAI).
/// Class tetap bernama KunjunganScreen supaya import di shell & direktori tidak perlu diubah.
class KunjunganScreen extends StatefulWidget {
  const KunjunganScreen({super.key, this.onBack, this.subtitle = 'Musyrif • Kunjungan Wali'});

  final VoidCallback? onBack;
  final String subtitle;

  @override
  State<KunjunganScreen> createState() => _KunjunganScreenState();
}

enum _Periode { semua, mingguIni, bulanIni }

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _fmtTanggal(DateTime d) =>
    '${d.day} ${_bulan[d.month - 1]} ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

List<Map<String, dynamic>> _asList(dynamic res) {
  final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
  final list = raw is List ? raw : const [];
  return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// Notifikasi melayang bertema (sama dengan _toast di kesehatan & pelanggaran).
void _showToast(BuildContext context, String title, {String? subtitle, bool error = false}) {
  final w = MediaQuery.of(context).size.width;
  final side = w > 472 ? (w - 440) / 2 : 16.0;
  final fg = error ? SC.errorText : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? SC.errorBg : SC.primary,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: Duration(seconds: error ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: error ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: error ? Colors.white : SC.gold.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error ? Icons.error_outline : Icons.check_rounded,
                size: 18,
                color: error ? SC.errorText : SC.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: kFont, fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontFamily: kFont, fontSize: 11.5, color: fg.withOpacity(0.75))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

String _str(Map? m, String key) => (m?[key] ?? '').toString();

class _KunjunganScreenState extends State<KunjunganScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _santri = [];
  bool _loading = true;
  bool _started = false;
  String? _error;
  _Periode _periode = _Periode.semua;
  String _query = '';
  final Set<String> _sedangDiproses = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load({bool showSpinner = true}) async {
    final api = AppScope.of(context).api;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        api.get('/kunjungan'),
        api.get(ApiUrl.santri, query: {'perPage': '100'}),
      ]);
      if (!mounted) return;
      setState(() {
        _items = _asList(results[0]);
        _santri = _asList(results[1]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime? _tgl(Map<String, dynamic> k) => DateTime.tryParse((k['tanggal'] ?? '').toString())?.toLocal();

  bool _sedangBerlangsung(Map<String, dynamic> k) => _str(k, 'status') != 'SELESAI';

  bool _dalamMingguIni(DateTime d) {
    final now = DateTime.now();
    final awalMinggu = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return !d.isBefore(awalMinggu);
  }

  bool _dalamBulanIni(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  int get _countMinggu => _items.where((k) => _tgl(k) != null && _dalamMingguIni(_tgl(k)!)).length;
  int get _countBulan => _items.where((k) => _tgl(k) != null && _dalamBulanIni(_tgl(k)!)).length;

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _items.where((k) {
      final d = _tgl(k);
      if (_periode == _Periode.mingguIni && (d == null || !_dalamMingguIni(d))) return false;
      if (_periode == _Periode.bulanIni && (d == null || !_dalamBulanIni(d))) return false;
      if (q.isEmpty) return true;
      final santri = _str(k['santri'] as Map?, 'nama').toLowerCase();
      final wali = _str(k, 'namaWali').toLowerCase();
      return santri.contains(q) || wali.contains(q);
    }).toList();
    // Yang masih berlangsung ditampilkan paling atas, lalu urut tanggal terbaru.
    list.sort((a, b) {
      final ba = _sedangBerlangsung(a) ? 0 : 1;
      final bb = _sedangBerlangsung(b) ? 0 : 1;
      if (ba != bb) return ba.compareTo(bb);
      return (_tgl(b) ?? DateTime(0)).compareTo(_tgl(a) ?? DateTime(0));
    });
    return list;
  }

  Future<void> _openForm() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _KunjunganForm(santri: _santri),
    );
    if (ok == true && mounted) {
      _showToast(context, 'Kunjungan wali tercatat', subtitle: 'Status: sedang dijenguk');
      _load(showSpinner: false);
    }
  }

  Future<void> _tandaiSelesai(Map<String, dynamic> k) async {
    final id = _str(k, 'id');
    final api = AppScope.of(context).api;
    setState(() => _sedangDiproses.add(id));
    try {
      await api.patch('/kunjungan/$id/selesai', {});
      if (!mounted) return;
      _showToast(context, 'Kunjungan selesai dijenguk', subtitle: 'Waktu selesai sudah tercatat');
      _load(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      _showToast(context, 'Gagal menandai selesai', subtitle: '$e', error: true);
    } finally {
      if (mounted) setState(() => _sedangDiproses.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    final canInput = user != null && (user.isMusyrif || user.isAdmin);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: SC.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildSearch(),
                    _buildFilters(),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? _buildError()
                              : RefreshIndicator(
                                  onRefresh: () => _load(showSpinner: false),
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                    children: filtered.isEmpty
                                        ? [_buildEmpty()]
                                        : [for (final k in filtered) _kunjunganCard(k, canInput)],
                                  ),
                                ),
                    ),
                  ],
                ),
                if (canInput)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _openForm,
                      tooltip: 'Catat Kunjungan',
                      backgroundColor: SC.primary,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Catat Kunjungan', style: sty(14, FontWeight.w700, Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final jumlahBerlangsung = _items.where(_sedangBerlangsung).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: SC.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              onPressed: widget.onBack,
              tooltip: 'Kembali',
              icon: Icon(Icons.arrow_back, color: SC.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Kunjungan Wali', style: sty(19, FontWeight.w800, const Color(0xFF1B1C1A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: SC.primary, borderRadius: BorderRadius.circular(999)),
                    child: Text('$jumlahBerlangsung Sedang dijenguk', style: sty(10.5, FontWeight.w800, Colors.white)),
                  ),
                ]),
                const SizedBox(height: 1),
                Text(widget.subtitle, style: sty(12, FontWeight.w500, SC.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        style: sty(14, FontWeight.w500, SC.ink),
        decoration: InputDecoration(
          hintText: 'Cari nama santri atau wali...',
          hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
          prefixIcon: const Icon(Icons.search, color: SC.inkSecondary),
          filled: true,
          fillColor: SC.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, int count, _Periode p) {
      final selected = _periode == p;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _periode = p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? SC.primary : SC.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? SC.primary : SC.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: sty(12.5, FontWeight.w700, selected ? Colors.white : SC.ink)),
              const SizedBox(width: 6),
              Text('$count', style: sty(11, FontWeight.w800, selected ? Colors.white70 : SC.inkSecondary)),
            ]),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        chip('Semua', _items.length, _Periode.semua),
        chip('Minggu Ini', _countMinggu, _Periode.mingguIni),
        chip('Bulan Ini', _countBulan, _Periode.bulanIni),
      ]),
    );
  }

  Widget _kunjunganCard(Map<String, dynamic> k, bool canInput) {
    final santri = k['santri'] as Map?;
    final tgl = _tgl(k);
    final selesaiRaw = DateTime.tryParse(_str(k, 'selesaiAt'))?.toLocal();
    final berlangsung = _sedangBerlangsung(k);
    final namaWali = _str(k, 'namaWali').trim();
    final catatan = _str(k, 'catatan').trim();
    final nama = _str(santri, 'nama');
    final kelas = _str(santri?['kelas'] as Map?, 'namaKelas');
    final id = _str(k, 'id');
    final diproses = _sedangDiproses.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SantriAvatar(name: nama.isEmpty ? '?' : nama, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama.isEmpty ? '-' : nama, style: sty(14, FontWeight.w800, SC.ink)),
                  Text(kelas.isEmpty ? 'Santri' : 'Kelas $kelas', style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                ],
              ),
            ),
            SPill(
              berlangsung ? 'Sedang dijenguk' : 'Selesai',
              bg: berlangsung ? SC.pendingBg : SC.successBg,
              fg: berlangsung ? SC.pendingText : SC.successText,
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: SC.goldSurface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.family_restroom, size: 18, color: SC.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  namaWali.isEmpty ? 'Wali tidak dicatat' : namaWali,
                  style: sty(12.5, FontWeight.w700, SC.ink),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.schedule, size: 14, color: SC.inkSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tgl == null
                    ? '-'
                    : berlangsung
                        ? 'Datang: ${_fmtTanggal(tgl)}'
                        : 'Datang: ${_fmtTanggal(tgl)}${selesaiRaw == null ? '' : '\nSelesai: ${_fmtTanggal(selesaiRaw)}'}',
                style: sty(11.5, FontWeight.w600, SC.inkSecondary, h: 1.4),
              ),
            ),
          ]),
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(catatan, style: sty(12, FontWeight.w500, SC.ink, h: 1.4)),
          ],
          if (berlangsung && canInput) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: diproses ? null : () => _tandaiSelesai(k),
                style: FilledButton.styleFrom(
                  backgroundColor: SC.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: diproses
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                label: Text('Tandai Selesai Dijenguk', style: sty(13, FontWeight.w700, Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(children: [
        Icon(Icons.family_restroom_outlined, size: 48, color: SC.inkMuted),
        const SizedBox(height: 12),
        Text(
          _items.isEmpty
              ? 'Belum ada catatan kunjungan wali.\nKetuk "Catat Kunjungan" untuk menambah.'
              : 'Tidak ada kunjungan yang cocok dengan filter.',
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.5),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Gagal memuat data kunjungan.', style: sty(14, FontWeight.w700, SC.ink)),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _load(),
            style: FilledButton.styleFrom(backgroundColor: SC.primary),
            child: const Text('Coba lagi'),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Form catat kunjungan (bottom sheet) — gaya input disamakan dengan Pelanggaran
// ---------------------------------------------------------------------
InputDecoration _fieldDeco({String? hint, String? errorText}) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: SC.background,
      hintText: hint,
      hintStyle: sty(13, FontWeight.w500, SC.inkMuted),
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );

Widget _fieldLabel(String label, {String? suffix}) => Text.rich(TextSpan(
      text: label,
      style: sty(13, FontWeight.w700, SC.ink),
      children: [
        if (suffix != null) TextSpan(text: ' $suffix', style: sty(12, FontWeight.w500, SC.inkSecondary)),
      ],
    ));

class _KunjunganForm extends StatefulWidget {
  const _KunjunganForm({required this.santri});

  final List<Map<String, dynamic>> santri;

  @override
  State<_KunjunganForm> createState() => _KunjunganFormState();
}

class _KunjunganFormState extends State<_KunjunganForm> {
  String? _santriId;
  DateTime _tanggal = DateTime.now();
  final _waliCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  bool _saving = false;
  String? _errSantri;

  @override
  void dispose() {
    _waliCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _tanggal = DateTime(picked.year, picked.month, picked.day, _tanggal.hour, _tanggal.minute));
    }
  }

  Future<void> _simpan() async {
    if (_santriId == null) {
      setState(() => _errSantri = 'Pilih santri terlebih dahulu');
      return;
    }
    final wali = _waliCtrl.text.trim();
    final catatan = _catatanCtrl.text.trim();
    final api = AppScope.of(context).api;
    setState(() => _saving = true);
    try {
      await api.post('/kunjungan', {
        'santriId': _santriId,
        'namaWali': wali.isEmpty ? null : wali,
        'tanggal': _tanggal.toIso8601String(),
        'catatan': catatan.isEmpty ? null : catatan,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showToast(context, 'Gagal menyimpan kunjungan', subtitle: '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: SC.inkSecondary.withOpacity(0.25), borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Catat Kunjungan Wali', style: sty(17, FontWeight.w800, SC.ink)),
              const SizedBox(height: 16),
              _fieldLabel('Santri yang dijenguk', suffix: '*'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _santriId,
                isExpanded: true,
                style: sty(14, FontWeight.w500, SC.ink),
                decoration: _fieldDeco(hint: 'Pilih santri', errorText: _errSantri),
                items: [
                  for (final s in widget.santri)
                    DropdownMenuItem(
                      value: s['id'].toString(),
                      child: Text('${s['nama'] ?? '-'} • ${s['nis'] ?? '-'}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _santriId = v;
                  _errSantri = null;
                }),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Nama wali yang datang', suffix: '(Opsional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _waliCtrl,
                textCapitalization: TextCapitalization.words,
                style: sty(14, FontWeight.w500, SC.ink),
                decoration: _fieldDeco(hint: 'Contoh: Bapak Ahmad (ayah)'),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Tanggal kunjungan', suffix: '*'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: SC.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(
                      child: Text(_fmtTanggal(_tanggal).split(' • ').first, style: sty(14, FontWeight.w500, SC.ink)),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: SC.inkSecondary),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Catatan', suffix: '(Opsional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _catatanCtrl,
                maxLines: 3,
                style: sty(14, FontWeight.w500, SC.ink),
                decoration: _fieldDeco(hint: 'Contoh: membawa bekal dan pakaian ganti'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: SC.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Simpan', style: sty(14, FontWeight.w700, Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}