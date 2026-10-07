import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama persis dengan `_AC` di absensi_screen.dart.
class _UC {
  _UC._();

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

class _RoleInfo {
  final String value;
  final String label;
  final String chip; // label pendek untuk filter
  final IconData icon;
  const _RoleInfo(this.value, this.label, this.chip, this.icon);
}

const _kRoles = [
  _RoleInfo('ADMIN', 'Admin', 'Admin', Icons.admin_panel_settings_outlined),
  _RoleInfo('USTADZ', 'Ustadz / Guru', 'Ustadz', Icons.school_outlined),
  _RoleInfo('MUSYRIF', 'Musyrif / Pembina', 'Musyrif', Icons.night_shelter_outlined),
  _RoleInfo('PIMPINAN', 'Pimpinan / Mudir', 'Pimpinan', Icons.workspace_premium_outlined),
  _RoleInfo('WALI_SANTRI', 'Wali Santri', 'Wali', Icons.family_restroom_outlined),
];

_RoleInfo _roleOf(String value) {
  for (final r in _kRoles) {
    if (r.value == value) return r;
  }
  return _RoleInfo(value, value, value, Icons.person_outline_rounded);
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA'; // 'SEMUA' atau nilai role
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  bool _isAktif(Map<String, dynamic> u) => (u['status'] ?? '').toString() == 'AKTIF';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.users);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
          _error = 'Gagal memuat daftar pengguna.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final res = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _UC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _TambahSheet(),
    );
    if (res == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.users, {
        'nama': res['nama'],
        'email': res['email'],
        'password': res['password'],
        'role': res['role'],
      });
      if (!mounted) return;
      _toast('Pengguna ditambahkan', subtitle: '${res['nama']} • ${_roleOf(res['role']!).label}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menambahkan pengguna.', error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Util
  // ---------------------------------------------------------------------
  String _inisial(String nama) {
    final n = nama.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  /// Notifikasi melayang bertema (sukses = emerald, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _UC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _UC.errorBg : _UC.primary,
          elevation: 6,
          margin: EdgeInsets.fromLTRB(side, 0, side, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: error ? _UC.errorText.withOpacity(0.25) : _UC.gold.withOpacity(0.5)),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _UC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _UC.errorText : _UC.gold,
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

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _UC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _UC.border),
      ),
      child: child,
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manajemen Pengguna',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _UC.ink)),
        SizedBox(height: 2),
        Text('Akun yang dapat masuk ke sistem pondok',
            style: TextStyle(fontSize: 12, color: _UC.inkSecondary)),
      ],
    );
  }

  Widget _counter(IconData icon, String label, int value) {
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
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _items.length;
    final aktif = _items.where(_isAktif).length;
    final nonaktif = total - aktif;
    final pct = total > 0 ? aktif / total : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_UC.primary, _UC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _UC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
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
              decoration: BoxDecoration(color: _UC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RINGKASAN PENGGUNA',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text('$total Pengguna Terdaftar',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _counter(Icons.groups_2_outlined, 'Total', total),
                    const SizedBox(width: 8),
                    _counter(Icons.check_circle_outline, 'Aktif', aktif),
                    const SizedBox(width: 8),
                    _counter(Icons.pause_circle_outline, 'Nonaktif', nonaktif),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Akun Aktif', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8))),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_UC.mint),
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
      style: const TextStyle(fontSize: 14, color: _UC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama atau email',
        hintStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _UC.inkSecondary),
        filled: true,
        fillColor: _UC.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _UC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _UC.primary),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : _UC.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _UC.inkSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    int countRole(String r) => _items.where((u) => (u['role'] ?? '').toString() == r).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('SEMUA', 'Semua', _items.length),
          for (final r in _kRoles) ...[
            const SizedBox(width: 8),
            _filterChip(r.value, r.chip, countRole(r.value)),
          ],
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: _UC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.manage_accounts_outlined, color: _UC.gold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _UC.inkSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _userCard(int index, Map<String, dynamic> u) {
    final nama = (u['nama'] ?? '-').toString().trim();
    final email = (u['email'] ?? '-').toString();
    final role = _roleOf((u['role'] ?? '').toString());
    final aktif = _isAktif(u);
    final even = index.isEven;

    // Pill role: admin = hijau tema, pembina/pengajar = emas, lainnya = netral
    Color roleBg;
    Color roleFg;
    switch (role.value) {
      case 'ADMIN':
        roleBg = _UC.sage;
        roleFg = _UC.primary;
        break;
      case 'USTADZ':
      case 'MUSYRIF':
        roleBg = const Color(0xFFF3E2B8);
        roleFg = _UC.goldDark;
        break;
      default:
        roleBg = const Color(0xFFE6E4DB);
        roleFg = _UC.ink;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: even ? _UC.sage : _UC.goldSurface, shape: BoxShape.circle),
                child: Text(_inisial(nama),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: even ? _UC.primary : _UC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _UC.ink)),
                    const SizedBox(height: 2),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: aktif ? const Color(0xFFD2E4DC) : const Color(0xFFE6E4DB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: aktif ? const Color(0xFF0F3A2E) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(aktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: aktif ? const Color(0xFF0F3A2E) : _UC.inkSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(role.icon, size: 14, color: roleFg),
                const SizedBox(width: 6),
                Text(role.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: roleFg)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final filtered = _items.where((u) {
      if (_filter != 'SEMUA' && (u['role'] ?? '').toString() != _filter) return false;
      if (q.isEmpty) return true;
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

      Widget content;
    if (_loading) {
      content = loadingView();
    } else if (_error != null) {
      content = errorView(_error!, _load);
    } else {
      content = RefreshIndicator(
        color: _UC.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _header(),
            const SizedBox(height: 14),
            _summaryCard(),
            const SizedBox(height: 14),
            _searchField(),
            const SizedBox(height: 12),
            _filterRow(),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              _emptyCard(_items.isEmpty
                  ? 'Belum ada pengguna.'
                  : 'Tidak ada pengguna yang cocok.')
            else
              for (var i = 0; i < filtered.length; i++) ...[
                _userCard(i, filtered[i]),
                const SizedBox(height: 10),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _UC.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: _add,
                  backgroundColor: _UC.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tambah User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: tambah user
// ---------------------------------------------------------------------
class _TambahSheet extends StatefulWidget {
  const _TambahSheet();

  @override
  State<_TambahSheet> createState() => _TambahSheetState();
}

class _TambahSheetState extends State<_TambahSheet> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'USTADZ';
  bool _showPass = false;
  String? _err;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final nama = _nama.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;

    if (nama.isEmpty) {
      setState(() => _err = 'Nama wajib diisi.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Format email tidak valid.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _err = 'Password minimal 6 karakter.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {
      'nama': nama,
      'email': email,
      'password': pass,
      'role': _role,
    });
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) => InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        hintStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        labelStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        filled: true,
        fillColor: _UC.surfaceDim,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _roleChip(_RoleInfo r) {
    final selected = _role == r.value;
    return GestureDetector(
      onTap: () => setState(() => _role = r.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(r.icon, size: 15, color: selected ? Colors.white : _UC.inkSecondary),
            const SizedBox(width: 6),
            Text(r.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: _UC.goldSurface, shape: BoxShape.circle),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: _UC.gold),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah Pengguna',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _UC.ink)),
                        Text('Buat akun baru untuk masuk ke sistem',
                            style: TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('Nama', hint: 'Nama lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('Email', hint: 'nama@pondok.id'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec(
                  'Password',
                  hint: 'Minimal 6 karakter',
                  suffix: IconButton(
                    onPressed: () => setState(() => _showPass = !_showPass),
                    tooltip: _showPass ? 'Sembunyikan' : 'Tampilkan',
                    icon: Icon(
                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: _UC.inkSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ROLE',
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: _UC.inkSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final r in _kRoles) _roleChip(r)]),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _UC.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: _UC.errorText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_err!, style: const TextStyle(fontSize: 12.5, color: _UC.errorText)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _UC.inkSecondary,
                      side: const BorderSide(color: _UC.border),
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _UC.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                        label: const Text('Simpan Pengguna',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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
}