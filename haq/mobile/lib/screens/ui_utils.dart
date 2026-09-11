import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

/// Menampilkan logo yang bisa berupa URL biasa atau data URI base64.
Widget brandLogo(String? logo, {double width = 44, double height = 44, double radius = 12, IconData fallback = Icons.school_rounded}) {
  if (logo != null && logo.isNotEmpty) {
    if (logo.startsWith('data:')) {
      final parts = logo.split(',');
      if (parts.length > 1) {
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              base64Decode(parts.sublist(1).join(',')),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, color: Colors.white, size: 26),
            ),
          );
        } catch (_) {}
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        logo,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, color: Colors.white, size: 26),
      ),
    );
  }
  return Icon(fallback, color: Colors.white, size: (width + height) / 3);
}

/// Kartu statistik ala template admin Tailwind:
/// kartu putih rounded-2xl dengan "icon chip" berwarna + angka besar.
Widget statCard(
  BuildContext context, {
  required String label,
  required String value,
  IconData? icon,
  Color? color,
  Color? softColor,
  String? hint,
}) {
  final c = color ?? Tw.primary;
  final s = softColor ?? Tw.primarySoft;
  return Card(
    margin: const EdgeInsets.all(0),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: s,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: c, size: 17),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Tw.gray900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Tw.gray500),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 1),
                  Text(hint, style: const TextStyle(fontSize: 10, color: Tw.gray400)),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Badge kecil berwarna ala Tailwind (mis. status chip).
Widget twBadge(BuildContext context, String text, {Color? color, Color? soft}) {
  final c = color ?? Tw.primary;
  final s = soft ?? Tw.primarySoft;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: s,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

Widget loadingView() => const Center(
      child: CircularProgressIndicator(color: Tw.primary, strokeWidth: 2.5),
    );

Widget errorView(String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Tw.redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Tw.red, size: 36),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Tw.gray600)),
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Muat Ulang')),
        ],
      ),
    ),
  );
}

Widget emptyView(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Tw.gray100, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.inbox_outlined, color: Tw.gray400, size: 40),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Tw.gray500)),
        ],
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tw.gray900),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Header halaman (judul besar + aksi) ala Tailwind.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const PageHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Tw.gray900),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: Tw.gray500)),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Select modern & bersih — membuka bottom sheet berisi opsi dengan tanda centang.
class TwSelect extends StatelessWidget {
  final String? value;
  final List<DropdownOption> options;
  final ValueChanged<String?> onChanged;
  final String label;
  final IconData? icon;
  final bool required;

  const TwSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label = '',
    this.icon,
    this.required = false,
  });

  String get _display {
    final selected = options.where((o) => o.value == value);
    return selected.isNotEmpty ? selected.first.label : (label.isEmpty ? 'Pilih…' : 'Pilih $label…');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Tw.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Tw.gray100),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Tw.gray400),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty) ...[
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: Tw.gray400, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Tw.gray900 : Tw.gray400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Tw.gray400),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TwSelectSheet(
        title: label.isEmpty ? 'Pilih' : 'Pilih $label',
        value: value,
        options: options,
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class DropdownOption {
  final String value;
  final String label;
  const DropdownOption(this.value, this.label);
}

/// Modal form (tambah/edit) yang bersih & modern: header ber-ikon, jarak field
/// konsisten, konten bisa discroll agar tidak overflow di layar kecil.
class TwFormDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? subtitle;
  final List<Widget> fields;
  final List<Widget> actions;
  const TwFormDialog({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    required this.fields,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final seed = AppScope.maybeOf(context)?.brandingColor ?? Tw.primary;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Tw.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 22, color: seed),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(title)),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: 4, left: icon != null ? 52 : 0),
              child: DefaultTextStyle(
                style: const TextStyle(color: Tw.gray500, fontSize: 13, height: 1.4),
                child: subtitle!,
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Tw.gray100),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              fields[i],
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      actions: actions,
    );
  }
}

class _TwSelectSheet extends StatefulWidget {
  final String title;
  final String? value;
  final List<DropdownOption> options;
  const _TwSelectSheet({required this.title, required this.value, required this.options});

  @override
  State<_TwSelectSheet> createState() => _TwSelectSheetState();
}

class _TwSelectSheetState extends State<_TwSelectSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DropdownOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((o) => o.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final seed = AppScope.maybeOf(context)?.brandingColor ?? Tw.primary;
    final list = _filtered;
    return Container(
      decoration: const BoxDecoration(
        color: Tw.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Tw.gray200, borderRadius: BorderRadius.circular(4))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Tw.gray900)),
            ),
            if (widget.options.length >= 5) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
            Flexible(
              child: list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Tidak ada hasil.', style: TextStyle(color: Tw.gray400, fontSize: 13))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (_, i) {
                        final o = list[i];
                        final sel = o.value == widget.value;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, o.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: sel ? Tw.primarySoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: sel ? seed : Tw.gray200),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(o.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: sel ? Tw.gray900 : Tw.gray700,
                                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                      )),
                                ),
                                if (sel) Icon(Icons.check_rounded, size: 20, color: seed),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
