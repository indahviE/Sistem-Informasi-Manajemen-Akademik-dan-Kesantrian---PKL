import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  final _nama = TextEditingController();
  String _logo = '';
  final _warna = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Color _preview = Tw.primary;

  static const _palette = [
    Color(0xFF059669),
    Color(0xFF0EA5E9),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFF0D9488),
    Color(0xFFDB2777),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.brandingMe) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _nama.text = res['namaPondok'] as String? ?? '';
        _logo = res['logoUrl'] as String? ?? '';
        final hex = res['warnaTema'] as String?;
        _warna.text = hex ?? '';
        _preview = _hexToColor(hex) ?? Tw.primary;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pilihLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    final ext = (file.extension ?? 'png').toLowerCase();
    final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';
    setState(() {
      _logo = 'data:$mime;base64,${base64Encode(file.bytes!)}';
    });
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      await AppScope.of(context).api.patch(ApiUrl.branding, {
        'namaPondok': _nama.text.trim(),
        'logoUrl': _logo.isEmpty ? null : _logo,
        'warnaTema': _warna.text.trim().isEmpty ? null : _warna.text.trim(),
      });
      await AppScope.of(context).refreshBranding();
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Branding berhasil disimpan.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: _preview,
                                    child: const Icon(Icons.school, color: Colors.white),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nama.text.trim().isEmpty ? 'Nama Pondok Anda' : _nama.text.trim(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Tw.gray900),
                                        ),
                                        const Text('Pratinjau identitas', style: TextStyle(fontSize: 12, color: Tw.gray500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SectionCard(
                            title: 'Pengaturan Branding',
                            children: [
                              TextField(controller: _nama,
                                  decoration: const InputDecoration(labelText: 'Nama Pondok')),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Tw.gray50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Tw.gray200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: _preview,
                                      ),
                                      child: _logo.isEmpty
                                          ? Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.9))
                                          : brandLogo(_logo, width: 56, height: 56),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Logo Pondok',
                                              style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Tw.gray900)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _logo.isEmpty
                                                ? 'Belum ada logo'
                                                : 'Logo tersimpan (base64)',
                                            style: const TextStyle(fontSize: 12, color: Tw.gray500),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _pilihLogo,
                                                icon: const Icon(Icons.upload_file, size: 18),
                                                label: const Text('Upload'),
                                              ),
                                              if (_logo.isNotEmpty)
                                                TextButton.icon(
                                                  onPressed: () => setState(() => _logo = ''),
                                                  icon: const Icon(Icons.delete_outline, size: 18),
                                                  label: const Text('Hapus'),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(controller: _warna,
                                  decoration: const InputDecoration(
                                    labelText: 'Warna Tema (hex)',
                                    hintText: '#059669',
                                  ),
                                  onChanged: (v) => setState(() {
                                    _preview = _hexToColor(v.trim()) ?? Tw.primary;
                                  })),
                              const SizedBox(height: 12),
                              const Text('Pilih warna cepat:',
                                  style: TextStyle(fontSize: 13, color: Tw.gray600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final c in _palette)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _preview = c;
                                        _warna.text = '#${c.toARGB32().toRadixString(16).substring(2)}';
                                      }),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                          border: _preview == c
                                              ? Border.all(color: Tw.gray800, width: 3)
                                              : null,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _saving ? null : _simpan,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Simpan Branding'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
