import { AuditKategori } from '@prisma/client';

/** Kata kerja untuk judul otomatis dari HTTP method. */
export const VERB: Record<string, string> = {
  POST: 'Menambahkan',
  PUT: 'Memperbarui',
  PATCH: 'Memperbarui',
  DELETE: 'Menghapus',
};

/** Nama resource (segmen pertama URL setelah /api) -> label yang enak dibaca. */
export const ENTITY_LABEL: Record<string, string> = {
  tenants: 'tenant',
  users: 'pengguna',
  santri: 'santri',
  ustadz: 'ustadz',
  kelas: 'kelas',
  mapel: 'mata pelajaran',
  absensi: 'absensi',
  nilai: 'nilai',
  tahfidz: 'tahfidz',
  pelanggaran: 'pelanggaran',
  perizinan: 'perizinan',
  kesehatan: 'kesehatan',
  kunjungan: 'kunjungan',
  'tata-tertib': 'tata tertib',
  notifikasi: 'notifikasi',
  wali: 'wali santri',
  ppdb: 'PPDB',
  kurikulum: 'kurikulum',
  silabus: 'silabus',
  rpp: 'RPP',
  'rekam-medis': 'rekam medis',
  paket: 'paket',
  subscriptions: 'langganan',
  invoices: 'invoice',
  ujian: 'ujian',
  remedial: 'remedial',
  rapor: 'rapor',
  kelulusan: 'kelulusan',
  konseling: 'konseling',
  'pembinaan-karakter': 'pembinaan karakter',
  'pembinaan-ibadah': 'pembinaan ibadah',
  'keadaan-darurat': 'keadaan darurat',
  pengaturan: 'pengaturan platform',
  auth: 'autentikasi',
};

/** Kategori event berdasarkan resource. Default: DATA. */
export const KATEGORI_BY_ENTITY: Record<string, AuditKategori> = {
  paket: AuditKategori.BILLING,
  subscriptions: AuditKategori.BILLING,
  invoices: AuditKategori.BILLING,
  tenants: AuditKategori.SISTEM,
  pengaturan: AuditKategori.SISTEM,
  auth: AuditKategori.KEAMANAN,
};

/**
 * Resource yang isinya data sensitif anak (kesehatan, pelanggaran, konseling).
 * Untuk resource ini, body request TIDAK disimpan — hanya nama field yang dikirim.
 */
export const SENSITIVE_ENTITIES = new Set([
  'kesehatan',
  'rekam-medis',
  'konseling',
  'pelanggaran',
  'keadaan-darurat',
]);

const ROLE_LABEL: Record<string, string> = {
  SUPER_ADMIN: 'Super Admin (ROOT)',
  ADMIN: 'Admin Pondok',
  USTADZ: 'Ustadz / Guru',
  GURU: 'Ustadz / Guru',
  MUSYRIF: 'Musyrif Asrama',
  PIMPINAN: 'Pimpinan / Mudir',
  WALI_SANTRI: 'Wali Santri',
  SANTRI: 'Santri',
};

export function roleLabel(role?: string | null): string {
  if (!role) return 'Sistem';
  return ROLE_LABEL[role] ?? role;
}