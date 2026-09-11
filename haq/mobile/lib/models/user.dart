class UserData {
  final String id;
  final String nama;
  final String email;
  final String role;
  final Map<String, dynamic>? tenant;

  UserData({required this.id, required this.nama, required this.email, required this.role, this.tenant});

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        id: j['id'] as String,
        nama: j['nama'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        tenant: j['tenant'] as Map<String, dynamic>?,
      );

  String get tenantNama => (tenant?['namaPondok'] as String?) ?? '';

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN';
  bool get isPimpinan => role == 'PIMPINAN';
  bool get isUstadz => role == 'USTADZ';
  bool get isMusyrif => role == 'MUSYRIF';
  bool get isWali => role == 'WALI_SANTRI';
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  LoginResult({required this.accessToken, required this.refreshToken, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> j) => LoginResult(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        user: UserData.fromJson(j['user'] as Map<String, dynamic>),
      );
}
