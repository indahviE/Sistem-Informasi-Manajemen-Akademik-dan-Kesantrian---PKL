// test/utils/seed-tenant.ts
//
// Bikin satu tenant dummy lengkap dengan admin + satu contoh data di
// beberapa entity utama (santri, tahun ajaran, pelanggaran), khusus untuk
// test isolasi tenant. Password sama untuk semua tenant test supaya login
// gampang; email & kodeTenant dibuat unik per-run biar test bisa diulang
// tanpa bentrok unique constraint.

import { PrismaClient, Role, TenantStatus, UserStatus } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

export const TEST_PASSWORD = 'TenantTest123!';

export interface SeededTenant {
  tenant: { id: string; kodeTenant: string };
  admin: { id: string; email: string; password: string };
  santri: { id: string };
  tahunAjaran: { id: string };
  pelanggaran: { id: string };
}

let counter = 0;

export async function seedTenant(prisma: PrismaClient, label: string): Promise<SeededTenant> {
  counter += 1;
  const unique = `${Date.now()}-${counter}`;

  const tenant = await prisma.tenant.create({
    data: {
      kodeTenant: `tst${label.toLowerCase()}${unique}`.slice(0, 40),
      namaPondok: `[TEST] Tenant ${label}`,
      status: TenantStatus.AKTIF,
    },
  });

  const passwordHash = await bcrypt.hash(TEST_PASSWORD, 10);
  const admin = await prisma.user.create({
    data: {
      tenantId: tenant.id,
      nama: `[TEST] Admin ${label}`,
      email: `admin-${label.toLowerCase()}-${unique}@test.local`,
      passwordHash,
      role: Role.ADMIN,
      status: UserStatus.AKTIF,
    },
  });

  const santri = await prisma.santri.create({
    data: {
      tenantId: tenant.id,
      nis: `NIS-${unique}`,
      nama: `[TEST] Santri ${label}`,
      jenisKelamin: 'L',
      tahunMasuk: new Date().getFullYear(),
    },
  });

  const tahunAjaran = await prisma.tahunAjaran.create({
    data: {
      tenantId: tenant.id,
      nama: `[TEST] TA-${unique}`,
      aktif: true,
    },
  });

  const pelanggaran = await prisma.pelanggaran.create({
    data: {
      tenantId: tenant.id,
      santriId: santri.id,
      jenisPelanggaran: 'Terlambat (dummy test)',
      poin: 5,
      tanggal: new Date(),
      status: 'DICATAT',
    },
  });

  return {
    tenant: { id: tenant.id, kodeTenant: tenant.kodeTenant },
    admin: { id: admin.id, email: admin.email, password: TEST_PASSWORD },
    santri: { id: santri.id },
    tahunAjaran: { id: tahunAjaran.id },
    pelanggaran: { id: pelanggaran.id },
  };
}

/** Hapus semua data dummy satu tenant test. Urutan penting karena foreign key. */
export async function cleanupTenant(prisma: PrismaClient, tenantId: string) {
  await prisma.pelanggaran.deleteMany({ where: { tenantId } });
  await prisma.santri.deleteMany({ where: { tenantId } });
  await prisma.tahunAjaran.deleteMany({ where: { tenantId } });
  await prisma.user.deleteMany({ where: { tenantId } });
  await prisma.tenant.delete({ where: { id: tenantId } });
}