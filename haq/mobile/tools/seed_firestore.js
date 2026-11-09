// Seed Firebase (Auth + Firestore) dari data demo yang sama dengan prisma seed.
// Aman dijalankan berulang: akun yang sudah ada dipakai ulang, dokumen ditimpa.
//
// Jalankan dari folder tools:
//   npm init -y
//   npm i firebase-admin
//   node seed_firestore.js
//
// Butuh file serviceAccountKey.json di folder yang sama (JANGAN di-commit ke git).

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const auth = getAuth();
const db = getFirestore();

const T = 'mahad-alquran';
const now = new Date().toISOString();
const tenantInfo = {
  id: T,
  kodeTenant: T,
  namaPondok: "Ma'had Al-Qur'an Wal Lughah",
  status: 'AKTIF',
};

async function ensureUser(email, password, nama) {
  try {
    return (await auth.getUserByEmail(email)).uid;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    return (await auth.createUser({ email, password, displayName: nama })).uid;
  }
}

async function main() {
  console.log('Mulai seeding Firebase...');

  // ---------- akun login (Firebase Auth) ----------
  const uid = {
    superadmin: await ensureUser('superadmin@sistempesantren.com', 'superadmin123', 'Super Admin Platform'),
    admin: await ensureUser('admin@mahad.id', 'admin123', 'Admin Pondok'),
    ustadz: await ensureUser('ustadz@mahad.id', 'admin123', 'Ustadz Ahmad'),
    musyrif: await ensureUser('musyrif@mahad.id', 'admin123', 'Musyrif Ali'),
    mudir: await ensureUser('mudir@mahad.id', 'admin123', 'Mudir Pondok'),
    wali: await ensureUser('wali@mahad.id', 'admin123', 'H. Budi Santoso'),
  };
  console.log('Akun Auth siap.');

  const b = db.batch();
  const tenantRef = db.collection('tenants').doc(T);
  const col = (name) => tenantRef.collection(name);

  // ---------- tenant ----------
  b.set(tenantRef, {
    kodeTenant: T,
    namaPondok: tenantInfo.namaPondok,
    status: 'AKTIF',
    adminAwalId: uid.admin,
    createdAt: now,
  });

  // ---------- users/{uid} ----------
  const userDoc = (u, nama, email, role, extra = {}) =>
    b.set(db.collection('users').doc(u), {
      nama, email, role, status: 'AKTIF',
      tenantId: T, tenant: tenantInfo,
      kelasIds: [], waliKelasIds: [],
      ...extra,
    });

  // Super admin: level platform, tanpa tenant.
  b.set(db.collection('users').doc(uid.superadmin), {
    nama: 'Super Admin Platform', email: 'superadmin@sistempesantren.com',
    role: 'SUPER_ADMIN', status: 'AKTIF', tenantId: null, tenant: null,
    kelasIds: [], waliKelasIds: [],
  });
  userDoc(uid.admin, 'Admin Pondok', 'admin@mahad.id', 'ADMIN');
  userDoc(uid.ustadz, 'Ustadz Ahmad', 'ustadz@mahad.id', 'USTADZ',
    { ustadzId: 'ustadz-ahmad', kelasIds: ['kelas-7a'], waliKelasIds: ['kelas-7a'] });
  userDoc(uid.musyrif, 'Musyrif Ali', 'musyrif@mahad.id', 'MUSYRIF',
    { ustadzId: 'musyrif-ali', kelasIds: ['kelas-7b'], waliKelasIds: ['kelas-7b'] });
  userDoc(uid.mudir, 'Mudir Pondok', 'mudir@mahad.id', 'PIMPINAN');
  userDoc(uid.wali, 'H. Budi Santoso', 'wali@mahad.id', 'WALI_SANTRI',
    { santriIds: ['2026001', '2026002'] });

  // ---------- tahun ajaran ----------
  b.set(col('tahunAjaran').doc('ta-2026-2027'), { nama: '2026/2027', aktif: true, createdAt: now });

  // ---------- ustadz ----------
  b.set(col('ustadz').doc('ustadz-ahmad'), { nama: 'Ustadz Ahmad', jenis: 'GURU', userId: uid.ustadz, createdAt: now });
  b.set(col('ustadz').doc('ustadzah-siti'), { nama: 'Ustadzah Siti', jenis: 'GURU', createdAt: now });
  b.set(col('ustadz').doc('musyrif-ali'), { nama: 'Musyrif Ali', jenis: 'MUSYRIF', userId: uid.musyrif, createdAt: now });

  // ---------- mapel ----------
  b.set(col('mapel').doc('mapel-tahfidz'), { namaMapel: "Tahfidzul Qur'an", jenis: 'TAHFIDZ', createdAt: now });
  b.set(col('mapel').doc('mapel-arab'), { namaMapel: 'Bahasa Arab', jenis: 'BAHASA_ARAB', createdAt: now });
  b.set(col('mapel').doc('mapel-fiqih'), { namaMapel: 'Fiqih Ibadah', createdAt: now });

  // ---------- kelas ----------
  b.set(col('kelas').doc('kelas-7a'), {
    namaKelas: '7A', tingkat: '7', waliKelasId: 'ustadz-ahmad', tahunAjaranId: 'ta-2026-2027', createdAt: now,
  });
  b.set(col('kelas').doc('kelas-7b'), {
    namaKelas: '7B', tingkat: '7', waliKelasId: 'musyrif-ali', tahunAjaranId: 'ta-2026-2027', createdAt: now,
  });

  // ---------- wali ----------
  b.set(col('wali').doc('wali-budi'), { nama: 'H. Budi Santoso', noHp: '08123456789', hubungan: 'Ayah', userId: uid.wali, createdAt: now });
  b.set(col('wali').doc('wali-siti'), { nama: 'Ibu Siti Rahma', noHp: '08987654321', hubungan: 'Ibu', createdAt: now });

  // ---------- santri (ID dokumen = NIS) ----------
  const santri = [
    { nis: '2026001', nama: 'Muhammad Fathir', jenisKelamin: 'L', tanggalLahir: '2012-03-15', kelasId: 'kelas-7a', asrama: 'Putra', waliId: 'wali-budi' },
    { nis: '2026002', nama: 'Abdullah Hasan', jenisKelamin: 'L', tanggalLahir: '2012-07-20', kelasId: 'kelas-7a', asrama: 'Putra', waliId: 'wali-budi' },
    { nis: '2026003', nama: 'Aisyah Nur', jenisKelamin: 'P', tanggalLahir: '2012-01-10', kelasId: 'kelas-7b', asrama: 'Putri', waliId: 'wali-siti' },
  ];
  for (const s of santri) {
    b.set(col('santri').doc(s.nis), { ...s, tahunMasuk: 2026, status: 'AKTIF', createdAt: now });
  }

  // Counter NIS otomatis: nomor pertama setelah seed = 20260001 (tidak bentrok dgn 2026001).
  b.set(col('counters').doc('santri_2026'), { n: 0 });

  await b.commit();

  console.log('Seeding selesai. Tenant demo (kode pondok: ' + T + ')');
  console.log('  Admin   : admin@mahad.id / admin123');
  console.log('  Ustadz  : ustadz@mahad.id / admin123');
  console.log('  Musyrif : musyrif@mahad.id / admin123');
  console.log('  Mudir   : mudir@mahad.id / admin123');
  console.log('  Wali    : wali@mahad.id / admin123');
  console.log('  Super   : superadmin@sistempesantren.com / superadmin123');
}

main().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });