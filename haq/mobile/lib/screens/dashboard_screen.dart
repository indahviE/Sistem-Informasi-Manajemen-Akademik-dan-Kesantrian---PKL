import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'ui_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _data = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.dashboard);
      if (!mounted) return;
      setState(() => _data = res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat dashboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return errorView(_error!, _load);
    if (_data == null) return loadingView();
    final role = _data!['role'] as String;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const PageHeader(title: 'Ringkasan', subtitle: 'Pantau kondisi pondok secara real-time'),
          if (role == 'SUPER_ADMIN')
            _superBody()
          else if (role == 'WALI_SANTRI')
            _waliBody()
          else
            _tenantBody(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> cards) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1400 ? 6 : (w >= 1024 ? 4 : (w >= 600 ? 3 : 3));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: w >= 600 ? 2.1 : 1.8,
        children: cards,
      ),
    );
  }

  Widget _superBody() {
    final s = (_data!['statistik'] as Map).cast<String, dynamic>();
    final tenants = (_data!['tenantTerbaru'] as List? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          statCard(context, label: 'Total Tenant', value: '${s['totalTenant'] ?? 0}', icon: Icons.apartment, color: Tw.primary, softColor: Tw.primarySoft),
          statCard(context, label: 'Tenant Aktif', value: '${s['tenantAktif'] ?? 0}', icon: Icons.check_circle_outline, color: Tw.teal, softColor: Tw.tealSoft),
          statCard(context, label: 'Menunggu Persetujuan', value: '${s['tenantPending'] ?? 0}', icon: Icons.hourglass_top, color: Tw.amber, softColor: Tw.amberSoft),
          statCard(context, label: 'Total Santri', value: '${s['totalSantri'] ?? 0}', icon: Icons.groups, color: Tw.indigo, softColor: Tw.indigoSoft),
        ]),
        const SizedBox(height: 8),
        SectionCard(
          title: 'Tenant Terbaru',
          trailing: const Icon(Icons.chevron_right, color: Tw.gray400),
          children: tenants.isEmpty
              ? [const Text('Belum ada tenant.', style: TextStyle(color: Tw.gray500))]
              : [
                  for (final t in tenants.cast<Map<String, dynamic>>())
                    _tenantRow(context, t),
                ],
        ),
      ],
    );
  }

  Widget _tenantRow(BuildContext context, Map<String, dynamic> t) {
    final status = t['status'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Tw.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment, color: Tw.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['namaPondok'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Tw.gray900)),
                Text('${t['kodeTenant']} • Santri: ${(t['_count'] as Map)['santris'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Tw.gray500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (status == 'PENDING')
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              onPressed: () => _tenantAction(t, 'approve'),
              child: const Text('Setujui', style: TextStyle(fontSize: 13)),
            )
          else
            twBadge(context, status,
                color: status == 'AKTIF' ? Tw.teal : Tw.red,
                soft: status == 'AKTIF' ? Tw.tealSoft : Tw.redSoft),
        ],
      ),
    );
  }

  Future<void> _tenantAction(Map<String, dynamic> t, String action) async {
    try {
      final api = AppScope.of(context).api;
      await api.post(action == 'approve' ? ApiUrl.tenantApprove : ApiUrl.tenantSuspend,
          {'tenantId': t['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve'
            ? '${t['namaPondok']} telah diaktifkan.'
            : 'Tenant di-suspend.'),
      ));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _waliBody() {
    final s = (_data!['statistik'] as Map).cast<String, dynamic>();
    final anak = (_data!['anak'] as List? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          statCard(context, label: 'Jumlah Anak', value: '${s['jumlahAnak'] ?? 0}', icon: Icons.family_restroom, color: Tw.primary, softColor: Tw.primarySoft),
          statCard(context, label: 'Rata-rata Nilai', value: _fmt(s['rataRataNilai']), icon: Icons.grade, color: Tw.amber, softColor: Tw.amberSoft),
          statCard(context, label: 'Pelanggaran', value: '${s['pelanggaranTotal'] ?? 0}', icon: Icons.gavel, color: Tw.red, softColor: Tw.redSoft),
          statCard(context, label: 'Izin Menunggu', value: '${s['izinPending'] ?? 0}', icon: Icons.hourglass_top, color: Tw.teal, softColor: Tw.tealSoft),
        ]),
        const SizedBox(height: 8),
        SectionCard(
          title: 'Anak Anda',
          children: anak.isEmpty
              ? [const Text('Belum ada data anak.', style: TextStyle(color: Tw.gray500))]
              : [
                  for (final a in anak.cast<Map<String, dynamic>>())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Tw.skySoft, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.person, color: Tw.sky),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['nama'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Tw.gray900)),
                              Text('${a['nis']} • ${(a['kelas'] as Map?)?['namaKelas'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12, color: Tw.gray500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
        ),
      ],
    );
  }

  Widget _tenantBody() {
    final s = (_data!['statistik'] as Map).cast<String, dynamic>();
    final kelas = (_data!['distribusiKelas'] as List? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          statCard(context, label: 'Santri Aktif', value: '${s['santriAktif'] ?? 0}', icon: Icons.groups, color: Tw.primary, softColor: Tw.primarySoft),
          statCard(context, label: 'Hadir Hari Ini', value: '${s['hadirHariIni'] ?? 0}', icon: Icons.check_circle_outline, color: Tw.teal, softColor: Tw.tealSoft),
          statCard(context, label: 'Pelanggaran Minggu 7', value: '${s['pelanggaranMingguIni'] ?? 0}', icon: Icons.gavel, color: Tw.red, softColor: Tw.redSoft),
          statCard(context, label: 'Izin Menunggu', value: '${s['izinPending'] ?? 0}', icon: Icons.hourglass_top, color: Tw.amber, softColor: Tw.amberSoft),
          statCard(context, label: 'Kelas', value: '${s['totalKelas'] ?? 0}', icon: Icons.class_, color: Tw.indigo, softColor: Tw.indigoSoft),
          statCard(context, label: 'Santri Sakit', value: '${s['santriSakit'] ?? 0}', icon: Icons.medical_services, color: Tw.sky, softColor: Tw.skySoft),
        ]),
        const SizedBox(height: 8),
        SectionCard(
          title: 'Distribusi Santri per Kelas',
          children: kelas.isEmpty
              ? [const Text('Belum ada kelas.', style: TextStyle(color: Tw.gray500))]
              : [
                  for (final k in kelas.cast<Map<String, dynamic>>())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${k['namaKelas']}', style: const TextStyle(color: Tw.gray800)),
                          ),
                          Text('${(k['_count'] as Map)['santris'] ?? 0} santri',
                              style: const TextStyle(color: Tw.gray500, fontSize: 12.5)),
                        ],
                      ),
                    ),
                ],
        ),
      ],
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final n = (v as num).toDouble();
    return n.toStringAsFixed(1);
  }
}