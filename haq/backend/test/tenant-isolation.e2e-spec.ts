// test/tenant-isolation.e2e-spec.ts
//
// PRD bagian 8 (Non-Functional Requirements) eksplisit menyebut isolasi
// data antar tenant sebagai requirement WAJIB dan risiko kritis.
//
// Test ini login sebagai admin tenant A dan tenant B (bukan Super Admin,
// yang memang legitimate akses semua tenant), lalu pastikan admin tenant B
// TIDAK PERNAH bisa:
//   1. melihat data tenant A muncul di list-nya sendiri,
//   2. mengambil data tenant A langsung lewat id (harus 404, bukan bocor),
//   3. mengubah/menghapus data tenant A lewat id.
//
// Termasuk regression test khusus untuk bug yang pernah ditemukan di
// POST /tahun-ajaran/:id/aktif (master-data.service.ts).

import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupTenant, seedTenant, SeededTenant } from './utils/seed-tenant';

describe('Isolasi data antar tenant (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tenantA: SeededTenant;
  let tenantB: SeededTenant;
  let tokenB: string; // "penyerang" di semua test: coba akses data tenant A

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true, stopAtFirstError: true }),
    );
    await app.init();

    prisma = app.get(PrismaService);

    tenantA = await seedTenant(prisma, 'A');
    tenantB = await seedTenant(prisma, 'B');

    tokenB = await login(tenantB.tenant.kodeTenant, tenantB.admin.email, tenantB.admin.password);
  });

  afterAll(async () => {
    await cleanupTenant(prisma, tenantA.tenant.id);
    await cleanupTenant(prisma, tenantB.tenant.id);
    await app.close();
  });

  async function login(kodeTenant: string, email: string, password: string): Promise<string> {
    const res = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ kodeTenant, email, password });
    if (res.status >= 300) {
      throw new Error(`Login gagal untuk ${email}: ${res.status} ${JSON.stringify(res.body)}`);
    }
    return res.body.accessToken as string;
  }

  describe('Santri', () => {
    it('list santri (tenant B) tidak berisi santri tenant A', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/santri')
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.status).toBe(200);
      const ids = (res.body.items ?? []).map((s: any) => s.id);
      expect(ids).not.toContain(tenantA.santri.id);
    });

    it('GET /santri/:id milik tenant lain -> 404 (bukan bocor datanya)', async () => {
      const res = await request(app.getHttpServer())
        .get(`/api/santri/${tenantA.santri.id}`)
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.status).toBe(404);
    });

    it('PATCH /santri/:id milik tenant lain -> 404, data tenant A tidak berubah', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/santri/${tenantA.santri.id}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ nama: 'DIUBAH PAKSA TENANT LAIN' });

      expect(res.status).toBe(404);

      const masihAsli = await prisma.santri.findUnique({ where: { id: tenantA.santri.id } });
      expect(masihAsli?.nama).not.toBe('DIUBAH PAKSA TENANT LAIN');
    });

    it('DELETE /santri/:id milik tenant lain -> 404, data tenant A tidak terhapus', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/api/santri/${tenantA.santri.id}`)
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.status).toBe(404);

      const masihAda = await prisma.santri.findUnique({ where: { id: tenantA.santri.id } });
      expect(masihAda).not.toBeNull();
    });
  });

  describe('Pelanggaran', () => {
    it('list pelanggaran (tenant B) tidak berisi pelanggaran tenant A', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/pelanggaran')
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.status).toBe(200);
      const ids = (Array.isArray(res.body) ? res.body : []).map((p: any) => p.id);
      expect(ids).not.toContain(tenantA.pelanggaran.id);
    });

    it('PATCH /pelanggaran/:id milik tenant lain -> 404, poin tenant A tidak berubah', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/pelanggaran/${tenantA.pelanggaran.id}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ poin: 999 });

      expect(res.status).toBe(404);

      const masihAsli = await prisma.pelanggaran.findUnique({
        where: { id: tenantA.pelanggaran.id },
      });
      expect(masihAsli?.poin).not.toBe(999);
    });
  });

  describe('Tahun Ajaran', () => {
    it('list tahun-ajaran (tenant B) tidak berisi tahun ajaran tenant A', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/tahun-ajaran')
        .set('Authorization', `Bearer ${tokenB}`);

      expect(res.status).toBe(200);
      const ids = (Array.isArray(res.body) ? res.body : []).map((t: any) => t.id);
      expect(ids).not.toContain(tenantA.tahunAjaran.id);
    });

    it('[REGRESSION] POST /tahun-ajaran/:id/aktif milik tenant lain -> 404, TIDAK mengaktifkan tahun ajaran tenant lain', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/tahun-ajaran/${tenantA.tahunAjaran.id}/aktif`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send();

      expect(res.status).toBe(404);

      const tahunAjaranA = await prisma.tahunAjaran.findUnique({
        where: { id: tenantA.tahunAjaran.id },
      });
      expect(tahunAjaranA?.aktif).toBe(true);
    });
  });
});