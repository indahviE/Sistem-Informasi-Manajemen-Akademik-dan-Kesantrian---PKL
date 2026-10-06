import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama persis dengan `_AC` di absensi_screen.dart.
class _RC {
  _RC._();

  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

const _kGolDarah = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class _StatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusStyle(this.label, this.bg, this.fg);
}

_StatusStyle _statusStyle(String s) {
  switch (s) {
    case 'RAWAT_JALAN':
      return const _StatusStyle('Rawat Jalan', Color(0xFFF3E2B8), Color(0xFF7A5B10));
    case 'DIRUJUK':
      return const _StatusStyle('Dirujuk', Color(0xFFFEE2E2), Color(0xFF991B1B));
    case 'SEMBUH':
      return const _StatusStyle('Sembuh', Color(0xFFD2E4DC), Color(0xFF0F3A2E));
    default:
      return _StatusStyle(s, const Color(0xFFE6E4DB), const Color(0xFF0F172A));
  }
}

String _fmtIso(String raw) {
  if (raw.length < 10) return raw;
  final p = raw.substring(0, 10).split('-');
  if (p.length != 3) return raw.substring(0, 10);
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final m = int.tryParse(p[1]) ?? 0;
  final d = int.tryParse(p[2]) ?? 0;
  if (m < 1 || m > 12) return raw.substring(0, 10);
  return '$d ${months[m]} ${p[0]}';
}

String _kelasOf(Map<String, dynamic> s) {
  final k = s['kelas'];
  if (k is Map && k['namaKelas'] != null) return k['namaKelas'].toString();
  return '-';
}

String _inisial(String nama) {
  final n = nama.trim();
  return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
}

/// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
void _rcToast(BuildContext context, String title, {String? subtitle, bool error = false}) {
  if (!context.mounted) return;
  final w = MediaQuery.of(context).size.width;
  final side = w > 472 ? (w - 440) / 2 : 16.0;
  final fg = error ? _RC.errorText : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? _RC.errorBg : _RC.primary,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: Duration(seconds: error ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: error ? _RC.errorText.withOpacity(0.25) : _RC.gold.withOpacity(0.5)),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: error ? Colors.white : _RC.gold.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error ? Icons.error_outline : Icons.check_rounded,
                size: 18,
                color: error ? _RC.errorText : _RC.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

Widget _rcCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _RC.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _RC.border),
    ),
    child: child,
  );
}

// =====================================================================
// Daftar santri
// =====================================================================
class RekamMedisScreen extends StatefulWidget {
  const RekamMedisScreen({super.key});

  @override
  State<RekamMedisScreen> createState() => _RekamMedisScreenState();
}

