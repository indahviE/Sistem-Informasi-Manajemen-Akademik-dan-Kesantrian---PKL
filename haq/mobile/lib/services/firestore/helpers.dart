part of '../firestore_api_client.dart';

/// Helper yang dipakai banyak modul. Jangan diedit tanpa kabar ke A.
extension Helpers on FirestoreApiClient {
  void _roles(Map<String, dynamic> me, List<String> ok) {
    if (!ok.contains(me['role'])) {
      throw ApiException(403, 'Anda tidak punya akses untuk aksi ini.');
    }
  }

  /// Kosong -> null.
  String? _nn(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Ambil tanggalnya saja, simpan sebagai ISO tengah malam UTC.
  String _tgl(dynamic v) {
    final s = (v ?? '').toString();
    if (s.length < 10 || DateTime.tryParse(s.substring(0, 10)) == null) {
      throw ApiException(400, 'Tanggal tidak valid');
    }
    return '${s.substring(0, 10)}T00:00:00Z';
  }

  /// Tanggal hari ini menurut WIB (UTC+7), bukan zona perangkat.
  String _hariIniWib() =>
      _tgl(DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String());

  /// Tanggal hari ini (jam perangkat).
  String _hariIni() => _tgl(DateTime.now().toIso8601String());

  /// Angka bulat opsional dalam rentang; null kalau tidak dikirim.
  int? _cekInt(dynamic v, String label, int min, int max) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    if (v is! num || v != v.toInt()) throw ApiException(400, '$label harus angka');
    final n = v.toInt();
    if (n < min || n > max) throw ApiException(400, '$label harus $min sampai $max');
    return n;
  }

  DateTime? _parseTgl(dynamic v) {
    final s = _nn(v);
    if (s == null) return null;
    final t = DateTime.tryParse(s);
    if (t == null) throw ApiException(400, 'Tanggal tidak valid');
    return t;
  }

  Future<void> _audit(WriteBatch b, Map<String, dynamic> me, String action, String ujianId, String judul,
      String desk, [Map<String, dynamic>? data, String tingkat = 'INFO']) async {
    b.set(await _ref('auditLog'), {
      'userId': me['userId'],
      'userNama': me['nama'],
      'userRole': me['role'],
      'action': action,
      'entity': 'Ujian',
      'entityId': ujianId,
      'kategori': 'DATA',
      'tingkat': tingkat,
      'judul': judul,
      'deskripsi': desk,
      'data': data,
      'createdAt': _now(),
    });
  }
}