// ppdb_form_screen.dart
//
// Formulir PPDB Online — mengikuti desain baru (hero banner, gerbang kode
// PPDB, step indicator 4 langkah). Menggunakan PColors & PText yang sama
// dengan signup_screen.dart supaya konsisten secara visual.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../signup_screen.dart'; // reuse PColors & PText

// ============================================================================
// Data models lokal
// ============================================================================

class _JenjangOption {
  const _JenjangOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

const List<_JenjangOption> _kJenjangOptions = [
  _JenjangOption(
    id: 'ibtidaiyah',
    label: 'Marhalah Ibtidaiyah',
    subtitle: 'Setingkat MI / SD Tahfidz Al-Qur\'an',
    icon: Icons.auto_stories_outlined,
  ),
  _JenjangOption(
    id: 'mutawassithah',
    label: 'Marhalah Mutawassithah',
    subtitle: 'Setingkat MTs / SMP Tahfidz Al-Qur\'an 30 Juz',
    icon: Icons.school_outlined,
  ),
  _JenjangOption(
    id: 'aliyah',
    label: 'Marhalah Aliyah',
    subtitle: 'Setingkat MA / SMA Tahfidz Al-Qur\'an',
    icon: Icons.account_balance_outlined,
  ),
];

class _TenantInfo {
  const _TenantInfo({
    required this.namaPondok,
    required this.alamat,
    required this.sisaKuota,
    required this.gelombangLabel,
    required this.gelombangDibuka,
  });

  final String namaPondok;
  final String alamat;
  final int? sisaKuota;
  final String gelombangLabel;
  final bool gelombangDibuka;

  factory _TenantInfo.fromJson(Map<String, dynamic> j) {
    final gelombang = (j['gelombang'] as Map<String, dynamic>?) ?? const {};
    final status = (gelombang['status'] as String?)?.toUpperCase() ?? 'DIBUKA';
    final sisaKuota = gelombang['sisaKuota'];

    return _TenantInfo(
      namaPondok: (j['namaPondok'] as String?)?.trim().isNotEmpty == true
          ? j['namaPondok'] as String
          : '-',
      alamat: (j['alamat'] as String?) ?? '',
      sisaKuota: sisaKuota is int ? sisaKuota : int.tryParse('$sisaKuota'),
      gelombangLabel: 'Gelombang 1',
      gelombangDibuka: status == 'DIBUKA',
    );
  }
}

const List<String> _kStepTitles = ['Santri', 'Wali', 'Berkas', 'Kirim'];

// ============================================================================
// PpdbFormScreen
// ============================================================================

class PpdbFormScreen extends StatefulWidget {
  const PpdbFormScreen({super.key});

  @override
  State<PpdbFormScreen> createState() => _PpdbFormScreenState();
}

class _PpdbFormScreenState extends State<PpdbFormScreen> {
  // --- Gerbang Kode PPDB ---
  // TODO: ganti nilai awal & validasi dengan hasil GET /api/ppdb/lookup?kode=...
  final _kode = TextEditingController(text: 'mahad-alquran');
  bool _kodeValid = false;
  bool _checkingKode = false;
  _TenantInfo? _tenantInfo;
  int _heroTab = 0;

  // --- Step 0: Data Calon Santri ---
  final _namaCalon = TextEditingController();
  final _nisn = TextEditingController();
  final _tempatLahir = TextEditingController();
  final _tglLahir = TextEditingController();
  final _asalSekolah = TextEditingController();
  String _jenisKelamin = 'L';
  String _jenjang = 'mutawassithah';

  // --- Step 1: Data Wali ---
  final _namaWali = TextEditingController();
  final _noHpWali = TextEditingController();
  final _emailWali = TextEditingController();
  final _alamatWali = TextEditingController();

  // --- Step 2: Berkas (placeholder nama/link berkas) ---
  final _fotoAnak = TextEditingController();
  final _kartuKeluarga = TextEditingController();
  final _aktaLahir = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  String? _sukses;

