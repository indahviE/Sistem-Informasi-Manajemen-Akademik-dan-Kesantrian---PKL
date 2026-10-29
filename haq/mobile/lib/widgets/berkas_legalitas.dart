// berkas_legalitas.dart
//
// Dua widget untuk berkas legalitas pondok:
//  - BerkasUploadField : dipakai di signup_screen.dart (pendaftar unggah berkas)
//  - BerkasLegalitasCard : dipakai di tenant_detail_screen.dart (Super Admin melihat berkas)
//
// File ini berdiri sendiri (tidak import tenants_screen / signup_screen),
// jadi tidak bentrok dengan class PColors/PText yang dobel di dua file itu.
// Simpan misalnya di lib/widgets/berkas_legalitas.dart.

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class _C {
  _C._();
  static const primary = Color(0xFF0F3A2E);
  static const sage = Color(0xFFE2ECE9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const border = Color(0xFFEAE6DC);
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const outline = Color(0xFF717975);
  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const errorText = Color(0xFF991B1B);
  static const errorBorder = Color(0xFFFECACA);
}

const int kBerkasMaxBytes = 2 * 1024 * 1024; // 2MB per berkas

// ===========================================================================
// 1) Kolom unggah — untuk form pendaftaran
// ===========================================================================

class BerkasUploadField extends StatefulWidget {
  const BerkasUploadField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialNamaFile,
  });

  final String label;

  /// Nama file yang sudah dipilih sebelumnya (supaya tampilan tetap benar
  /// saat pengguna kembali ke langkah ini dari langkah berikutnya).
  final String? initialNamaFile;

  /// Dipanggil saat berkas dipilih (dataUri & namaFile terisi)
  /// atau dihapus (keduanya null).
  final void Function(String? dataUri, String? namaFile) onChanged;

  @override
  State<BerkasUploadField> createState() => _BerkasUploadFieldState();
}

