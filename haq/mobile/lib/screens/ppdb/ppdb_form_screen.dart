// ppdb_form_screen.dart
//
// Formulir Pendaftaran Santri Baru (PPDB Online).
// Alur: Pondok (kode) -> Santri -> Wali -> Berkas -> Kirim.
// Khusus pendaftaran: tanpa tab status & kelulusan.
// Memakai PColors & PText dari signup_screen.dart supaya tema tetap hijau.

import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../signup_screen.dart'; // reuse PColors & PText

// ============================================================================
// Data lokal
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
    required this.gelombangDibuka,
  });

  final String namaPondok;
  final String alamat;
  final int? sisaKuota;
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
      gelombangDibuka: status == 'DIBUKA',
    );
  }
}

class _StepDef {
  const _StepDef(this.title, this.icon);
  final String title;
  final IconData icon;
}

const List<_StepDef> _kSteps = [
  _StepDef('Pondok', Icons.mosque_outlined),
  _StepDef('Santri', Icons.person_outline),
  _StepDef('Wali', Icons.family_restroom_outlined),
  _StepDef('Berkas', Icons.folder_outlined),
  _StepDef('Kirim', Icons.send_outlined),
];

// ============================================================================
// PpdbFormScreen
// ============================================================================

class PpdbFormScreen extends StatefulWidget {
  const PpdbFormScreen({super.key});

  @override
  State<PpdbFormScreen> createState() => _PpdbFormScreenState();
}

class _PpdbFormScreenState extends State<PpdbFormScreen> {
  final _scroll = ScrollController();

  // --- Step 0: Pondok ---
  final _kode = TextEditingController();
  bool _kodeValid = false;
  bool _checkingKode = false;
  _TenantInfo? _tenantInfo;

  // --- Step 1: Calon santri ---
  final _namaCalon = TextEditingController();
  final _nisn = TextEditingController();
  final _tempatLahir = TextEditingController();
  final _tglLahir = TextEditingController();
  final _asalSekolah = TextEditingController();
  String? _tglLahirIso; // YYYY-MM-DD untuk backend
  String _jenisKelamin = 'L';
  String _jenjang = 'mutawassithah';

  // --- Step 2: Wali ---
  final _namaWali = TextEditingController();
  final _noHpWali = TextEditingController();
  final _emailWali = TextEditingController();
  final _alamatWali = TextEditingController();

  // --- Step 3: Berkas (data URI base64) ---
  final _fotoAnak = TextEditingController();
  final _kartuKeluarga = TextEditingController();
  final _aktaLahir = TextEditingController();

  /// Naik setiap form di-reset, dipakai sebagai key supaya tile berkas dibuat ulang.
  int _gen = 0;

  int _step = 0;
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  String? _suksesPesan;
  String? _suksesNomor;