class _RekamMedisScreenState extends State<RekamMedisScreen> {
  List<Map<String, dynamic>> _santri = [];
  bool _loading = true;
  String? _error;
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.santri, query: {'perPage': '100'});
      final items = (res as Map<String, dynamic>)['items'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _santri = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar santri.';
          _loading = false;
        });
      }
    }
  }

  Widget _banner() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_RC.primary, _RC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _RC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _RC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.folder_shared_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATA MEDIS SANTRI',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 2),
                      Text('${_santri.length} Santri Terdaftar',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _q = v),
      style: const TextStyle(fontSize: 14, color: _RC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama, NIS, atau kelas',
        hintStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _RC.inkSecondary),
        filled: true,
        fillColor: _RC.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _RC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _RC.primary),
        ),
      ),
    );
  }

  Widget _santriCard(int index, Map<String, dynamic> s) {
    final nama = (s['nama'] ?? '-').toString();
    final even = index.isEven;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _RekamDetail(santri: s))),
      borderRadius: BorderRadius.circular(16),
      child: _rcCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: even ? _RC.sage : _RC.goldSurface, shape: BoxShape.circle),
              child: Text(_inisial(nama),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: even ? _RC.primary : _RC.gold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _RC.ink)),
                  const SizedBox(height: 2),
                  Text('NIS ${s['nis'] ?? '-'} • ${_kelasOf(s)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _RC.inkSecondary),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return _rcCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: _RC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.folder_open_outlined, color: _RC.gold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _RC.inkSecondary, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = _santri.where((s) {
      if (q.isEmpty) return true;
      return (s['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (s['nis'] ?? '').toString().toLowerCase().contains(q) ||
          _kelasOf(s).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: _RC.background,
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: RefreshIndicator(
                      color: _RC.primary,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        children: [
                          const Text('Rekam Medis',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _RC.ink)),
                          const SizedBox(height: 2),
                          const Text('Ketuk santri untuk melihat dan mengubah data medis',
                              style: TextStyle(fontSize: 12, color: _RC.inkSecondary)),
                          const SizedBox(height: 14),
                          _banner(),
                          const SizedBox(height: 14),
                          _searchField(),
                          const SizedBox(height: 14),
                          if (_santri.isEmpty)
                            _emptyCard('Belum ada santri.')
                          else if (list.isEmpty)
                            _emptyCard('Santri tidak ditemukan.')
                          else
                            for (int i = 0; i < list.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _santriCard(i, list[i]),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

// =====================================================================
// Detail rekam medis satu santri
// =====================================================================
class _RekamDetail extends StatefulWidget {
  final Map<String, dynamic> santri;
  const _RekamDetail({required this.santri});

  @override
  State<_RekamDetail> createState() => _RekamDetailState();
}

class _RekamDetailState extends State<_RekamDetail> {
  Map<String, dynamic> _rm = {};
  List<dynamic> _logs = [];
  bool _loading = true;
  bool _saving = false;
  bool _saved = false; // true = rekam medis santri ini sudah ada di server
  bool _editing = false; // true = admin membuka kunci ("Ubah Data Medis")
  String? _error;
  String? _gol;

  /// Terkunci = sudah tersimpan dan belum dibuka untuk diubah.
  bool get _locked => _saved && !_editing;

  final _alergi = TextEditingController();
  final _riwayat = TextEditingController();
  final _tinggi = TextEditingController();
  final _berat = TextEditingController();
  final _catatan = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _alergi.dispose();
    _riwayat.dispose();
    _tinggi.dispose();
    _berat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  String _s(dynamic v) => v?.toString() ?? '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final sid = widget.santri['id'] as String;
      final rm = await api.get('${ApiUrl.rekamMedis}/$sid') as Map<String, dynamic>;
      final logs = await api.get(ApiUrl.kesehatan, query: {'santriId': sid});
      if (!mounted) return;
      setState(() {
        _rm = rm;
        _saved = rm['kosong'] != true;
        _editing = false;
        _logs = (logs as List);
        final g = _s(rm['golonganDarah']).trim();
        _gol = g.isEmpty ? null : g;
        _alergi.text = _s(rm['alergi']);
        _riwayat.text = _s(rm['riwayatPenyakit']);
        _tinggi.text = _s(rm['tinggiBadan']);
        _berat.text = _s(rm['beratBadan']);
        _catatan.text = _s(rm['catatanKhusus']);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat rekam medis.';
          _loading = false;
        });
      }
    }
  }

  /// Batal ubah: kembalikan isi form ke data tersimpan terakhir.
  void _batalUbah() {
    FocusScope.of(context).unfocus();
    setState(() {
      final g = _s(_rm['golonganDarah']).trim();
      _gol = g.isEmpty ? null : g;
      _alergi.text = _s(_rm['alergi']);
      _riwayat.text = _s(_rm['riwayatPenyakit']);
      _tinggi.text = _s(_rm['tinggiBadan']);
      _berat.text = _s(_rm['beratBadan']);
      _catatan.text = _s(_rm['catatanKhusus']);
      _editing = false;
    });
  }

  String? _nullIfEmpty(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _simpan() async {
    if (_saving) return;
    final tinggi = _tinggi.text.trim();
    final berat = _berat.text.trim();
    if ((tinggi.isNotEmpty && int.tryParse(tinggi) == null) ||
        (berat.isNotEmpty && int.tryParse(berat) == null)) {
      _rcToast(context, 'Tinggi dan berat harus berupa angka.', error: true);
      return;
    }

    final payload = <String, dynamic>{
      'golonganDarah': _gol,
      'alergi': _nullIfEmpty(_alergi.text),
      'riwayatPenyakit': _nullIfEmpty(_riwayat.text),
      'tinggiBadan': int.tryParse(tinggi),
      'beratBadan': int.tryParse(berat),
      'catatanKhusus': _nullIfEmpty(_catatan.text),
    };

    setState(() => _saving = true);
    try {
      await AppScope.of(context).api.put('${ApiUrl.rekamMedis}/${widget.santri['id']}', payload);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _rm = {..._rm, ...payload}..remove('kosong');
        _saving = false;
        _saved = true;
        _editing = false;
      });
      _rcToast(context, 'Rekam medis disimpan', subtitle: _s(widget.santri['nama']));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _rcToast(context, e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _rcToast(context, 'Gagal menyimpan rekam medis.', error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  InputDecoration _dec(String label, {String? hint, String? suffix}) => InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        hintStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
        labelStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
        filled: true,
        fillColor: _locked ? _RC.surface : _RC.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: _locked ? const BorderSide(color: _RC.border) : BorderSide.none,
        ),
      );

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    final nama = _s(widget.santri['nama']);
    final tinggi = _s(_rm['tinggiBadan']);
    final berat = _s(_rm['beratBadan']);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_RC.primary, _RC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _RC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _RC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: Text(_inisial(nama),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('NIS ${_s(widget.santri['nis'])} • ${_kelasOf(widget.santri)}',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _heroStat('Gol. Darah', _gol ?? '-'),
                    const SizedBox(width: 8),
                    _heroStat('Tinggi', tinggi.isEmpty ? '-' : '$tinggi cm'),
                    const SizedBox(width: 8),
                    _heroStat('Berat', berat.isEmpty ? '-' : '$berat kg'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(color: _RC.goldSurface, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: _RC.gold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _RC.ink)),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11, color: _RC.inkSecondary)),
      ],
    );
  }

  Widget _golChip(String g) {
    final selected = _gol == g;
    return GestureDetector(
      onTap: _locked ? null : () => setState(() => _gol = selected ? null : g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 58,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _RC.primary : _RC.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _RC.primary : _RC.border),
        ),
        child: Text(g,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _RC.inkSecondary,
            )),
      ),
    );
  }

    Widget _formCard() {
    final options = [..._kGolDarah, if (_gol != null && !_kGolDarah.contains(_gol)) _gol!];
    return _rcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.monitor_heart_outlined, 'Data Medis',
              trailing: _locked ? 'Tersimpan' : (_editing ? 'Mode Ubah' : 'Belum diisi')),
          if (_locked) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _RC.goldSurface, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 15, color: _RC.gold),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data medis sudah tersimpan dan terkunci. Ketuk "Ubah Data Medis" untuk mengedit.',
                      style: TextStyle(fontSize: 12, height: 1.35, color: _RC.goldDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('GOLONGAN DARAH',
              style: TextStyle(
                  fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: _RC.inkSecondary)),
          const SizedBox(height: 8),
          if (_locked && _gol == null)
            const Text('Belum diisi', style: TextStyle(fontSize: 13, color: _RC.inkSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in options)
                  if (!_locked || g == _gol) _golChip(g),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _alergi,
            enabled: !_locked,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, color: _RC.ink),
            decoration: _dec('Alergi', hint: 'Contoh: Debu, seafood, antibiotik'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _riwayat,
            enabled: !_locked,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, color: _RC.ink),
            decoration: _dec('Riwayat Penyakit', hint: 'Contoh: Asma sejak kecil'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tinggi,
                  enabled: !_locked,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14, color: _RC.ink),
                  decoration: _dec('Tinggi', suffix: 'cm'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _berat,
                  enabled: !_locked,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14, color: _RC.ink),
                  decoration: _dec('Berat', suffix: 'kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatan,
            enabled: !_locked,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, color: _RC.ink),
            decoration: _dec('Catatan Khusus'),
          ),
          const SizedBox(height: 16),
          if (_locked)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ubah Data Medis',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _RC.primary,
                  side: const BorderSide(color: _RC.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            )
          else
            Row(
              children: [
                if (_editing) ...[
                  OutlinedButton(
                    onPressed: _saving ? null : _batalUbah,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _RC.inkSecondary,
                      side: const BorderSide(color: _RC.border),
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _simpan,
                      style: FilledButton.styleFrom(
                        backgroundColor: _RC.primary,
                        disabledBackgroundColor: _RC.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                      label: Text(
                        _saving ? 'Menyimpan...' : (_editing ? 'Simpan Perubahan' : 'Simpan Rekam Medis'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value, {Color color = _RC.inkSecondary}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label: $value',
                style: const TextStyle(fontSize: 12, height: 1.35, color: _RC.ink)),
          ),
        ],
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> l) {
    final st = _statusStyle(_s(l['status']));
    final diagnosa = _s(l['diagnosa']).trim();
    final obat = _s(l['obat']).trim();
    final tindakan = _s(l['tindakan']).trim();
    final tempat = _s(l['tempat']).isEmpty ? 'UKS' : _s(l['tempat']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _RC.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(_s(l['keluhan']),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _RC.ink)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(st.label,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: st.fg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: _RC.inkSecondary),
              const SizedBox(width: 5),
              Text('${_fmtIso(_s(l['tanggal']))} • $tempat',
                  style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
            ],
          ),
          if (diagnosa.isNotEmpty) _detailLine(Icons.fact_check_outlined, 'Diagnosa', diagnosa),
          if (obat.isNotEmpty) _detailLine(Icons.medication_outlined, 'Obat', obat),
          if (tindakan.isNotEmpty)
            _detailLine(Icons.medical_services_outlined, 'Tindakan', tindakan, color: _RC.gold),
        ],
      ),
    );
  }

  Widget _riwayatCard() {
    return _rcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.history_rounded, 'Riwayat Kesehatan', trailing: '${_logs.length} catatan'),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('Belum ada catatan kesehatan.',
                    style: TextStyle(fontSize: 13, color: _RC.inkSecondary)),
              ),
            )
          else
            for (int i = 0; i < _logs.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == _logs.length - 1 ? 0 : 10),
                child: _logCard(_logs[i] as Map<String, dynamic>),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RC.background,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? loadingView()
                      : _error != null
                          ? errorView(_error!, _load)
                          : RefreshIndicator(
                              color: _RC.primary,
                              onRefresh: _load,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                                children: [
                                  _hero(),
                                  const SizedBox(height: 14),
                                  _formCard(),
                                  const SizedBox(height: 14),
                                  _riwayatCard(),
                                ],
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

  /// Header sama gayanya dengan layar Kesehatan: judul 19 tebal + subjudul kecil.
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded, color: _RC.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rekam Medis',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _RC.ink)),
                const SizedBox(height: 2),
                Text('${_s(widget.santri['nama'])} • NIS ${_s(widget.santri['nis'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _RC.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}