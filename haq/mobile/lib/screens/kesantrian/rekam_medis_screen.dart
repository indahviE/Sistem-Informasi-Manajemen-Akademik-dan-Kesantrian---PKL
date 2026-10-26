import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama dengan layar admin lain (emerald + emas).
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
  static const warnBg = Color(0xFFFFF4E5);
  static const warnText = Color(0xFFB45309);
}

const _kGolDarah = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _kBatasRiwayat = 4;

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

String _namaOf(Map<String, dynamic> s) => (s['nama'] ?? '-').toString();

String _huruf(String nama) {
  final n = nama.trim();
  if (n.isEmpty) return '#';
  final c = n.substring(0, 1).toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(c) ? c : '#';
}

/// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
void _rcToast(BuildContext context, String title, {String? subtitle, bool error = false, double bottom = 16}) {
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
        margin: EdgeInsets.fromLTRB(side, 0, side, bottom),
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

Widget _rcCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _RC.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _RC.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

Widget _sectionHeader(IconData icon, String title, {Widget? trailing}) {
  return Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: _RC.goldSurface, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: _RC.gold),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _RC.ink)),
      ),
      if (trailing != null) trailing,
    ],
  );
}

Widget _miniPill(String text, {required Color bg, required Color fg, IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
      ],
    ),
  );
}

// =====================================================================
// Daftar santri
// =====================================================================
class RekamMedisScreen extends StatefulWidget {
  const RekamMedisScreen({super.key, this.onBack});

  /// Opsional: kalau diisi, tombol kembali muncul di header.
  final VoidCallback? onBack;

  @override
  State<RekamMedisScreen> createState() => _RekamMedisScreenState();
}