class _BerkasUploadFieldState extends State<BerkasUploadField> {
  String? _namaFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    final awal = widget.initialNamaFile;
    if (awal != null && awal.isNotEmpty) _namaFile = awal;
  }

  Future<void> _pilih() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Berkas tidak bisa dibaca.');
      return;
    }
    if (bytes.length > kBerkasMaxBytes) {
      setState(() => _error = 'Ukuran berkas maksimal 2MB.');
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    setState(() => _namaFile = file.name);
    widget.onChanged('data:$mime;base64,${base64Encode(bytes)}', file.name);
  }

  void _hapus() {
    setState(() {
      _namaFile = null;
      _error = null;
    });
    widget.onChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final sudahAda = _namaFile != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sudahAda ? _C.successBg : _C.surfaceDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error != null ? _C.errorBorder : _C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sudahAda ? Icons.check_circle : Icons.description_outlined,
                size: 20,
                color: sudahAda ? _C.successText : _C.inkSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                    if (sudahAda)
                      Text(
                        _namaFile!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: _C.successText,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pilih,
                style: TextButton.styleFrom(
                  foregroundColor: _C.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  sudahAda ? 'Ganti' : 'Pilih',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              if (sudahAda)
                IconButton(
                  onPressed: _hapus,
                  tooltip: 'Hapus berkas',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18, color: _C.errorText),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.errorText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 2) Kartu daftar berkas — untuk halaman detail tenant (Super Admin)
// ===========================================================================
//
// Format data yang dibaca dari tenant['berkas']:
//   [{ "nama": "SK Kemenag / Izin Operasional",
//      "namaFile": "sk.pdf",
//      "url": "https://..." }]
// (kalau backend masih mengirim "data" berupa data URI, gambar tetap
// bisa dipratinjau; PDF butuh "url".)

class BerkasLegalitasCard extends StatelessWidget {
  const BerkasLegalitasCard({
    super.key,
    required this.berkas,
    this.resolveUrl,
  });
  

  final dynamic berkas; // tenant['berkas']

  /// Dipanggil saat berkas diketuk. Menerima id berkas, mengembalikan URL
  /// sementara yang bisa dibuka di browser (diminta ke backend).
  final Future<String?> Function(String id)? resolveUrl;

  List<Map<String, dynamic>> get _list {
    if (berkas is! List) return [];
    return (berkas as List).whereType<Map<String, dynamic>>().toList();
  }

  bool _adalahGambar(Map<String, dynamic> b) {
    final nama = (b['namaFile'] ?? '').toString().toLowerCase();
    return nama.endsWith('.jpg') ||
        nama.endsWith('.jpeg') ||
        nama.endsWith('.png');
  }

  void _pratinjauGambar(BuildContext context, String url, String judul) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      judul,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) => progress == null
                      ? child
                      : const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                  errorBuilder: (c, e, s) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Foto gagal dimuat.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ketuk(BuildContext context, List<Map<String, dynamic>> list,
      Map<String, dynamic> b) {
    if (_adalahGambar(b)) {
      showDialog(
        context: context,
        builder: (_) => _PratinjauBerkasDialog(
          items: list,
          awal: list.indexOf(b),
          resolveUrl: resolveUrl,
        ),
      );
    } else {
      _buka(context, b);
    }
  }

  Future<void> _buka(BuildContext context, Map<String, dynamic> b) async {
    var sumber = (b['url'] ?? b['data'] ?? '').toString();

    final id = b['id']?.toString();
    if (id != null && resolveUrl != null) {
      try {
        sumber = (await resolveUrl!(id)) ?? '';
      } catch (e) {
        if (context.mounted) {
          _notif(context, 'Gagal Mengambil Berkas',
              subtitle: e.toString(), error: true);
        }
        return;
      }
      if (sumber.isEmpty) {
        if (context.mounted) {
          _notif(context, 'Gagal Mengambil Berkas', error: true);
        }
        return;
      }
    }

    if (sumber.startsWith('http')) {
      final ok = await launchUrl(
        Uri.parse(sumber),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        _notif(context, 'Tidak Bisa Membuka Berkas', error: true);
      }
      return;
    }

    if (sumber.startsWith('data:image')) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: InteractiveViewer(
            child: Image.memory(base64Decode(sumber.split(',').last)),
          ),
        ),
      );
      return;
    }

    if (context.mounted) {
      _notif(context, 'Berkas Belum Bisa Dibuka', error: true);
    }
  }

  /// Notifikasi melayang bertema emerald + emas (sama gayanya dengan
  /// notifikasi di Kelola Tenant dan Absensi).
  void _notif(
    BuildContext context,
    String title, {
    String? subtitle,
    bool error = false,
  }) {
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final bg = error ? const Color(0xFFB91C1C) : _C.primary;
    final accent = error ? Colors.white : const Color(0xFFC5A059);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 6,
          // 96 = jarak dari bawah supaya tidak menutupi tombol di bar bawah
          margin: EdgeInsets.fromLTRB(side, 0, side, 96),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accent.withOpacity(0.5)),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline_rounded : Icons.check_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  size: 18, color: Color(0xFFB78103)),
              SizedBox(width: 8),
              Text(
                'Berkas Legalitas',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB78103),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Periksa berkas sebelum menekan Setujui & Aktifkan.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: _C.inkSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: const Text(
                'Pendaftar tidak mengunggah berkas. Verifikasi manual lewat PIC bila perlu.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: _C.inkSecondary,
                ),
              ),
            )
          else
            for (final b in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _ketuk(context, list, b),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 18, color: _C.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (b['nama'] ?? 'Berkas').toString(),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.ink,
                                ),
                              ),
                              if ((b['namaFile'] ?? '').toString().isNotEmpty)
                                Text(
                                  b['namaFile'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: _C.outline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new,
                            size: 15, color: _C.outline),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
// SESUDAH (baru, tambahkan di akhir file)
class _PratinjauBerkasDialog extends StatefulWidget {
  const _PratinjauBerkasDialog({
    required this.items,
    required this.awal,
    required this.resolveUrl,
  });

  final List<Map<String, dynamic>> items;
  final int awal;
  final Future<String?> Function(String id)? resolveUrl;

  @override
  State<_PratinjauBerkasDialog> createState() =>
      _PratinjauBerkasDialogState();
}

class _PratinjauBerkasDialogState extends State<_PratinjauBerkasDialog> {
  final _ctrl = TransformationController();
  late int _i;
  String? _url;
  bool _loading = true;
  String? _error;
  double _zoom = 1;
  Size _stage = Size.zero;

  Map<String, dynamic> get _b => widget.items[_i];

  bool get _gambar {
    final n = (_b['namaFile'] ?? '').toString().toLowerCase();
    return n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png');
  }

  @override
  void initState() {
    super.initState();
    _i = widget.awal;
    _ctrl.addListener(() {
      final s = _ctrl.value.getMaxScaleOnAxis();
      if ((s - _zoom).abs() > 0.01 && mounted) setState(() => _zoom = s);
    });
    _muat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    final index = _i;
    try {
      final id = _b['id']?.toString();
      String? u;
      if (id != null && widget.resolveUrl != null) {
        u = await widget.resolveUrl!(id);
      } else {
        u = (_b['url'] ?? _b['data'] ?? '').toString();
      }
      if (!mounted || index != _i) return;
      if (u == null || u.isEmpty) {
        setState(() {
          _error = 'Berkas tidak bisa diambil.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _url = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || index != _i) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _pindah(int arah) {
    _ctrl.value = Matrix4.identity();
    setState(() {
      _i += arah;
      _loading = true;
      _error = null;
      _url = null;
      _zoom = 1;
    });
    _muat();
  }

  void _setZoom(double s) {
    final z = s.clamp(0.5, 4.0).toDouble();
    final tx = _stage.width * (1 - z) / 2;
    final ty = _stage.height * (1 - z) / 2;
    _ctrl.value = Matrix4.translationValues(tx, ty, 0)
      ..multiply(Matrix4.diagonal3Values(z, z, 1));
  }

  Widget _panah(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: _C.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: _C.ink),
        ),
      ),
    );
  }

  bool get _bisaDibuka => _url != null && !_url!.startsWith('data:');

  Future<void> _unduh() async {
    final u = Uri.parse(_url!);
    final unduh = u.replace(
      queryParameters: {...u.queryParameters, 'download': '1'},
    );
    await launchUrl(unduh, mode: LaunchMode.externalApplication);
  }

  Widget _barZoom() {
    Widget tombol(IconData icon, VoidCallback onTap,
        {Color color = Colors.white}) {
      return InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.primary,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tombol(Icons.zoom_out, () => _setZoom(_zoom - 0.25)),
          SizedBox(
            width: 46,
            child: Text(
              '${(_zoom * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          tombol(Icons.zoom_in, () => _setZoom(_zoom + 0.25)),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white30,
          ),
          tombol(Icons.fit_screen, () => _setZoom(1),
              color: const Color(0xFFC5A059)),
        ],
      ),
    );
  }

  Widget _isiStage() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _C.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12.5,
              color: _C.errorText,
            ),
          ),
        ),
      );
    }
    if (!_gambar) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 48, color: _C.primary),
            SizedBox(height: 8),
            Text(
              'PDF dibuka di aplikasi atau tab lain.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                color: _C.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }
    final u = _url!;
    return LayoutBuilder(
      builder: (ctx, c) {
        _stage = Size(c.maxWidth, c.maxHeight);
        return InteractiveViewer(
          transformationController: _ctrl,
          minScale: 0.5,
          maxScale: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 16, 44, 56),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: u.startsWith('data:')
                    ? Image.memory(
                        base64Decode(u.split(',').last),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        u,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                    color: _C.primary),
                              ),
                        errorBuilder: (c, e, s) => const Text(
                          'Foto gagal dimuat.',
                          style: TextStyle(color: _C.errorText),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final n = widget.items.length;
    final namaFile = (b['namaFile'] ?? '').toString();
    final tinggiStage =
        (MediaQuery.of(context).size.height * 0.45).clamp(200.0, 320.0).toDouble();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.sage,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        size: 20, color: _C.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (b['nama'] ?? 'Berkas').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                          ),
                        ),
                        Text(
                          '${namaFile.isEmpty ? '-' : namaFile} · Berkas ${_i + 1} dari $n',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: _C.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                        backgroundColor: _C.surfaceDim),
                    icon: const Icon(Icons.close, size: 18, color: _C.ink),
                  ),
                ],
              ),
            ),
            Container(
              height: tinggiStage,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _C.surfaceDim,
                border: Border.symmetric(
                  horizontal: BorderSide(color: _C.border),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _isiStage()),
                  if (n > 1 && _i > 0)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _panah(Icons.chevron_left, () => _pindah(-1)),
                      ),
                    ),
                  if (n > 1 && _i < n - 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _panah(Icons.chevron_right, () => _pindah(1)),
                      ),
                    ),
                  if (_gambar && _url != null && _error == null)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: _barZoom()),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _bisaDibuka ? _unduh : null,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text(
                          'Unduh',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          side: const BorderSide(color: _C.border),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _bisaDibuka
                            ? () => launchUrl(
                                  Uri.parse(_url!),
                                  mode: LaunchMode.externalApplication,
                                )
                            : null,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text(
                          'Buka di tab baru',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.primary,
                          side: const BorderSide(color: _C.border),
                          shape: const StadiumBorder(),
                        ),
                      ),
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
}