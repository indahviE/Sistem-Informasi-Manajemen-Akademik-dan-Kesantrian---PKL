import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet dashboard wali. Warna utama ikut identitas pondok (SC),
/// aksen emas dan warna status tetap.
class _WD {
  _WD._();

  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFE2C58A);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF7A5B10);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);
  static const dangerText = Color(0xFF991B1B);
}

// ---------------------------------------------------------------------------
// Helper aman-null
// ---------------------------------------------------------------------------
String? _str(Map<String, dynamic>? m, List<String> keys) {
  if (m == null) return null;
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return null;
}

num? _numOf(List<Map<String, dynamic>> sources, List<String> keys) {
  for (final m in sources) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v;
      if (v is String) {
        final p = num.tryParse(v);
        if (p != null) return p;
      }
    }
  }
  return null;
}

List<Map<String, dynamic>> _anakOf(Map<String, dynamic> data) {
  final raw = data['anak'];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

String _kelasOf(Map<String, dynamic> a) {
  final k = a['kelas'];
  if (k is String && k.trim().isNotEmpty) return k;
  if (k is Map && k['namaKelas'] != null) return k['namaKelas'].toString();
  final asrama = a['asrama'];
  if (asrama is String && asrama.trim().isNotEmpty) return asrama;
  return '-';
}

String _tanggalIndo(DateTime dt) {
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
  const months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} ${dt.year}';
}

String _kapital(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1).toLowerCase();
}

String _salam() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------
class WaliHero extends StatelessWidget {
  final Map<String, dynamic> data;
  const WaliHero({super.key, required this.data});

  Widget _pill(IconData icon, String text, {required Color bg, required Color fg, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    final nama = _str(data, ['namaPengguna', 'nama', 'userName']) ?? user?.nama ?? 'Wali Santri';
    final tn = user?.tenantNama;
    final pondok = _str(data, ['namaPondok', 'namaLembaga', 'tenantNama']) ??
        ((tn != null && tn.isNotEmpty) ? tn : null);
    final jumlahAnak = _anakOf(data).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_WD.primary, _WD.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _WD.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ornamen geometris ala rub el hizb
          Positioned(
            right: -26,
            top: -26,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _WD.gold.withOpacity(0.25), width: 1.2),
              ),
            ),
          ),
          Positioned(
            left: -44,
            bottom: -54,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _WD.gold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: _WD.gold.withOpacity(0.7)),
                      ),
                      child: const Icon(Icons.mosque_outlined, size: 20, color: _WD.goldLight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PORTAL WALI SANTRI',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: _WD.goldLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pondok ?? 'Pondok Pesantren',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  "Assalamu'alaikum  •  ${_salam()}",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau perkembangan ananda dengan tenang dan transparan.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.68),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(
                      Icons.calendar_today_outlined,
                      _tanggalIndo(DateTime.now()),
                      bg: Colors.white.withOpacity(0.12),
                      fg: Colors.white,
                    ),
                    if (jumlahAnak > 0)
                      _pill(
                        Icons.family_restroom,
                        '$jumlahAnak Anak',
                        bg: _WD.mint,
                        fg: _WD.primary,
                      ),
                    _pill(
                      Icons.visibility_outlined,
                      'Mode Pantau',
                      bg: _WD.gold.withOpacity(0.18),
                      fg: _WD.goldLight,
                      border: _WD.gold.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BODY
// ---------------------------------------------------------------------------
class WaliBody extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(String label) onNavigate;
  const WaliBody({super.key, required this.data, required this.onNavigate});

  @override
  State<WaliBody> createState() => _WaliBodyState();
}

class _WaliBodyState extends State<WaliBody> {
  int _sel = 0;

