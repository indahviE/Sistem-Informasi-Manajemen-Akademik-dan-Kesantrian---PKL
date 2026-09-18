import 'package:flutter/material.dart';

/// Placeholder for the Super Admin "Pengaturan" (platform settings) screen.
/// TODO: build out real content from the
/// `pengaturan_platform_saas_super_admin` design mockup.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Pengaturan Platform belum diimplementasikan.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}