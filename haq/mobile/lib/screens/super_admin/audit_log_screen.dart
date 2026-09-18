import 'package:flutter/material.dart';

/// Placeholder for the Super Admin "Audit Log" screen.
/// TODO: build out real content from the
/// `audit_log_platform_saas_super_admin` design mockup
/// (security alerts, login attempts, tenant mutation log, etc).
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Audit Log belum diimplementasikan.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}