class _RekamMedisScreenState extends State<RekamMedisScreen> {
  List<Map<String, dynamic>> _santri = [];
  bool _loading = true;
  String? _error;
  String _q = '';
  String _kelasFilter = 'Semua';

  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

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
      final raw = res is List ? res : (res is Map ? (res['items'] as List? ?? []) : []);
      if (!mounted) return;
      setState(() {
        _santri = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  List<String> get _kelasList {
    final set = <String>{};
    for (final s in _santri) {
      final k = _kelasOf(s);
      if (k != '-') set.add(k);
    }
    final list = set.toList()..sort();
    return list;
  }

  int _countKelas(String k) => _santri.where((s) => _kelasOf(s) == k).length;

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    final list = _santri.where((s) {
      if (_kelasFilter != 'Semua' && _kelasOf(s) != _kelasFilter) return false;
      if (q.isEmpty) return true;
      return _namaOf(s).toLowerCase().contains(q) ||
          (s['nis'] ?? '').toString().toLowerCase().contains(q) ||
          _kelasOf(s).toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => _namaOf(a).toLowerCase().compareTo(_namaOf(b).toLowerCase()));
    return list;
  }

  // ---------------------------------------------------------------------
  // Komponen
  // ---------------------------------------------------------------------
  Widget _header() {
    return Row(
      children: [
        if (widget.onBack != null)
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _RC.border),
            ),
            child: IconButton(
              onPressed: widget.onBack,
              tooltip: 'Kembali',
              icon: Icon(Icons.arrow_back_rounded, color: _RC.primary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekam Medis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _RC.ink, letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text(
                _readOnly
                    ? 'Ketuk santri untuk melihat data medis'
                    : 'Ketuk santri untuk melihat dan mengubah data medis',
                style: const TextStyle(fontSize: 12, color: _RC.inkSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner() {
    final kelas = _kelasList.length;
    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                      Text(label,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_RC.primary, _RC.primaryGradientEnd],
          ),
          boxShadow: [BoxShadow(color: _RC.primary.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -36,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
              ),
            ),
            Positioned(
              right: 26,
              bottom: -46,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _RC.gold.withOpacity(0.12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.medical_information_outlined, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DATA MEDIS SANTRI',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withOpacity(0.75))),
                            const SizedBox(height: 3),
                            Text('${_santri.length} Santri Terdaftar',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      stat(Icons.class_outlined, '$kelas', 'Kelas'),
                      const SizedBox(width: 8),
                      stat(_readOnly ? Icons.visibility_outlined : Icons.edit_note_rounded,
                          _readOnly ? 'Pantau' : 'Kelola', 'Hak akses'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _RC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RC.border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        style: const TextStyle(fontSize: 14, color: _RC.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: 'Cari nama, NIS, atau kelas...',
          hintStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _RC.inkSecondary),
        ),
      ),
    );
  }

  Widget _kelasChips() {
    final kelas = _kelasList;
    if (kelas.length < 2) return const SizedBox.shrink();
    final opsi = ['Semua', ...kelas];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: opsi.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final k = opsi[i];
            final selected = _kelasFilter == k;
            final count = k == 'Semua' ? _santri.length : _countKelas(k);
            return InkWell(
              onTap: () => setState(() => _kelasFilter = k),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                decoration: BoxDecoration(
                  color: selected ? _RC.primary : _RC.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? _RC.primary : _RC.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(k == 'Semua' ? 'Semua' : 'Kelas $k',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _RC.inkSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withOpacity(0.22) : _RC.surfaceDim,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : _RC.ink)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _letterHeader(String huruf) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _RC.sage, borderRadius: BorderRadius.circular(8)),
            child: Text(huruf,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _RC.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _RC.border)),
        ],
      ),
    );
  }

  Widget _santriCard(Map<String, dynamic> s) {
    final nama = _namaOf(s);
    final kelas = _kelasOf(s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: _RC.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _RC.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _RekamDetail(santri: s))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SantriAvatar(name: nama, gender: s['jenisKelamin']?.toString(), size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _RC.ink)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.tag_rounded, size: 13, color: _RC.inkSecondary),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text('${s['nis'] ?? '-'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
                            ),
                            if (kelas != '-') ...[
                              const SizedBox(width: 8),
                              _miniPill('Kelas $kelas', bg: _RC.mint, fg: _RC.primary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: _RC.surfaceDim, shape: BoxShape.circle),
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: _RC.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String msg, IconData icon) {
    return _rcCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: _RC.goldSurface, shape: BoxShape.circle),
            child: Icon(icon, color: _RC.gold, size: 30),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _RC.ink)),
          const SizedBox(height: 4),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _RC.inkSecondary, height: 1.45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    final children = <Widget>[
      _header(),
      const SizedBox(height: 16),
      _banner(),
      const SizedBox(height: 16),
      _searchField(),
      _kelasChips(),
      const SizedBox(height: 16),
    ];

    if (_santri.isEmpty) {
      children.add(_emptyCard('Belum Ada Santri', 'Data santri akan tampil di sini setelah ditambahkan.',
          Icons.folder_open_outlined));
    } else if (list.isEmpty) {
      children.add(_emptyCard('Tidak Ditemukan', 'Coba kata kunci lain atau ubah filter kelas.',
          Icons.search_off_rounded));
    } else {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: _RC.gold, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Daftar Santri',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _RC.ink)),
            ),
            Text('${list.length} santri', style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
          ],
        ),
      ));
      String? lastKey;
      for (final s in list) {
        final k = _huruf(_namaOf(s));
        if (k != lastKey) {
          children.add(_letterHeader(k));
          lastKey = k;
        }
        children.add(_santriCard(s));
      }
    }

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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        children: children,
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
  bool _showAllLogs = false;
  String? _error;
  String? _gol;

  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  /// Terkunci = sudah tersimpan dan belum dibuka untuk diubah (atau akun hanya-lihat).
  bool get _locked => _readOnly || (_saved && !_editing);

  /// Bar simpan di bawah hanya tampil saat form terbuka.
  bool get _showBar => !_loading && _error == null && !_locked;

  final _alergi = TextEditingController();
  final _riwayat = TextEditingController();
  final _tinggi = TextEditingController();
  final _berat = TextEditingController();
  final _catatan = TextEditingController();

  List<TextEditingController> get _ctrls => [_alergi, _riwayat, _tinggi, _berat, _catatan];

  @override
  void initState() {
    super.initState();
    for (final c in _ctrls) {
      c.addListener(_onChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _s(dynamic v) => v?.toString() ?? '';

  int get _terisi {
    var n = 0;
    if (_gol != null) n++;
    for (final c in [_alergi, _riwayat, _tinggi, _berat, _catatan]) {
      if (c.text.trim().isNotEmpty) n++;
    }
    return n;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final sid = _s(widget.santri['id']);
      final rm = await api.get('${ApiUrl.rekamMedis}/$sid') as Map<String, dynamic>;
      final logs = await api.get(ApiUrl.kesehatan, query: {'santriId': sid});
      if (!mounted) return;
      _alergi.text = _s(rm['alergi']);
      _riwayat.text = _s(rm['riwayatPenyakit']);
      _tinggi.text = _s(rm['tinggiBadan']);
      _berat.text = _s(rm['beratBadan']);
      _catatan.text = _s(rm['catatanKhusus']);
      setState(() {
        _rm = rm;
        _saved = rm['kosong'] != true;
        _editing = false;
        _logs = (logs as List);
        final g = _s(rm['golonganDarah']).trim();
        _gol = g.isEmpty ? null : g;
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
    _alergi.text = _s(_rm['alergi']);
    _riwayat.text = _s(_rm['riwayatPenyakit']);
    _tinggi.text = _s(_rm['tinggiBadan']);
    _berat.text = _s(_rm['beratBadan']);
    _catatan.text = _s(_rm['catatanKhusus']);
    setState(() {
      final g = _s(_rm['golonganDarah']).trim();
      _gol = g.isEmpty ? null : g;
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
      _rcToast(context, 'Tinggi dan berat harus berupa angka.', error: true, bottom: 92);
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
      _rcToast(context, e.message, error: true, bottom: 92);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _rcToast(context, 'Gagal menyimpan rekam medis.', error: true, bottom: 92);
    }
  }

  // ---------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------
  Widget _topBar() {
    final String statusLabel;
    final Color sBg;
    final Color sFg;
    final IconData sIcon;
    if (_loading) {
      statusLabel = '';
      sBg = Colors.transparent;
      sFg = Colors.transparent;
      sIcon = Icons.circle;
    } else if (_readOnly) {
      statusLabel = 'Hanya Lihat';
      sBg = _RC.surfaceDim;
      sFg = _RC.inkSecondary;
      sIcon = Icons.visibility_outlined;
    } else if (_editing) {
      statusLabel = 'Mode Ubah';
      sBg = _RC.warnBg;
      sFg = _RC.warnText;
      sIcon = Icons.edit_outlined;
    } else if (_saved) {
      statusLabel = 'Tersimpan';
      sBg = const Color(0xFFD2E4DC);
      sFg = const Color(0xFF0F3A2E);
      sIcon = Icons.verified_outlined;
    } else {
      statusLabel = 'Belum Diisi';
      sBg = _RC.goldSurface;
      sFg = _RC.goldDark;
      sIcon = Icons.pending_outlined;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _RC.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Kembali',
              icon: Icon(Icons.arrow_back_rounded, color: _RC.primary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Rekam Medis',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _RC.ink, letterSpacing: -0.3)),
          ),
          if (statusLabel.isNotEmpty) _miniPill(statusLabel, bg: sBg, fg: sFg, icon: sIcon),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero profil + vital
  // ---------------------------------------------------------------------
  Widget _vital(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    final nama = _s(widget.santri['nama']);
    final kelas = _kelasOf(widget.santri);
    final tinggi = _tinggi.text.trim();
    final berat = _berat.text.trim();
    final terisi = _terisi;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_RC.primary, _RC.primaryGradientEnd],
          ),
          boxShadow: [BoxShadow(color: _RC.primary.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -44,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -44,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _RC.gold.withOpacity(0.10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SantriAvatar(
                        name: nama,
                        gender: widget.santri['jenisKelamin']?.toString(),
                        size: 58,
                        onDark: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nama,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                SPill('NIS ${_s(widget.santri['nis'])}',
                                    icon: Icons.tag_rounded, bg: Colors.white.withOpacity(0.14), fg: Colors.white),
                                if (kelas != '-')
                                  SPill('Kelas $kelas', icon: Icons.class_outlined, bg: SC.mint, fg: SC.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _vital(Icons.bloodtype_rounded, 'Gol. Darah', _gol ?? '-'),
                      const SizedBox(width: 8),
                      _vital(Icons.height_rounded, 'Tinggi', tinggi.isEmpty ? '-' : '$tinggi cm'),
                      const SizedBox(width: 8),
                      _vital(Icons.monitor_weight_outlined, 'Berat', berat.isEmpty ? '-' : '$berat kg'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Kelengkapan data medis',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
                      const Spacer(),
                      Text('$terisi/6',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: terisi / 6,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(_RC.gold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Peringatan alergi (mode lihat)
  // ---------------------------------------------------------------------
  Widget _alergiAlert() {
    final a = _alergi.text.trim();
    if (!_locked || a.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _RC.errorBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _RC.errorText.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, size: 20, color: _RC.errorText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PERHATIAN: ALERGI',
                      style: TextStyle(
                          fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: _RC.errorText)),
                  const SizedBox(height: 3),
                  Text(a,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _RC.ink, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu data medis
  // ---------------------------------------------------------------------
  InputDecoration _dec(String label, {String? hint, String? suffix, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon == null ? null : Icon(icon, size: 19, color: _RC.inkSecondary),
        hintStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
        labelStyle: const TextStyle(fontSize: 13, color: _RC.inkSecondary),
        filled: true,
        fillColor: _RC.surfaceDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _RC.primary, width: 1.4),
        ),
      );

  Widget _infoBlock(IconData icon, String label, String value) {
    final kosong = value.trim().isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _RC.surfaceDim, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _RC.surface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: _RC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w800, color: _RC.inkSecondary)),
                const SizedBox(height: 3),
                Text(kosong ? 'Belum diisi' : value,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: kosong ? FontWeight.w500 : FontWeight.w700,
                      fontStyle: kosong ? FontStyle.italic : FontStyle.normal,
                      color: kosong ? _RC.inkSecondary : _RC.ink,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _golChip(String g) {
    final selected = _gol == g;
    return GestureDetector(
      onTap: () => setState(() => _gol = selected ? null : g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 62,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _RC.primary : _RC.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _RC.primary : _RC.border),
        ),
        child: Text(g,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _RC.inkSecondary,
            )),
      ),
    );
  }

  Widget _viewBody() {
    if (_readOnly && !_saved) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: _RC.goldSurface, shape: BoxShape.circle),
              child: const Icon(Icons.folder_open_outlined, color: _RC.gold, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Belum Ada Data Medis',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _RC.ink)),
            const SizedBox(height: 3),
            const Text('Data medis santri ini belum diisi oleh petugas.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: _RC.inkSecondary)),
          ],
        ),
      );
    }
    return Column(
      children: [
        _infoBlock(Icons.coronavirus_outlined, 'Alergi', _alergi.text.trim()),
        const SizedBox(height: 10),
        _infoBlock(Icons.history_edu_outlined, 'Riwayat Penyakit', _riwayat.text.trim()),
        const SizedBox(height: 10),
        _infoBlock(Icons.sticky_note_2_outlined, 'Catatan Khusus', _catatan.text.trim()),
      ],
    );
  }

  Widget _editBody() {
    final options = [..._kGolDarah, if (_gol != null && !_kGolDarah.contains(_gol)) _gol!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _saved ? _RC.warnBg : _RC.goldSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_saved ? Icons.edit_outlined : Icons.info_outline_rounded,
                  size: 16, color: _saved ? _RC.warnText : _RC.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _saved
                      ? 'Mode ubah aktif. Perubahan baru tersimpan setelah kamu menekan "Simpan Perubahan".'
                      : 'Data medis santri ini belum diisi. Lengkapi form di bawah lalu simpan.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: _saved ? _RC.warnText : _RC.goldDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('GOLONGAN DARAH',
            style: TextStyle(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w800, color: _RC.inkSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final g in options) _golChip(g)]),
        const SizedBox(height: 16),
        TextField(
          controller: _alergi,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, color: _RC.ink),
          decoration: _dec('Alergi', hint: 'Contoh: Debu, seafood, antibiotik', icon: Icons.coronavirus_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _riwayat,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, color: _RC.ink),
          decoration: _dec('Riwayat Penyakit', hint: 'Contoh: Asma sejak kecil', icon: Icons.history_edu_outlined),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tinggi,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14, color: _RC.ink),
                decoration: _dec('Tinggi', suffix: 'cm', icon: Icons.height_rounded),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _berat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14, color: _RC.ink),
                decoration: _dec('Berat', suffix: 'kg', icon: Icons.monitor_weight_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatan,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, color: _RC.ink),
          decoration: _dec('Catatan Khusus', icon: Icons.sticky_note_2_outlined),
        ),
      ],
    );
  }

  Widget _dataCard() {
    return _rcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.monitor_heart_outlined, 'Data Medis'),
          const SizedBox(height: 14),
          if (_locked) _viewBody() else _editBody(),
          if (_locked && !_readOnly) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ubah Data Medis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _RC.primary,
                  side: BorderSide(color: _RC.primary.withOpacity(0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Riwayat kesehatan (timeline)
  // ---------------------------------------------------------------------
  int _countLog(String status) => _logs.where((l) => _s((l as Map)['status']) == status).length;

  Widget _logStat(String label, int n, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text('$n', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _RC.inkSecondary)),
                Text(value, style: const TextStyle(fontSize: 12.5, height: 1.35, color: _RC.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logItem(Map<String, dynamic> l, {required bool last}) {
    final st = _statusStyle(_s(l['status']));
    final diagnosa = _s(l['diagnosa']).trim();
    final obat = _s(l['obat']).trim();
    final tindakan = _s(l['tindakan']).trim();
    final tempat = _s(l['tempat']).isEmpty ? 'UKS' : _s(l['tempat']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: st.fg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _RC.surface, width: 2),
                    boxShadow: [BoxShadow(color: st.fg.withOpacity(0.35), blurRadius: 4)],
                  ),
                ),
                if (!last) Expanded(child: Container(width: 2, color: _RC.border)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _RC.surfaceDim,
                  borderRadius: BorderRadius.circular(14),
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
                        _miniPill(st.label, bg: st.bg, fg: st.fg),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: _RC.inkSecondary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text('${_fmtIso(_s(l['tanggal']))} • $tempat',
                              style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
                        ),
                      ],
                    ),
                    if (diagnosa.isNotEmpty) _detailLine(Icons.fact_check_outlined, 'Diagnosa', diagnosa, _RC.primary),
                    if (obat.isNotEmpty) _detailLine(Icons.medication_outlined, 'Obat', obat, const Color(0xFF2563EB)),
                    if (tindakan.isNotEmpty)
                      _detailLine(Icons.medical_services_outlined, 'Tindakan', tindakan, _RC.gold),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riwayatCard() {
    final tampilCount = _showAllLogs ? _logs.length : (_logs.length > _kBatasRiwayat ? _kBatasRiwayat : _logs.length);
    final tampil = _logs.take(tampilCount).toList();

    return _rcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.history_rounded,
            'Riwayat Kesehatan',
            trailing: Text('${_logs.length} catatan',
                style: const TextStyle(fontSize: 11.5, color: _RC.inkSecondary)),
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _logStat('Rawat Jalan', _countLog('RAWAT_JALAN'), const Color(0xFFF3E2B8), const Color(0xFF7A5B10)),
                const SizedBox(width: 8),
                _logStat('Dirujuk', _countLog('DIRUJUK'), const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                const SizedBox(width: 8),
                _logStat('Sembuh', _countLog('SEMBUH'), const Color(0xFFD2E4DC), const Color(0xFF0F3A2E)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(color: _RC.goldSurface, shape: BoxShape.circle),
                      child: const Icon(Icons.health_and_safety_outlined, color: _RC.gold, size: 26),
                    ),
                    const SizedBox(height: 10),
                    const Text('Belum ada catatan kesehatan.',
                        style: TextStyle(fontSize: 13, color: _RC.inkSecondary)),
                  ],
                ),
              ),
            )
          else ...[
            for (int i = 0; i < tampil.length; i++)
              _logItem(Map<String, dynamic>.from(tampil[i] as Map), last: i == tampil.length - 1),
            if (_logs.length > _kBatasRiwayat) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showAllLogs = !_showAllLogs),
                  icon: Icon(_showAllLogs ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20, color: _RC.primary),
                  label: Text(
                    _showAllLogs ? 'Tampilkan lebih sedikit' : 'Lihat semua (${_logs.length - tampilCount} lagi)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _RC.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _RC.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bar aksi bawah (hanya saat form terbuka)
  // ---------------------------------------------------------------------
  Widget _actionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _RC.surface,
        border: Border(top: BorderSide(color: _RC.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  if (_editing) ...[
                    OutlinedButton(
                      onPressed: _saving ? null : _batalUbah,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _RC.inkSecondary,
                        side: const BorderSide(color: _RC.border),
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                                children: [
                                  _hero(),
                                  _alergiAlert(),
                                  const SizedBox(height: 14),
                                  _dataCard(),
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
      bottomNavigationBar: _showBar ? _actionBar() : null,
    );
  }
}