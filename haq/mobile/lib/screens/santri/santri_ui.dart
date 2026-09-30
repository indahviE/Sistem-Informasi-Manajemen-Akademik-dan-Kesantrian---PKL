import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Komponen desain bersama untuk layar Santri (list, form, detail).
/// Taruh di folder yang sama dengan santri_list_screen.dart.

const String kFont = 'Nunito';

class SC {
  SC._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryEnd = Color(0xFF164E3D);
  static const gold = Color(0xFFC5A059);
  static const goldDark = Color(0xFF8A6A2B);
  static const goldSurface = Color(0xFFFAF5EC);
  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const inkMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE3F1EA);
  static const successText = Color(0xFF166534);
  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

TextStyle sty(double size, FontWeight w, Color c, {double? h, double? ls}) => TextStyle(
      fontFamily: kFont,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

const softShadow = [
  BoxShadow(color: Color(0x0D0F3A2E), blurRadius: 10, offset: Offset(0, 3)),
];

class SStatus {
  const SStatus(this.fg, this.bg);
  final Color fg;
  final Color bg;
}

SStatus statusColors(String status) {
  final up = status.toUpperCase();
  if (up == 'AKTIF') return const SStatus(SC.successText, SC.successBg);
  if (up == 'NONAKTIF' || up == 'KELUAR' || up == 'LULUS') {
    return const SStatus(SC.errorText, SC.errorBg);
  }
  return const SStatus(SC.pendingText, SC.pendingBg);
}

// ---------------------------------------------------------------------------
// Motif kisi bintang delapan (emas tipis, baris selang-seling)
// ---------------------------------------------------------------------------
class LatticePainter extends CustomPainter {
  const LatticePainter();
  static const _t = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = SC.gold.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const r = _t * 0.3;
    var row = 0;
    for (double y = -_t; y < size.height + _t; y += _t * 0.86) {
      final off = row.isOdd ? _t / 2 : 0.0;
      for (double x = -_t + off; x < size.width + _t; x += _t) {
        _star(canvas, Offset(x, y), r, p);
      }
      row++;
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final a = Path();
    final b = Path();
    for (int i = 0; i < 4; i++) {
      final a1 = (math.pi / 2) * i;
      final a2 = a1 + math.pi / 4;
      final p1 = c + Offset(math.cos(a1), math.sin(a1)) * r;
      final p2 = c + Offset(math.cos(a2), math.sin(a2)) * r;
      if (i == 0) {
        a.moveTo(p1.dx, p1.dy);
        b.moveTo(p2.dx, p2.dy);
      } else {
        a.lineTo(p1.dx, p1.dy);
        b.lineTo(p2.dx, p2.dy);
      }
    }
    a.close();
    b.close();
    canvas.drawPath(a, paint);
    canvas.drawPath(b, paint);
  }

  @override
  bool shouldRepaint(covariant LatticePainter old) => false;
}

/// Hero hijau zamrud dengan sudut bawah membulat + motif.
class HeroShell extends StatelessWidget {
  const HeroShell({super.key, required this.child, this.top = 20, this.bottom = 22});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SC.primary, SC.primaryEnd],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: LatticePainter())),
          ),
          Positioned(
            right: -56,
            top: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SC.gold.withOpacity(0.14),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class HeroBackButton extends StatelessWidget {
  const HeroBackButton({super.key, this.onDark = true});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withOpacity(0.14) : SC.surface,
          shape: BoxShape.circle,
          border: Border.all(color: onDark ? Colors.white.withOpacity(0.22) : SC.border),
        ),
        child: Icon(Icons.arrow_back_rounded, size: 20, color: onDark ? Colors.white : SC.ink),
      ),
    );
  }
}

class SPill extends StatelessWidget {
  const SPill(this.label,
      {super.key, required this.bg, required this.fg, this.icon, this.border, this.size = 10.5});

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? border;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sty(size, FontWeight.w700, fg)),
          ),
        ],
      ),
    );
  }
}

/// Avatar squircle: zamrud untuk putra, emas untuk putri.
class SantriAvatar extends StatelessWidget {
  const SantriAvatar({
    super.key,
    required this.name,
    this.gender,
    this.size = 48,
    this.onDark = false,
    this.badge = false,
  });

  final String name;
  final String? gender;
  final double size;
  final bool onDark;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final n = name.trim();
    final initial = n.isEmpty || n == '-' ? '?' : n[0].toUpperCase();
    final female = gender?.toUpperCase() == 'P';
    final bg = onDark ? SC.mint : (female ? SC.goldSurface : SC.sage);
    final fg = onDark ? SC.primary : (female ? SC.goldDark : SC.primary);

    final box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: onDark ? Border.all(color: SC.gold.withOpacity(0.75), width: 1.6) : null,
      ),
      child: Text(initial, style: sty(size * 0.4, FontWeight.w800, fg)),
    );

    if (!badge || gender == null || gender!.isEmpty) return box;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          box,
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: female ? SC.gold : SC.primary,
                shape: BoxShape.circle,
                border: Border.all(color: SC.surface, width: 2),
              ),
              child: Icon(female ? Icons.female_rounded : Icons.male_rounded,
                  size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}