  @override
  void dispose() {
    _scroll.dispose();
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

  void _scrollTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Kosongkan semua isian untuk pendaftar berikutnya.
  /// Kode & info pondok dipertahankan (pondoknya sama), langsung ke langkah Santri.
  void _resetForm() {
    _namaCalon.clear();
    _nisn.clear();
    _tempatLahir.clear();
    _tglLahir.clear();
    _asalSekolah.clear();
    _namaWali.clear();
    _noHpWali.clear();
    _emailWali.clear();
    _alamatWali.clear();
    _fotoAnak.clear();
    _kartuKeluarga.clear();
    _aktaLahir.clear();
    setState(() {
      _gen++;
      _tglLahirIso = null;
      _jenisKelamin = 'L';
      _jenjang = 'mutawassithah';
      _step = 1;
      _error = null;
      _submitted = false;
      _suksesPesan = null;
      _suksesNomor = null;
    });
    _scrollTop();
  }

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _cekKode() async {
    FocusScope.of(context).unfocus();
    final kode = _kode.text.trim();
    if (kode.isEmpty) {
      setState(() => _error = 'Masukkan kode registrasi PPDB pondok.');
      return;
    }

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
      setState(() {
        _tenantInfo = _TenantInfo.fromJson(res as Map<String, dynamic>);
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
            ? 'Kode PPDB tidak ditemukan. Periksa kembali kode Anda.'
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
      setState(() {
        _tglLahir.text = '$dd/$mm/${picked.year}';
        _tglLahirIso = '${picked.year}-$mm-$dd';
      });
    }
  }

  String? _validateStep(int s) {
    if (s == 0) {
      if (!_kodeValid) return 'Periksa kode PPDB pondok terlebih dahulu.';
      if (_tenantInfo?.gelombangDibuka == false) {
        return 'Pendaftaran di pondok ini sedang ditutup.';
      }
    }
    if (s == 1) {
      if (_namaCalon.text.trim().isEmpty) {
        return 'Nama lengkap ananda wajib diisi.';
      }
      final nisn = _nisn.text.trim();
      if (nisn.isNotEmpty && nisn.length != 10) {
        return 'NISN harus 10 digit. Kosongkan kalau belum punya.';
      }
    }
    if (s == 2) {
      if (_namaWali.text.trim().isEmpty || _noHpWali.text.trim().isEmpty) {
        return 'Nama dan No. HP wali wajib diisi.';
      }
      if (_noHpWali.text.replaceAll(RegExp(r'\D'), '').length < 9) {
        return 'No. HP wali tidak valid.';
      }
      final email = _emailWali.text.trim();
      if (email.isNotEmpty &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        return 'Format email tidak valid.';
      }
    }
    return null;
  }

  void _goNext() {
    FocusScope.of(context).unfocus();

    // Di langkah Pondok, kalau kode belum diperiksa tombol berfungsi sebagai "Periksa".
    if (_step == 0 && !_kodeValid) {
      _cekKode();
      return;
    }

    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);

    if (_step < _kSteps.length - 1) {
      setState(() => _step += 1);
      _scrollTop();
    } else {
      _submit();
    }
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _error = null;
        _step -= 1;
      });
      _scrollTop();
    }
  }

  void _jumpTo(int step) {
    setState(() {
      _error = null;
      _step = step;
    });
    _scrollTop();
  }

  String? _nullIfEmpty(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
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
        'nisn': _nullIfEmpty(_nisn),
        'tempatLahir': _nullIfEmpty(_tempatLahir),
        'tanggalLahir': _tglLahirIso,
        'asalSekolah': _nullIfEmpty(_asalSekolah),
        'jenjang': _jenjang,
        'namaWali': _namaWali.text.trim(),
        'noHp': _noHpWali.text.trim(),
        'email': _nullIfEmpty(_emailWali),
        'alamat': _nullIfEmpty(_alamatWali),
        'fotoUrl': _nullIfEmpty(_fotoAnak),
        'kartuKeluargaUrl': _nullIfEmpty(_kartuKeluarga),
        'aktaLahirUrl': _nullIfEmpty(_aktaLahir),
      });
      if (!mounted) return;
      final m = res as Map<String, dynamic>;
      setState(() {
        _submitted = true;
        _suksesPesan =
            (m['message'] as String?) ?? 'Pendaftaran berhasil dikirim.';
        _suksesNomor = m['noPendaftaran'] as String?;
      });
      _scrollTop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal mengirim pendaftaran. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nextLabel() {
    switch (_step) {
      case 0:
        return _kodeValid ? 'Lanjut ke Data Santri' : 'Periksa Kode';
      case 1:
        return 'Lanjut ke Data Wali';
      case 2:
        return 'Lanjut ke Berkas';
      case 3:
        return 'Lanjut ke Ringkasan';
      default:
        return 'Kirim Pendaftaran';
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(
                        onBack: _goBack,
                        namaPondok: _kodeValid ? _tenantInfo?.namaPondok : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_submitted)
                              _SuksesCard(
                                message:
                                    _suksesPesan ?? 'Pendaftaran terkirim.',
                                nomor: _suksesNomor,
                                namaPondok: _tenantInfo?.namaPondok,
                                onReset: _resetForm,
                              )
                            else ...[
                              _StepTracker(step: _step, onTap: _tapStep),
                              const SizedBox(height: 16),
                              if (_step == 0) _buildStepPondok(),
                              if (_step == 1) _buildStepSantri(),
                              if (_step == 2) _buildStepWali(),
                              if (_step == 3) _buildStepBerkas(),
                              if (_step == 4) _buildStepKirim(),
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
              if (!_submitted) _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Boleh loncat mundur ke langkah yang sudah dilewati.
  void _tapStep(int i) {
    if (i < _step && !_loading) _jumpTo(i);
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: PColors.surface,
        border: Border(top: BorderSide(color: PColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                _MessageBanner(text: _error!),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (_step > 0) ...[
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _goBack,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: PColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: PColors.ink, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _PrimaryButton(
                      label: _nextLabel(),
                      loading: _loading || _checkingKode,
                      showArrow: _step < _kSteps.length - 1,
                      onPressed: _goNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STEP 0 — Pondok
  // ---------------------------------------------------------------------
  Widget _buildStepPondok() {
    final info = _tenantInfo;

    if (_kodeValid && info != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PColors.successBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PColors.successBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: PColors.successText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kode valid & terhubung',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: PColors.successText,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _kodeValid = false;
                        _tenantInfo = null;
                        _error = null;
                      }),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        'Ganti',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: PColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: PColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.mosque_outlined,
                          size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info.namaPondok, style: PText.headlineSm),
                          if (info.alamat.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(info.alamat, style: PText.bodySm),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PPill(
                      label: info.gelombangDibuka
                          ? 'Pendaftaran dibuka'
                          : 'Pendaftaran ditutup',
                      bg: Colors.white,
                      fg: info.gelombangDibuka
                          ? PColors.successText
                          : PColors.errorText,
                    ),
                    if (info.sisaKuota != null)
                      _PPill(
                        label: 'Sisa kuota ${info.sisaKuota} santri',
                        bg: Colors.white,
                        fg: PColors.successText,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _SectionCard(
      title: 'Masuk ke Pondok',
      subtitle: 'Masukkan kode PPDB dari brosur pendaftaran',
      icon: Icons.vpn_key_outlined,
      children: [
        _Field(
          label: 'Kode Registrasi PPDB',
          required: true,
          child: _PInput(
            controller: _kode,
            hint: 'mis. nama-pondok',
            icon: Icons.tag,
            bold: true,
            onSubmitted: (_) => _cekKode(),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.help_outline,
                size: 14, color: PColors.inkSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Belum punya kode? Hubungi panitia PPDB pondok.',
                style: PText.bodySm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 1 — Calon Santri
  // ---------------------------------------------------------------------
  Widget _buildStepSantri() {
    return _SectionCard(
      title: 'Data Calon Santri',
      subtitle: 'Isi sesuai akta kelahiran ananda',
      icon: Icons.person_rounded,
      children: [
        _Field(
          label: 'Nama Lengkap',
          required: true,
          child: _PInput(
            controller: _namaCalon,
            hint: 'Nama lengkap ananda',
            icon: Icons.person_outline,
            capitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Jenis Kelamin',
          child: Row(
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
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(
                label: 'Tempat Lahir',
                child: _PInput(
                  controller: _tempatLahir,
                  hint: 'Jakarta',
                  capitalization: TextCapitalization.words,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'Tanggal Lahir',
                child: _PInput(
                  controller: _tglLahir,
                  hint: 'DD/MM/YYYY',
                  readOnly: true,
                  onTap: _pickTanggalLahir,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'NISN',
          optional: true,
          child: _PInput(
            controller: _nisn,
            hint: '10 digit (nomor dari sekolah asal)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 10,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Asal Sekolah / Madrasah',
          child: _PInput(
            controller: _asalSekolah,
            hint: 'SDIT Ibnu Abbas',
            icon: Icons.school_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Jenjang yang Dipilih',
          child: Column(
            children: [
              for (final o in _kJenjangOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _jenjang = o.id),
                    child: _JenjangTile(option: o, selected: _jenjang == o.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 2 — Wali
  // ---------------------------------------------------------------------
  Widget _buildStepWali() {
    return _SectionCard(
      title: 'Data Wali Santri',
      subtitle: 'Kontak yang akan dihubungi panitia',
      icon: Icons.family_restroom_rounded,
      children: [
        _Field(
          label: 'Nama Ayah / Bunda / Wali',
          required: true,
          child: _PInput(
            controller: _namaWali,
            hint: 'Nama lengkap wali',
            icon: Icons.person_outline,
            capitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'No. HP / WhatsApp Aktif',
          required: true,
          child: _PInput(
            controller: _noHpWali,
            hint: '08xxxxxxxxxx',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Email',
          optional: true,
          child: _PInput(
            controller: _emailWali,
            hint: 'wali@email.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Alamat Domisili',
          optional: true,
          child: _PInput(
            controller: _alamatWali,
            hint: 'Alamat lengkap domisili',
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 3 — Berkas
  // ---------------------------------------------------------------------
  Widget _buildStepBerkas() {
    return _SectionCard(
      title: 'Unggah Berkas',
      subtitle: 'PNG / JPG / PDF, maksimal 2MB per berkas',
      icon: Icons.folder_copy_outlined,
      children: [
        _UploadTile(
          key: ValueKey('foto$_gen'),
          title: 'Pas Foto Ananda',
          controller: _fotoAnak,
          kind: _BerkasKind.photoOnly,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          key: ValueKey('kk$_gen'),
          title: 'Kartu Keluarga',
          controller: _kartuKeluarga,
          kind: _BerkasKind.documentOnly,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          key: ValueKey('akta$_gen'),
          title: 'Akta Kelahiran',
          controller: _aktaLahir,
          kind: _BerkasKind.documentOnly,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 4 — Ringkasan
  // ---------------------------------------------------------------------
  Widget _buildStepKirim() {
    final jenjang = _kJenjangOptions.firstWhere((j) => j.id == _jenjang);
    final ttl = [_tempatLahir.text.trim(), _tglLahir.text.trim()]
        .where((e) => e.isNotEmpty)
        .join(', ');
    String berkas(TextEditingController c) =>
        c.text.trim().isEmpty ? 'Belum diunggah' : 'Terunggah';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Ringkasan Pendaftaran',
          subtitle: 'Periksa kembali sebelum dikirim',
          icon: Icons.fact_check_outlined,
          children: [
            _SummarySection(
              title: 'Pondok',
              onEdit: () => _jumpTo(0),
              rows: [
                _SummaryRow('Pondok', _tenantInfo?.namaPondok ?? '-'),
              ],
            ),
            const Divider(color: PColors.border, height: 24),
            _SummarySection(
              title: 'Calon Santri',
              onEdit: () => _jumpTo(1),
              rows: [
                _SummaryRow('Nama', _namaCalon.text.trim()),
                _SummaryRow('Jenis Kelamin',
                    _jenisKelamin == 'L' ? 'Ikhwan (Putra)' : 'Akhwat (Putri)'),
                _SummaryRow('Tempat, Tgl Lahir', ttl),
                _SummaryRow('NISN', _nisn.text.trim()),
                _SummaryRow('Asal Sekolah', _asalSekolah.text.trim()),
                _SummaryRow('Jenjang', jenjang.label),
              ],
            ),
            const Divider(color: PColors.border, height: 24),
            _SummarySection(
              title: 'Wali Santri',
              onEdit: () => _jumpTo(2),
              rows: [
                _SummaryRow('Nama', _namaWali.text.trim()),
                _SummaryRow('No. HP', _noHpWali.text.trim()),
                _SummaryRow('Email', _emailWali.text.trim()),
                _SummaryRow('Alamat', _alamatWali.text.trim()),
              ],
            ),
            const Divider(color: PColors.border, height: 24),
            _SummarySection(
              title: 'Berkas',
              onEdit: () => _jumpTo(3),
              rows: [
                _SummaryRow('Pas Foto', berkas(_fotoAnak)),
                _SummaryRow('Kartu Keluarga', berkas(_kartuKeluarga)),
                _SummaryRow('Akta Kelahiran', berkas(_aktaLahir)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _MessageBanner(
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
// Hero
// ============================================================================

/// Motif bintang delapan tipis (arabesque), digambar dengan CustomPainter.
class _ArabesquePatternPainter extends CustomPainter {
  static const double _tile = 48;
  static const double _starRadius = _tile * 0.34;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (double y = -_tile; y < size.height + _tile; y += _tile) {
      for (double x = -_tile; x < size.width + _tile; x += _tile) {
        _drawEightPointStar(canvas, Offset(x, y), _starRadius, paint);
      }
    }
  }

  void _drawEightPointStar(
      Canvas canvas, Offset center, double r, Paint paint) {
    final square1 = Path();
    final square2 = Path();
    for (int i = 0; i < 4; i++) {
      final a1 = (math.pi / 2) * i;
      final a2 = a1 + math.pi / 4;
      final p1 = center + Offset(math.cos(a1), math.sin(a1)) * r;
      final p2 = center + Offset(math.cos(a2), math.sin(a2)) * r;
      if (i == 0) {
        square1.moveTo(p1.dx, p1.dy);
        square2.moveTo(p2.dx, p2.dy);
      } else {
        square1.lineTo(p1.dx, p1.dy);
        square2.lineTo(p2.dx, p2.dy);
      }
    }
    square1.close();
    square2.close();
    canvas.drawPath(square1, paint);
    canvas.drawPath(square2, paint);
  }

  @override
  bool shouldRepaint(covariant _ArabesquePatternPainter oldDelegate) => false;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onBack, this.namaPondok});

  final VoidCallback onBack;
  final String? namaPondok;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    final y = DateTime.now().year;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PColors.primary, PColors.primaryGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArabesquePatternPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -34,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PColors.gold.withOpacity(0.16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.16),
                      shape: CircleBorder(
                        side: BorderSide(color: Colors.white.withOpacity(0.28)),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SIMPesantren',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Tahun Ajaran $y/${y + 1}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pendaftaran Santri Baru',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  namaPondok != null
                      ? namaPondok!
                      : "Bismillah. Ahlan wa Sahlan Ayah & Bunda, mari bersama "
                          "membina generasi penghafal Al-Qur'an.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    height: 1.45,
                    fontWeight:
                        namaPondok != null ? FontWeight.w700 : FontWeight.w400,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Step tracker
// ============================================================================

class _StepTracker extends StatelessWidget {
  const _StepTracker({required this.step, required this.onTap});

  final int step;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_kSteps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i - 1) ~/ 2 < step;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 17, left: 2, right: 2),
                color: done ? PColors.primary : PColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx == step;
          final done = idx < step;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(idx),
            child: SizedBox(
              width: 50,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (active || done)
                          ? PColors.primary
                          : PColors.surfaceDim,
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(color: PColors.gold, width: 2)
                          : null,
                    ),
                    child: Icon(
                      done ? Icons.check : _kSteps[idx].icon,
                      size: 17,
                      color: (active || done)
                          ? Colors.white
                          : PColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _kSteps[idx].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? PColors.ink : PColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// Gender tile & jenjang tile
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? PColors.primary : PColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? PColors.primary : PColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: selected ? Colors.white : PColors.primary),
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

class _JenjangTile extends StatelessWidget {
  const _JenjangTile({required this.option, required this.selected});

  final _JenjangOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? PColors.sage : PColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? PColors.primary : PColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? PColors.primary : PColors.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(option.icon,
                size: 19, color: selected ? Colors.white : PColors.primary),
          ),
          const SizedBox(width: 12),
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
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: selected ? PColors.primary : PColors.inkSecondary,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Upload tile
// ============================================================================

/// - photoOnly: kamera/galeri (Pas Foto)
/// - documentOnly: file picker PDF/JPG/PNG (KK, Akta)
enum _BerkasKind { photoOnly, documentOnly }

class _UploadTile extends StatefulWidget {
  const _UploadTile({
    super.key,
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
  bool _busy = false;
  String? _error;

  static const int _maxBytes = 2 * 1024 * 1024;

  bool get _hasFile => widget.controller.text.trim().isNotEmpty;

  /// Info singkat dari data URI, mis. "PDF • 340 KB".
  String get _info {
    final t = widget.controller.text;
    final semi = t.indexOf(';');
    final comma = t.indexOf(',');
    if (!t.startsWith('data:') || semi < 0 || comma < 0) return 'Berkas siap';
    final mime = t.substring(5, semi);
    final jenis = switch (mime) {
      'image/jpeg' => 'JPG',
      'image/png' => 'PNG',
      'application/pdf' => 'PDF',
      _ => 'Berkas',
    };
    final bytes = ((t.length - comma - 1) * 3 / 4).round();
    final ukuran = bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).round()} KB';
    return '$jenis • $ukuran';
  }

  Future<void> _pick() async {
    try {
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
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: PColors.primary),
                  title: const Text('Ambil Foto'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: PColors.primary),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        if (source == null) return;
        final xfile =
            await ImagePicker().pickImage(source: source, imageQuality: 85);
        if (xfile == null) return;
        final bytes = await xfile.readAsBytes();
        final ext = xfile.name.contains('.')
            ? xfile.name.split('.').last.toLowerCase()
            : 'jpg';
        _store(bytes, ext);
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData: true,
        );
        if (result == null || result.files.single.bytes == null) return;
        final file = result.files.single;
        _store(file.bytes!, (file.extension ?? '').toLowerCase());
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal membuka berkas. Coba lagi.');
    }
  }

  void _store(List<int> bytes, String ext) {
    if (!mounted) return;
    if (bytes.length > _maxBytes) {
      setState(() => _error = 'Ukuran berkas maksimal 2MB.');
      return;
    }
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
    widget.controller.text = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      _busy = false;
      _error = null;
    });
  }

  void _remove() {
    widget.controller.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _hasFile;
    final hasError = _error != null;
    final accent = hasError
        ? PColors.errorText
        : hasFile
            ? PColors.successText
            : PColors.inkSecondary;

    return GestureDetector(
      onTap: _busy ? null : _pick,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile ? PColors.successBg : PColors.surfaceDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? PColors.errorBorder
                : hasFile
                    ? PColors.successBorder
                    : PColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile ? Colors.white : PColors.sage,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.check_rounded
                    : widget.kind == _BerkasKind.photoOnly
                        ? Icons.photo_camera_outlined
                        : Icons.upload_file_outlined,
                size: 20,
                color: hasFile ? PColors.successText : PColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: PText.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    _error ??
                        (hasFile
                            ? _info
                            : widget.kind == _BerkasKind.photoOnly
                                ? 'Ketuk untuk ambil / pilih foto'
                                : 'Ketuk untuk pilih berkas'),
                    style: PText.bodySm.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                onPressed: _remove,
                tooltip: 'Hapus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: PColors.inkSecondary),
              )
            else
              Icon(
                hasError ? Icons.error_outline : Icons.chevron_right,
                color: accent,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Widget bersama
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: PColors.sage,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: PColors.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PText.headlineSm),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: PText.bodySm),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              style: PText.labelLg,
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: PColors.errorText),
                  ),
                if (optional)
                  TextSpan(text: '  (opsional)', style: PText.bodySm),
              ],
            ),
          ),
        ),
        child,
      ],
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
    this.maxLength,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.formatters,
    this.capitalization = TextCapitalization.none,
    this.bold = false,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization capitalization;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      style: PText.bodyMd.copyWith(
        color: PColors.ink,
        fontWeight: bold ? FontWeight.w700 : null,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: PText.bodyMd,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: PColors.inkSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: PColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(PColors.inputBorder),
        enabledBorder: border(PColors.inputBorder),
        focusedBorder: border(PColors.primary, 2),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<Widget> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: PColors.inkSecondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 14, color: PColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Ubah',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
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
          SizedBox(width: 118, child: Text(label, style: PText.bodySm)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: PText.bodyMd
                  .copyWith(color: PColors.ink, fontWeight: FontWeight.w600),
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
          disabledBackgroundColor: PColors.primary.withOpacity(0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PColors.gold,
                      ),
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,
                        size: 18, color: PColors.gold),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SuksesCard extends StatelessWidget {
  const _SuksesCard({
    required this.message,
    required this.nomor,
    required this.namaPondok,
    required this.onReset,
  });

  final String message;
  final String? nomor;
  final String? namaPondok;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pendaftaran Terkirim',
      subtitle: namaPondok,
      icon: Icons.mark_email_read_outlined,
      children: [
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: PColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: PColors.successText, size: 44),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PText.bodyMd
                  .copyWith(color: PColors.ink, fontWeight: FontWeight.w700),
            ),
            if (nomor != null && nomor!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: PColors.sage,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nomor Pendaftaran', style: PText.bodySm),
                          const SizedBox(height: 2),
                          Text(
                            nomor!,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: nomor!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Nomor pendaftaran disalin')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: PColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simpan nomor ini untuk konfirmasi dengan panitia.',
                textAlign: TextAlign.center,
                style: PText.bodySm,
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onReset,
                style: FilledButton.styleFrom(
                  backgroundColor: PColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1,
                    size: 18, color: PColors.gold),
                label: const Text(
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
                text:
                    'Butuh panduan teknis pendaftaran? Hubungi Call Center Layanan '
                    'Wali Santri di ',
              ),
              TextSpan(
                text: '0812-8800-4321.',
                style: PText.bodySm
                    .copyWith(fontWeight: FontWeight.w700, color: PColors.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}