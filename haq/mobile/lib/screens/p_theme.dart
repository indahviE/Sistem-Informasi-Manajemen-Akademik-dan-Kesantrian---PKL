import 'package:flutter/material.dart';
import 'santri/santri_ui.dart' show SC;
import 'signup_screen.dart' as sg show PColors;

/// Palet bersama: warna utama ikut branding pondok (SC),
/// sisanya tetap dari PColors asli.
class PTheme {
  PTheme._();
  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static Color get sage => SC.sage;
  static Color get mint => SC.mint;
  static const background = sg.PColors.background;
  static const surface = sg.PColors.surface;
  static const ink = sg.PColors.ink;
  static const inkSecondary = sg.PColors.inkSecondary;
}