import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

// Design Colors
const Color _primaryColor = Color(0xFF0F3A2E);
const Color _surfaceColor = Color(0xFFFAF9F5);
const Color _borderColor = Color(0xFFEAE6DC);
const Color _gray600 = Color(0xFF697278);

class BillingInvoiceScreen extends StatefulWidget {
  const BillingInvoiceScreen({super.key});

  @override
  State<BillingInvoiceScreen> createState() => _BillingInvoiceScreenState();
}

class _BillingInvoiceScreenState extends State<BillingInvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text('Tagihan & Invoice'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _InvoiceListTab(),
        ),
      ),
    );
  }
}

class _InvoiceListTab extends StatefulWidget {
  @override
  State<_InvoiceListTab> createState() => _InvoiceListTabState();
}

class _InvoiceListTabState extends State<_InvoiceListTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final invoices = await api.get(ApiUrl.invoices);
      if (!mounted) return;
      setState(() {
        _items = (invoices as List);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      // Tangkap error selain ApiException (mis. koneksi gagal, CORS,
      // format response tidak sesuai, dll) supaya UI tidak stuck loading.
      if (mounted) setState(() {
        _error = 'Terjadi kesalahan saat memuat data: $e';
        _loading = false;
      });
    }
  }

  String _rupiah(num v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  void _showInvoiceDetail(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InvoiceDetailModal(
        invoice: invoice,
        rupiah: _rupiah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? loadingView()
        : _error != null
            ? errorView(_error!, _load)
            : _items.isEmpty
                ? emptyView('Belum ada tagihan.')
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Tagihan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelola dan monitor semua invoice dari pondok',
                            style: TextStyle(
                              fontSize: 13,
                              color: _gray600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          ..._items.map((item) {
                            final inv = item as Map<String, dynamic>;
                            final invoiceNo = inv['nomorInvoice'] as String? ?? 'INV-2025-001';
                            final tenant = inv['tenant'] as Map<String, dynamic>? ?? {};
                            final tenantName = tenant['namaPondok'] as String? ?? 'Pondok';
                            final slug = tenant['slug'] as String? ?? '';
                            final amount = inv['nominal'] as num? ?? 0;
                            final status = inv['status'] as String? ?? 'PENDING';
                            final dueDate = (inv['tanggalJatuhTempo'] as String?)?.split('T').first ?? '-';

                            return GestureDetector(
                              onTap: () => _showInvoiceDetail(inv),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: status == 'LUNAS'
                                                ? const Color(0xFFE8F5E9)
                                                : status == 'EXPIRED'
                                                    ? const Color(0xFFFFF8E1)
                                                    : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long,
                                            color: status == 'LUNAS'
                                                ? const Color(0xFF1B5E20)
                                                : status == 'EXPIRED'
                                                    ? const Color(0xFFB78103)
                                                    : const Color(0xFF991B1B),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                invoiceNo,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF697278),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              GestureDetector(
                                                onTap: () => _showInvoiceDetail(inv),
                                                child: Text(
                                                  tenantName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1B1C1A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Slug: $slug',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _gray600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: status == 'LUNAS'
                                                    ? const Color(0xFFE8F5E9)
                                                    : status == 'EXPIRED'
                                                        ? const Color(0xFFFFF8E1)
                                                        : const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: status == 'LUNAS'
                                                      ? const Color(0xFF1B5E20)
                                                      : status == 'EXPIRED'
                                                          ? const Color(0xFFB78103)
                                                          : const Color(0xFF991B1B),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Jatuh tempo: $dueDate',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _gray600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Total: ${_rupiah(amount)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          
                          const SizedBox(height: 88),
                        ],
                      ),
                    ),
                  );
  }
}

class InvoiceDetailModal extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final String Function(num) rupiah;

  const InvoiceDetailModal({
    required this.invoice,
    required this.rupiah,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceNo = invoice['nomorInvoice'] as String? ?? 'INV-2025-001';
    final tenant = invoice['tenant'] as Map<String, dynamic>? ?? {};
    final tenantName = tenant['namaPondok'] as String? ?? 'Pondok';
    final slug = tenant['slug'] as String? ?? '';
    final pic = tenant['pic'] as String? ?? 'PIC';
    final phone = tenant['noTelpon'] as String? ?? '-';
    final startDate = (invoice['tanggalMulai'] as String?)?.split('T').first ?? '-';
    final endDate = (invoice['tanggalBerakhir'] as String?)?.split('T').first ?? '-';
    final amount = invoice['nominal'] as num? ?? 0;
    final status = invoice['status'] as String? ?? 'PENDING';
    final description = invoice['deskripsi'] as String? ?? '';
    final method = invoice['metode'] as String? ?? 'Transfer Manual Bank BSI';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceNo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4693F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Slug: $slug',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF697278),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'LUNAS'
                        ? const Color(0xFFE8F5E9)
                        : status == 'EXPIRED'
                            ? const Color(0xFFFFF8E1)
                            : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status == 'LUNAS'
                          ? const Color(0xFF1B5E20)
                          : status == 'EXPIRED'
                              ? const Color(0xFFB78103)
                              : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tenant Details
            _DetailSection(
              title: 'TENANT PEMBAYAR',
              items: [
                ('Nama', tenantName),
                ('Slug', slug),
                ('PIC', pic),
                ('No. Telepon', phone),
                ('Periode Tagihan', '$startDate - $endDate'),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAE6DC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBTOTAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _gray600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rupiah(amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F3A2E),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _gray600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rupiah(amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F3A2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode: $method',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB78103),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: _gray600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email invoice dikirim ke admin tenant')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3A2E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.email),
                label: const Text('Kirim Uang ke Email Admin Tenant'),
              ),
            ),
            const SizedBox(height: 12),

            // Suspend Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Langganan disuspend')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Tw.red,
                  side: const BorderSide(color: Tw.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Suspend'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _DetailSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _gray600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final (label, value) = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: const Color(0xFF0F3A2E).withOpacity(0.3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 10, color: _gray600),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1B1C1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}