  @override
  void dispose() {
    _kode.dispose();
    _namaCalon.dispose();
    _nisn.dispose();
    _tempatLahir.dispose();
    _tglLahir.dispose();
    _asalSekolah.dispose();
    _namaWali.dispose();
    _noHpWali.dispose();
    _emailWali.dispose();
    _alamatWali.dispose();
    _fotoAnak.dispose();
    _kartuKeluarga.dispose();
    _aktaLahir.dispose();
    super.dispose();
  }

  Future<void> _cekKode() async {
    final kode = _kode.text.trim();
    if (kode.isEmpty) return;

    setState(() {
      _checkingKode = true;
      _error = null;
    });

    try {
      final res = await AppScope.of(context).api.get(
            ApiUrl.ppdbLookup,
            query: {'kode': kode},
            auth: false,
          );
      if (!mounted) return;
      final data = res as Map<String, dynamic>;
      setState(() {
        _tenantInfo = _TenantInfo.fromJson(data);
        _kodeValid = true;
        _checkingKode = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _kodeValid = false;
        _tenantInfo = null;
        _checkingKode = false;
        _error = e.statusCode == 404
            ? 'Kode Registrasi PPDB tidak ditemukan. Periksa kembali kode Anda.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kodeValid = false;
        _tenantInfo = null;
        _checkingKode = false;
        _error = 'Gagal memeriksa kode. Periksa koneksi Anda.';
      });
    }
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      setState(() => _tglLahir.text = '$dd/$mm/${picked.year}');
    }
  }

