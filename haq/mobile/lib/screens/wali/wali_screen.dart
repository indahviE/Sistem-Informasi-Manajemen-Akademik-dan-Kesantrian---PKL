import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../signup_screen.dart' show PColors, PText;

class WaliScreen extends StatefulWidget {
  const WaliScreen({super.key});

  @override
  State<WaliScreen> createState() => _WaliScreenState();
}

class _WaliScreenState extends State<WaliScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _nilai = [];
  bool _loading = true;
  String? _error;
  String? _selectedSantriId;

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
      final d = await api.get(ApiUrl.waliMe);
      List<dynamic> n = [];
      final anak = (d['santris'] as List? ?? []);
      if (anak.isNotEmpty) {
        final sid = (anak.first as Map)['id'] as String;
        n = (await api.get(ApiUrl.nilai, query: {'santriId': sid, 'perPage': ''}) as List?) ?? [];
      }
      if (!mounted) return;
      setState(() {
        _data = d as Map<String, dynamic>;
        _nilai = n;
        _selectedSantriId = anak.isNotEmpty ? (anak.first as Map)['id'] as String : null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Terjadi kesalahan tak terduga: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _onSelectSantri(String id) async {
    try {
      final api = AppScope.of(context).api;
      final n = (await api.get(ApiUrl.nilai, query: {'santriId': id}) as List?) ?? [];
      if (mounted) {
        setState(() {
          _selectedSantriId = id;
          _nilai = n;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
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
                          : _data == null
                              ? emptyView('Akun belum terhubung ke data santri.')
                              : RefreshIndicator(
                                  color: PColors.primary,
                                  onRefresh: _load,
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                    children: [
                                      _SectionTitleRow(
                                        icon: Icons.family_restroom_outlined,
                                        title: 'Anak Anda',
                                      ),
                                      const SizedBox(height: 10),
                                      _PCard(
                                        children: [
                                          for (final a in (_data!['santris'] as List).cast<Map<String, dynamic>>())
                                            _SantriTile(
                                              nama: a['nama'] as String,
                                              nis: '${a['nis']}',
                                              kelas: (a['kelas'] as Map?)?['namaKelas']?.toString() ?? '-',
                                              selected: _selectedSantriId == a['id'],
                                              onTap: () => _onSelectSantri(a['id'] as String),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _SectionTitleRow(
                                        icon: Icons.grade_outlined,
                                        title: 'Nilai',
                                      ),
                                      const SizedBox(height: 10),
                                      _PCard(
                                        children: _nilai.isEmpty
                                            ? [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  child: Text(
                                                    'Belum ada nilai untuk santri ini.',
                                                    style: PText.bodyMd,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ]
                                            : [
                                                for (final n in _nilai)
                                                  _NilaiTile(
                                                    nilai: (n['nilai'] as num).toDouble(),
                                                    mapel: (n['mapel'] as Map?)?['namaMapel']?.toString() ?? '',
                                                    jenis: n['jenis']?.toString() ?? '',
                                                    tanggal: (n['tanggal'] as String).substring(0, 10),
                                                  ),
                                              ],
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

// ===========================================================================
// Themed building blocks (matches SignupScreen's design system)
// ===========================================================================

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: PColors.primary),
        const SizedBox(width: 8),
        Text(title, style: PText.headlineSm),
      ],
    );
  }
}

class _PCard extends StatelessWidget {
  const _PCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SantriTile extends StatelessWidget {
  const _SantriTile({
    required this.nama,
    required this.nis,
    required this.kelas,
    required this.selected,
    required this.onTap,
  });

  final String nama;
  final String nis;
  final String kelas;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? PColors.goldSurface : PColors.surfaceDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? PColors.gold : PColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? PColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? PColors.primary : PColors.inkSecondary,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: PText.labelLg.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text('$nis • $kelas', style: PText.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NilaiTile extends StatelessWidget {
  const _NilaiTile({
    required this.nilai,
    required this.mapel,
    required this.jenis,
    required this.tanggal,
  });

  final double nilai;
  final String mapel;
  final String jenis;
  final String tanggal;

  Color get _scoreColor {
    if (nilai >= 85) return PColors.successText;
    if (nilai >= 70) return PColors.pendingText;
    return PColors.errorText;
  }

  Color get _scoreBg {
    if (nilai >= 85) return PColors.successBg;
    if (nilai >= 70) return PColors.pendingBg;
    return PColors.errorBg;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _scoreBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              nilai.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _scoreColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mapel, style: PText.labelLg.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('$jenis • $tanggal', style: PText.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}