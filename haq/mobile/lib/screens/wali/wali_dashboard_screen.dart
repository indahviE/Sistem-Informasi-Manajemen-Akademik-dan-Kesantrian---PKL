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

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------
class WaliHero extends StatelessWidget {
  final Map<String, dynamic> data;
  const WaliHero({super.key, required this.data});

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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _WD.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
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
              decoration: BoxDecoration(color: _WD.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _WD.gold.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 12, color: _WD.gold),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'PORTAL WALI SANTRI',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: _WD.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Mode Pantau',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text("Assalamu'alaikum,",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(nama, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _tanggalIndo(DateTime.now()),
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                    if (jumlahAnak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _WD.mint, borderRadius: BorderRadius.circular(999)),
                        child: Text('$jumlahAnak Anak',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _WD.primary)),
                      ),
                  ],
                ),
                if (pondok != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.mosque_outlined, size: 13, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(pondok,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.7))),
                      ),
                    ],
                  ),
                ],
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

  Widget _title(String t, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WD.ink)),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11.5, color: _WD.inkSecondary)),
      ],
    );
  }

  Widget _twoCol(List<Widget> c) {
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 10),
              Expanded(child: b),
            ],
          ),
        );
    return Column(
      children: [
        row(c[0], c[1]),
        const SizedBox(height: 10),
        row(c[2], c[3]),
      ],
    );
  }

  Widget _emptyAnak() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _WD.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WD.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: _WD.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.family_restroom, color: _WD.gold, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Belum ada santri yang terhubung',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WD.ink)),
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
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: anak.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _sel;
          final nama = (anak[i]['nama'] as String?)?.trim();
          return GestureDetector(
            onTap: () => setState(() => _sel = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _WD.primary : _WD.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _WD.primary : _WD.border),
              ),
              child: Text(
                (nama == null || nama.isEmpty) ? 'Santri ${i + 1}' : nama.split(' ').first,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _WD.inkSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _childCard(Map<String, dynamic> a) {
    final nama = (a['nama'] as String?) ?? 'Santri';
    final nis = (a['nis'] as String?) ?? '-';
    final status = _kapital(_str(a, ['status']) ?? 'Aktif');
    final aktif = status.toLowerCase() == 'aktif';
    final inisial = nama.trim().isNotEmpty ? nama.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _WD.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WD.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _WD.sage, shape: BoxShape.circle),
            child: Text(inisial,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _WD.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _WD.ink)),
                const SizedBox(height: 2),
                Text('${_kelasOf(a)} • NIS: $nis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: _WD.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: aktif ? _WD.successBg : _WD.pendingBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: aktif ? _WD.successText : _WD.pendingText,
                )),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Anak Saya', trailing: anak.length > 1 ? 'Pilih santri' : _tanggalIndo(DateTime.now())),
        const SizedBox(height: 10),
        if (a == null)
          _emptyAnak()
        else ...[
          if (anak.length > 1) ...[
            _childSelector(anak),
            const SizedBox(height: 10),
          ],
          _childCard(a),
        ],
        const SizedBox(height: 22),
        _title('Ringkasan', trailing: 'Perkembangan terkini'),
        const SizedBox(height: 10),
        _twoCol([
          _StatTile(
            icon: Icons.fact_check_outlined,
            label: 'Kehadiran',
            value: hadir != null ? '${hadir.round()}%' : null,
            caption: 'Rata-rata kehadiran',
            iconBg: _WD.sage,
            iconFg: _WD.primary,
            onTap: () => widget.onNavigate('Anak Saya'),
          ),
          _StatTile(
            icon: Icons.gavel_outlined,
            label: 'Pelanggaran',
            value: poin != null ? '${poin.round()}' : null,
            unit: 'Poin',
            caption: (poin != null && poin == 0) ? 'Tidak ada poin' : 'Total poin pelanggaran',
            iconBg: _WD.goldSurface,
            iconFg: _WD.gold,
            onTap: () => widget.onNavigate('Pelanggaran'),
          ),
          _StatTile(
            icon: Icons.exit_to_app_rounded,
            label: 'Perizinan',
            value: izin != null ? '${izin.round()}' : null,
            unit: 'Aktif',
            caption: 'Izin keluar / pulang',
            iconBg: _WD.goldSurface,
            iconFg: _WD.gold,
            onTap: () => widget.onNavigate('Perizinan'),
          ),
          _StatTile(
            icon: Icons.auto_stories_outlined,
            label: 'Tahfidz',
            value: juz != null ? '${juz.round()}' : null,
            unit: 'Juz',
            caption: 'Capaian hafalan',
            iconBg: _WD.sage,
            iconFg: _WD.primary,
            onTap: () => widget.onNavigate('Anak Saya'),
          ),
        ]),
        const SizedBox(height: 22),
        _title('Pantau Perkembangan', trailing: 'Hanya baca'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _WD.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _WD.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _MenuRow(
                icon: Icons.family_restroom,
                title: 'Data & Profil Anak',
                subtitle: 'Biodata, kelas, nilai, dan hafalan',
                onTap: () => widget.onNavigate('Anak Saya'),
              ),
              const Divider(height: 1, color: _WD.border),
              _MenuRow(
                icon: Icons.gavel_outlined,
                title: 'Pelanggaran & Poin',
                subtitle: 'Riwayat pelanggaran dan tindak lanjut',
                onTap: () => widget.onNavigate('Pelanggaran'),
              ),
              const Divider(height: 1, color: _WD.border),
              _MenuRow(
                icon: Icons.exit_to_app_rounded,
                title: 'Perizinan & Kepulangan',
                subtitle: 'Status izin keluar dan pulang',
                onTap: () => widget.onNavigate('Perizinan'),
              ),
              const Divider(height: 1, color: _WD.border),
              _MenuRow(
                icon: Icons.emoji_events_outlined,
                title: 'Pembinaan Karakter',
                subtitle: 'Catatan pembinaan dari pembina',
                onTap: () => widget.onNavigate('Pembinaan Karakter'),
              ),
              const Divider(height: 1, color: _WD.border),
              _MenuRow(
                icon: Icons.mosque_outlined,
                title: 'Pembinaan Ibadah',
                subtitle: 'Rekap ibadah harian santri',
                onTap: () => widget.onNavigate('Pembinaan Ibadah'),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _WD.gold),
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
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? unit;
  final String caption;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _WD.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _WD.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, size: 16, color: iconFg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: _WD.inkSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value ?? '—',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _WD.ink)),
                  if (value != null && unit != null) ...[
                    const SizedBox(width: 5),
                    Text(unit!, style: const TextStyle(fontSize: 11.5, color: _WD.inkSecondary)),
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
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _WD.sage, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: _WD.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _WD.ink)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: _WD.inkSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _WD.inkSecondary),
          ],
        ),
      ),
    );
  }
}