  bool _validateStep0() {
    if (_namaCalon.text.trim().isEmpty) {
      setState(() => _error = 'Nama lengkap ananda wajib diisi.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateStep1() {
    if (_namaWali.text.trim().isEmpty || _noHpWali.text.trim().isEmpty) {
      setState(() => _error = 'Nama dan No. HP wali wajib diisi.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  void _goNext() {
    if (!_kodeValid) {
      setState(() => _error = 'Periksa Kode Registrasi PPDB terlebih dahulu.');
      return;
    }
    if (_step == 0 && !_validateStep0()) return;
    if (_step == 1 && !_validateStep1()) return;
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _error = null;
        _step -= 1;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.postPublic(ApiUrl.ppdbDaftar, {
        'kodeTenant': _kode.text.trim(),
        'nama': _namaCalon.text.trim(),
        'jenisKelamin': _jenisKelamin,
        'nisn': _nisn.text.trim().isEmpty ? null : _nisn.text.trim(),
        'tempatLahir':
            _tempatLahir.text.trim().isEmpty ? null : _tempatLahir.text.trim(),
        'tanggalLahir': _tglLahir.text.trim().isEmpty ? null : _tglLahir.text.trim(),
        'asalSekolah':
            _asalSekolah.text.trim().isEmpty ? null : _asalSekolah.text.trim(),
        'jenjang': _jenjang,
        'namaWali': _namaWali.text.trim(),
        'noHp': _noHpWali.text.trim(),
        'email': _emailWali.text.trim().isEmpty ? null : _emailWali.text.trim(),
        'alamat': _alamatWali.text.trim().isEmpty ? null : _alamatWali.text.trim(),
      });
      if (!mounted) return;
      final m = res as Map<String, dynamic>;
      setState(() {
        _submitted = true;
        _sukses =
            '${m['message'] ?? 'Pendaftaran berhasil dikirim.'} ${m['noPendaftaran'] ?? ''}';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengirim pendaftaran. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                _PpdbHeader(onBack: _goBack),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroBanner(
                          activeTab: _heroTab,
                          onTabChanged: (i) => setState(() => _heroTab = i),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _KodeGateCard(
                                controller: _kode,
                                valid: _kodeValid,
                                checking: _checkingKode,
                                tenantInfo: _tenantInfo,
                                onCek: _cekKode,
                              ),
                              const SizedBox(height: 16),
                              _StepIndicator(step: _step),
                              const SizedBox(height: 16),
                              if (_submitted)
                                _SuksesCard(
                                  message: _sukses ?? 'Pendaftaran terkirim.',
                                  onReset: () => setState(() {
                                    _submitted = false;
                                    _sukses = null;
                                    _step = 0;
                                  }),
                                )
                              else ...[
                                if (_step == 0) _buildStepSantri(),
                                if (_step == 1) _buildStepWali(),
                                if (_step == 2) _buildStepBerkas(),
                                if (_step == 3) _buildStepKirim(),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  _MessageBanner(text: _error!),
                                ],
                                const SizedBox(height: 16),
                                _PrimaryButton(
                                  label: _step < 3 ? _nextLabel() : 'Kirim Pendaftaran',
                                  loading: _loading,
                                  showArrow: _step < 3,
                                  onPressed: _goNext,
                                ),
                              ],
                              const SizedBox(height: 20),
                              const _PpdbFooter(),
                            ],
                          ),
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

  String _nextLabel() {
    switch (_step) {
      case 0:
        return 'Lanjut ke Data Wali';
      case 1:
        return 'Lanjut ke Berkas';
      default:
        return 'Lanjut ke Ringkasan';
    }
  }

  // ---------------------------------------------------------------------
  // STEP 0 — Data Calon Santri
  // ---------------------------------------------------------------------
  Widget _buildStepSantri() {
    return _PCard(
      children: [
        Row(
          children: [
            Expanded(child: Text('Data Calon Santri', style: PText.headlineSm)),
            Text('Langkah 1 dari 4', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 16),
        Text('Nama Lengkap Ananda', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(
          controller: _namaCalon,
          hint: 'Nama lengkap sesuai akta kelahiran',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NISN (10 Digit)', style: PText.labelLg),
                  const SizedBox(height: 8),
                  _PInput(
                    controller: _nisn,
                    hint: '01xxxxxxxx',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tempat Lahir', style: PText.labelLg),
                  const SizedBox(height: 8),
                  _PInput(controller: _tempatLahir, hint: 'Jakarta'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Tanggal Lahir', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(
          controller: _tglLahir,
          hint: 'DD/MM/YYYY',
          readOnly: true,
          onTap: _pickTanggalLahir,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                size: 18, color: PColors.inkSecondary),
            onPressed: _pickTanggalLahir,
          ),
        ),
        const SizedBox(height: 16),
        Text('Jenis Kelamin', style: PText.labelLg),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderTile(
                icon: Icons.male,
                label: 'Ikhwan (Putra)',
                selected: _jenisKelamin == 'L',
                onTap: () => setState(() => _jenisKelamin = 'L'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GenderTile(
                icon: Icons.female,
                label: 'Akhwat (Putri)',
                selected: _jenisKelamin == 'P',
                onTap: () => setState(() => _jenisKelamin = 'P'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Asal Sekolah / Madrasah', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(controller: _asalSekolah, hint: 'SDIT Ibnu Abbas'),
        const SizedBox(height: 16),
        Text('Pilihan Jenjang & Peminatan', style: PText.labelLg),
        const SizedBox(height: 8),
        _JenjangSelector(
          selectedId: _jenjang,
          onSelect: (id) => setState(() => _jenjang = id),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 1 — Data Wali
  // ---------------------------------------------------------------------
  Widget _buildStepWali() {
    return _PCard(
      children: [
        Row(
          children: [
            Expanded(child: Text('Data Wali Santri', style: PText.headlineSm)),
            Text('Langkah 2 dari 4', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 16),
        Text('Nama Lengkap Ayah/Bunda/Wali', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(
          controller: _namaWali,
          hint: 'Nama lengkap wali santri',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        Text('No. HP / WhatsApp Aktif', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(
          controller: _noHpWali,
          hint: '08xx-xxxx-xxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Text('Email (opsional)', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(
          controller: _emailWali,
          hint: 'wali@email.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Text('Alamat Domisili', style: PText.labelLg),
        const SizedBox(height: 8),
        _PInput(controller: _alamatWali, hint: 'Alamat lengkap domisili wali', maxLines: 2),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 2 — Berkas
  // ---------------------------------------------------------------------
  Widget _buildStepBerkas() {
    return _PCard(
      children: [
        Row(
          children: [
            Expanded(child: Text('Unggah Berkas', style: PText.headlineSm)),
            Text('Langkah 3 dari 4', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 6),
        Text('Format PNG/JPG/PDF, maksimal 2MB per berkas.', style: PText.bodySm),
        const SizedBox(height: 16),
        _UploadTile(
          title: 'Pas Foto Ananda',
          controller: _fotoAnak,
          kind: _BerkasKind.photoOnly,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          title: 'Kartu Keluarga',
          controller: _kartuKeluarga,
          kind: _BerkasKind.documentOnly,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          title: 'Akta Kelahiran',
          controller: _aktaLahir,
          kind: _BerkasKind.documentOnly,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 3 — Ringkasan & Kirim
  // ---------------------------------------------------------------------
  Widget _buildStepKirim() {
    final jenjang = _kJenjangOptions.firstWhere((j) => j.id == _jenjang);
    return _PCard(
      children: [
        Row(
          children: [
            Expanded(child: Text('Ringkasan Pendaftaran', style: PText.headlineSm)),
            Text('Langkah 4 dari 4', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 16),
        Text('Data Calon Santri', style: PText.labelLg),
        const SizedBox(height: 10),
        _SummaryRow('Nama Ananda', _namaCalon.text.trim()),
        _SummaryRow('NISN', _nisn.text.trim()),
        _SummaryRow(
            'Tempat, Tgl Lahir', '${_tempatLahir.text.trim()}, ${_tglLahir.text.trim()}'),
        _SummaryRow(
            'Jenis Kelamin', _jenisKelamin == 'L' ? 'Ikhwan (Putra)' : 'Akhwat (Putri)'),
        _SummaryRow('Asal Sekolah', _asalSekolah.text.trim()),
        _SummaryRow('Jenjang', jenjang.label),
        const SizedBox(height: 16),
        Divider(color: PColors.border, height: 1),
        const SizedBox(height: 16),
        Text('Data Wali', style: PText.labelLg),
        const SizedBox(height: 10),
        _SummaryRow('Nama Wali', _namaWali.text.trim()),
        _SummaryRow('No. HP', _noHpWali.text.trim()),
        _SummaryRow('Email', _emailWali.text.trim()),
        _SummaryRow('Alamat', _alamatWali.text.trim()),
        const SizedBox(height: 16),
        _MessageBanner(
          text: 'Pastikan seluruh data sudah benar sebelum mengirim pendaftaran.',
          bg: PColors.pendingBg,
          fg: PColors.pendingText,
          border: PColors.pendingBorder,
        ),
      ],
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _PpdbHeader extends StatelessWidget {
  const _PpdbHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.chevron_left, color: PColors.ink, size: 26),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMPesantren',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                    color: PColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Informasi Institusi', style: PText.bodySm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PColors.mint,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'Registrasi Tenant Baru',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: PColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.help_outline, color: PColors.inkSecondary, size: 22),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Hero banner
// ============================================================================

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.activeTab, required this.onTabChanged});

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PColors.primary, PColors.primaryGradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Tahun Ajaran 1446-1447 H / 2025-2026 M',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Penerimaan Santri Baru',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 30 / 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bismillah. Ahlan wa Sahlan Ayah & Bunda. Mari bersama membina "
            "generasi penghafal Al-Qur'an yang beradab dan berwawasan luas.",
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              height: 19 / 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroTab(
                  icon: Icons.description_outlined,
                  label: 'Formulir PPDB',
                  selected: activeTab == 0,
                  onTap: () => onTabChanged(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroTab(
                  icon: Icons.verified_outlined,
                  label: 'Status & Kelulusan',
                  selected: activeTab == 1,
                  onTap: () => onTabChanged(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTab extends StatelessWidget {
  const _HeroTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? PColors.primary : Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? PColors.primary : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Gerbang Kode PPDB
// ============================================================================

class _KodeGateCard extends StatelessWidget {
  const _KodeGateCard({
    required this.controller,
    required this.valid,
    required this.checking,
    required this.tenantInfo,
    required this.onCek,
  });

  final TextEditingController controller;
  final bool valid;
  final bool checking;
  final _TenantInfo? tenantInfo;
  final VoidCallback onCek;

  @override
  Widget build(BuildContext context) {
    return _PCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: PColors.goldSurface, shape: BoxShape.circle),
              child: const Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: PColors.gold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Gerbang Kode PPDB', style: PText.headlineSm)),
            const _PPill(
              label: 'Wajib',
              bg: PColors.pendingBg,
              fg: PColors.pendingText,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Masukkan kode registrasi resmi pondok pesantren yang tercantum pada '
          'brosur pendaftaran untuk memvalidasi gelombang kuota santri.',
          style: PText.bodyMd,
        ),
        const SizedBox(height: 16),
        Text('Kode Registrasi PPDB', style: PText.labelLg),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: PColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PColors.inputBorder),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PColors.ink,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'mis. mahad-alquran',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: checking ? null : onCek,
                style: FilledButton.styleFrom(
                  backgroundColor: PColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: checking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Periksa',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (valid && tenantInfo != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PColors.successBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: PColors.successText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kode Valid & Terhubung',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PColors.successText,
                    ),
                  ),
                ),
                _PPill(
                  label: '${tenantInfo!.gelombangLabel}: '
                      '${tenantInfo!.gelombangDibuka ? "Dibuka" : "Ditutup"}',
                  bg: PColors.successBg,
                  fg: PColors.successText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantInfo!.namaPondok,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PText.labelLg,
                    ),
                    const SizedBox(height: 2),
                    Text(tenantInfo!.alamat, style: PText.bodySm),
                    const SizedBox(height: 2),
                    Text(
                      tenantInfo!.sisaKuota != null
                          ? 'Sisa Kuota: ${tenantInfo!.sisaKuota} Santri (Ikhwan & Akhwat)'
                          : 'Sisa kuota tidak tersedia',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PColors.successText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.help_outline, size: 14, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            Text('Simulasi kode keliru / kedaluwarsa?', style: PText.bodySm),
            const Spacer(),
            const Icon(Icons.support_agent_outlined, size: 14, color: PColors.primary),
            const SizedBox(width: 4),
            Text(
              'Tanya Panitia',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Step indicator
// ============================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_kStepTitles.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftDone = (i - 1) ~/ 2 < step;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: leftDone ? PColors.primary : PColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final active = idx == step;
        final done = idx < step;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (active || done) ? PColors.primary : PColors.surfaceDim,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: active ? Colors.white : PColors.inkSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                _kStepTitles[idx],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? PColors.ink : PColors.inkSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ============================================================================
// Gender tile & jenjang selector
// ============================================================================

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? PColors.primary : PColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? PColors.primary : PColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : PColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : PColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JenjangSelector extends StatelessWidget {
  const _JenjangSelector({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<String> onSelect;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pilih Jenjang & Peminatan', style: PText.headlineSm),
                const SizedBox(height: 12),
                ..._kJenjangOptions.map((opt) {
                  final selected = opt.id == selectedId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, opt.id),
                      child: _JenjangTile(option: opt, selected: selected),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) onSelect(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _kJenjangOptions.firstWhere((j) => j.id == selectedId);
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: _JenjangTile(option: selected, selected: false, showChevron: true),
    );
  }
}

class _JenjangTile extends StatelessWidget {
  const _JenjangTile({
    required this.option,
    required this.selected,
    this.showChevron = false,
  });

  final _JenjangOption option;
  final bool selected;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? PColors.sage : PColors.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? PColors.primary : PColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.label, style: PText.labelLg),
                const SizedBox(height: 2),
                Text(option.subtitle, style: PText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(option.icon, color: PColors.primary),
          if (showChevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: PColors.inkSecondary),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Upload tile (step Berkas)
// ============================================================================

/// Jenis berkas yang boleh diambil untuk tile ini.
/// - photoOnly: hanya kamera/galeri (untuk Pas Foto)
/// - documentOnly: file picker untuk PDF/JPG/PNG (untuk KK, Akta, dsb.)
enum _BerkasKind { photoOnly, documentOnly }

class _UploadTile extends StatefulWidget {
  const _UploadTile({
    required this.title,
    required this.controller,
    this.kind = _BerkasKind.documentOnly,
  });

  final String title;
  final TextEditingController controller;
  final _BerkasKind kind;

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile> {
  bool _uploading = false;
  String? _fileNameLocal;

  // TODO: sesuaikan dengan endpoint upload backend yang sebenarnya.
  // Belum ada endpoint upload publik untuk PPDB di backend saat ini —
  // perlu ditambahkan di NestJS, mis. @Public() POST /api/ppdb/upload,
  // menerima multipart/form-data field "file", membalas { "url": "..." }.
  static const String _uploadEndpoint = 'http://localhost:3000/api/ppdb/upload';

  Future<void> _showSourceSheet() async {
    if (widget.kind == _BerkasKind.photoOnly) {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: PColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: PColors.primary),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: PColors.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
      final xfile = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (xfile == null) return;
      await _uploadFile(File(xfile.path), xfile.name);
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.single.path == null) return;
      await _uploadFile(File(result.files.single.path!), result.files.single.name);
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    final sizeBytes = await file.length();
    if (sizeBytes > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran berkas maksimal 2MB.')),
        );
      }
      return;
    }

    setState(() {
      _uploading = true;
      _fileNameLocal = fileName;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final match = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(res.body);
        final url = match?.group(1) ?? '';
        if (!mounted) return;
        setState(() {
          widget.controller.text = url;
          _uploading = false;
        });
      } else {
        throw Exception('Upload gagal (${res.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _fileNameLocal = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah berkas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.controller.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: _uploading ? null : _showSourceSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PColors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: PColors.sage, shape: BoxShape.circle),
              child: _uploading
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2, color: PColors.primary),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18, color: PColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: PText.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    _uploading
                        ? 'Mengunggah...'
                        : hasFile
                            ? (_fileNameLocal ?? 'Berkas siap')
                            : 'Klik untuk unggah',
                    style: PText.bodySm.copyWith(
                      color: hasFile ? PColors.successText : PColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!_uploading)
              Icon(
                hasFile ? Icons.check_circle : Icons.chevron_right,
                color: hasFile ? PColors.successText : PColors.inkSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shared low-level widgets
// ============================================================================

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
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _PInput extends StatelessWidget {
  const _PInput({
    required this.controller,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: PText.bodyMd.copyWith(color: PColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PText.bodyMd,
        prefixIcon: icon == null ? null : Icon(icon, color: PColors.inkSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: PColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}

class _PPill extends StatelessWidget {
  const _PPill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: PText.bodySm)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    this.bg = PColors.errorBg,
    this.fg = PColors.errorText,
    this.border = PColors.errorBorder,
  });

  final String text;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(text, style: PText.bodyMd.copyWith(color: fg)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.showArrow = true,
  });

  final String label;
  final bool loading;
  final bool showArrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PColors.gold,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: PColors.gold),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SuksesCard extends StatelessWidget {
  const _SuksesCard({required this.message, required this.onReset});

  final String message;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _PCard(
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, color: PColors.successText, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onReset,
                style: FilledButton.styleFrom(
                  backgroundColor: PColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text(
                  'Daftarkan Santri Lain',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PColors.gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Footer
// ============================================================================

class _PpdbFooter extends StatelessWidget {
  const _PpdbFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sistem Informasi Manajemen Pesantren (SIMPesantren)',
          textAlign: TextAlign.center,
          style: PText.bodySm,
        ),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: PText.bodySm,
            children: [
              const TextSpan(
                text: 'Butuh panduan teknis pendaftaran? Hubungi Call Center Layanan '
                    'Wali Santri di ',
              ),
              TextSpan(
                text: '0812-8800-4321.',
                style: PText.bodySm.copyWith(fontWeight: FontWeight.w700, color: PColors.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}