  /// Judul section dengan penanda emas.
  Widget _title(String t, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _WD.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            t,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: _WD.ink,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11.5, color: _WD.inkSecondary)),
      ],
    );
  }

  Widget _pairRow(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );
  }

  Widget _emptyAnak() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: _WD.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _WD.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: _WD.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.family_restroom, color: _WD.gold, size: 30),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada santri yang terhubung',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WD.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hubungi admin pondok untuk menghubungkan akun ini dengan data anak Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _WD.inkSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _childSelector(List<Map<String, dynamic>> anak) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: anak.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _sel;
          final nama = (anak[i]['nama'] as String?)?.trim();
          final label = (nama == null || nama.isEmpty) ? 'Santri ${i + 1}' : nama.split(' ').first;
          final inisial = label.isNotEmpty ? label[0].toUpperCase() : '?';
          return GestureDetector(
            onTap: () => setState(() => _sel = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(5, 4, 16, 4),
              decoration: BoxDecoration(
                color: selected ? _WD.primary : _WD.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _WD.primary : _WD.border),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _WD.primary.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? Colors.white.withOpacity(0.18) : _WD.sage,
                    ),
                    child: Text(
                      inisial,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? _WD.goldLight : _WD.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _WD.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _WD.inkSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _WD.ink),
          ),
        ],
      ),
    );
  }

  /// Kartu identitas santri gaya kartu ID.
  Widget _childCard(Map<String, dynamic> a) {
    final nama = (a['nama'] as String?) ?? 'Santri';
    final nis = (a['nis'] as String?) ?? '-';
    final status = _kapital(_str(a, ['status']) ?? 'Aktif');
    final aktif = status.toLowerCase() == 'aktif';
    final inisial = nama.trim().isNotEmpty ? nama.trim()[0].toUpperCase() : '?';
    final asrama = _str(a, ['asrama']) ?? '-';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _WD.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _WD.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pita emas di atas kartu
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_WD.gold, _WD.goldLight, _WD.gold]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _WD.gold, width: 1.6),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_WD.primary, _WD.primaryEnd],
                      ),
                    ),
                    child: Text(
                      inisial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _WD.goldLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: _WD.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: aktif ? _WD.successBg : _WD.pendingBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: aktif ? _WD.successText : _WD.pendingText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Santri $status',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: aktif ? _WD.successText : _WD.pendingText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: _WD.surfaceDim,
              border: Border(top: BorderSide(color: _WD.border)),
            ),
            child: Row(
              children: [
                _infoCol('NIS', nis),
                _infoCol('KELAS', _kelasOf(a)),
                _infoCol('ASRAMA', asrama),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anak = _anakOf(widget.data);
    if (_sel >= anak.length) _sel = 0;
    final a = anak.isEmpty ? null : anak[_sel];

    // Sumber angka ringkasan: data anak -> ringkasan anak -> ringkasan umum.
    final sources = <Map<String, dynamic>>[
      if (a != null) a,
      if (a != null && a['ringkasan'] is Map) Map<String, dynamic>.from(a['ringkasan'] as Map),
      if (widget.data['ringkasan'] is Map) Map<String, dynamic>.from(widget.data['ringkasan'] as Map),
    ];

    final hadir = _numOf(sources, ['kehadiranPersen', 'persenKehadiran']);
    final poin = _numOf(sources, ['poinPelanggaran', 'totalPoin', 'poin']);
    final izin = _numOf(sources, ['izinAktif', 'perizinanAktif', 'izinBerjalan']);
    final juz = _numOf(sources, ['juzTahfidz', 'hafalanJuz', 'totalJuz']);

    final menu = <Widget>[
      _MenuTile(
        icon: Icons.family_restroom,
        title: 'Profil Anak',
        subtitle: 'Biodata, nilai & hafalan',
        c1: _WD.primary,
        c2: _WD.primaryEnd,
        onTap: () => widget.onNavigate('Anak Saya'),
      ),
      _MenuTile(
        icon: Icons.gavel_outlined,
        title: 'Pelanggaran',
        subtitle: 'Poin & tindak lanjut',
        c1: _WD.gold,
        c2: _WD.goldDark,
        onTap: () => widget.onNavigate('Pelanggaran'),
      ),
      _MenuTile(
        icon: Icons.exit_to_app_rounded,
        title: 'Perizinan',
        subtitle: 'Izin keluar & pulang',
        c1: _WD.gold,
        c2: _WD.goldDark,
        onTap: () => widget.onNavigate('Perizinan'),
      ),
      _MenuTile(
        icon: Icons.emoji_events_outlined,
        title: 'Karakter',
        subtitle: 'Catatan pembinaan',
        c1: _WD.primary,
        c2: _WD.primaryEnd,
        onTap: () => widget.onNavigate('Pembinaan Karakter'),
      ),
      _MenuTile(
        icon: Icons.mosque_outlined,
        title: 'Pembinaan Ibadah',
        subtitle: 'Rekap ibadah harian santri',
        c1: _WD.primary,
        c2: _WD.primaryEnd,
        onTap: () => widget.onNavigate('Pembinaan Ibadah'),
      ),
    ];

    final menuRows = <Widget>[];
    for (int i = 0; i < menu.length; i += 2) {
      if (i > 0) menuRows.add(const SizedBox(height: 10));
      if (i + 1 < menu.length) {
        menuRows.add(_pairRow(menu[i], menu[i + 1]));
      } else {
        menuRows.add(menu[i]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Anak Saya', trailing: anak.length > 1 ? 'Pilih santri' : null),
        const SizedBox(height: 12),
        if (a == null)
          _emptyAnak()
        else ...[
          if (anak.length > 1) ...[
            _childSelector(anak),
            const SizedBox(height: 12),
          ],
          _childCard(a),
        ],
        const SizedBox(height: 26),
        _title('Capaian & Ringkasan', trailing: 'Terkini'),
        const SizedBox(height: 12),
        _pairRow(
          _RingCard(
            icon: Icons.fact_check_outlined,
            label: 'Kehadiran',
            center: hadir != null ? '${hadir.round()}%' : '—',
            centerUnit: null,
            progress: hadir != null ? (hadir / 100).clamp(0.0, 1.0).toDouble() : 0,
            color: _WD.primary,
            caption: hadir != null ? 'Rata-rata kehadiran' : 'Belum ada data',
            onTap: () => widget.onNavigate('Anak Saya'),
          ),
          _RingCard(
            icon: Icons.auto_stories_outlined,
            label: 'Tahfidz',
            center: juz != null ? '${juz.round()}' : '—',
            centerUnit: juz != null ? 'dari 30 juz' : null,
            progress: juz != null ? (juz / 30).clamp(0.0, 1.0).toDouble() : 0,
            color: _WD.gold,
            caption: juz != null ? 'Capaian hafalan' : 'Belum ada data',
            onTap: () => widget.onNavigate('Anak Saya'),
          ),
        ),
        const SizedBox(height: 10),
        _pairRow(
          _MiniStat(
            icon: Icons.gavel_outlined,
            label: 'Pelanggaran',
            value: poin != null ? '${poin.round()}' : null,
            unit: 'Poin',
            caption: (poin != null && poin == 0) ? 'Tidak ada poin' : 'Total poin pelanggaran',
            accent: (poin != null && poin > 0) ? _WD.dangerText : _WD.successText,
            onTap: () => widget.onNavigate('Pelanggaran'),
          ),
          _MiniStat(
            icon: Icons.exit_to_app_rounded,
            label: 'Perizinan',
            value: izin != null ? '${izin.round()}' : null,
            unit: 'Aktif',
            caption: 'Izin keluar / pulang',
            accent: _WD.gold,
            onTap: () => widget.onNavigate('Perizinan'),
          ),
        ),
        const SizedBox(height: 26),
        _title('Pantau Perkembangan', trailing: 'Hanya baca'),
        const SizedBox(height: 12),
        ...menuRows,
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _WD.goldSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _WD.goldBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: _WD.goldDark),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Akun wali bersifat baca saja. Perubahan data anak dilakukan oleh pihak pondok.',
                  style: TextStyle(fontSize: 11.5, color: _WD.goldDark, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Expanded(child: Divider(color: _WD.goldBorder)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.auto_awesome, size: 14, color: _WD.gold),
            ),
            Expanded(child: Divider(color: _WD.goldBorder)),
          ],
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: _WD.gold),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            '"Ya Tuhanku, anugerahkanlah kepadaku (anak) yang termasuk orang-orang yang saleh."',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _WD.inkSecondary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Potongan UI
// ---------------------------------------------------------------------------

/// Cincin progres melingkar.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.stroke != stroke;
}

class _RingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String center;
  final String? centerUnit;
  final double progress;
  final Color color;
  final String caption;
  final VoidCallback onTap;
  const _RingCard({
    required this.icon,
    required this.label,
    required this.center,
    required this.progress,
    required this.color,
    required this.caption,
    required this.onTap,
    this.centerUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _WD.border),
      ),
      child: Material(
        color: _WD.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _WD.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: _WD.inkSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(92, 92),
                        painter: _RingPainter(
                          progress: progress,
                          color: color,
                          track: _WD.surfaceDim,
                          stroke: 9,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: _WD.ink,
                            ),
                          ),
                          if (centerUnit != null)
                            Text(
                              centerUnit!,
                              style: const TextStyle(fontSize: 8.5, color: _WD.inkSecondary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: _WD.inkSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? unit;
  final String caption;
  final Color accent;
  final VoidCallback onTap;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
    required this.onTap,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WD.border),
      ),
      child: Material(
        color: _WD.surface,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 15, color: accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _WD.inkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value ?? '—',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _WD.ink,
                              ),
                            ),
                            if (value != null && unit != null) ...[
                              const SizedBox(width: 5),
                              Text(
                                unit!,
                                style: const TextStyle(fontSize: 11, color: _WD.inkSecondary),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value == null ? 'Belum ada data' : caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: _WD.inkSecondary),
                        ),
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
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c1,
    required this.c2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _WD.border),
      ),
      child: Material(
        color: _WD.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c1, c2],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c1.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _WD.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: _WD.inkSecondary,
                        ),
                      ),
                    ],
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