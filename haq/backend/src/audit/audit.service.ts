import { Injectable, Logger } from '@nestjs/common';
import { AuditKategori, AuditLog, AuditTingkat, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { VERB, roleLabel } from './audit.util';

export interface AuditLogInput {
  action: string; // kode event, mis. LOGIN_GAGAL, TENANT_APPROVE, atau HTTP method dari interceptor
  entity: string; // resource, mis. 'tenants', 'auth'
  entityId?: string | null;
  kategori?: AuditKategori;
  tingkat?: AuditTingkat;
  judul?: string;
  /** Teks di antara backtick (`...`) dirender monospace di aplikasi. */
  deskripsi?: string;
  /** Label kecil di footer kartu, mis. "Rate limit aktif". */
  meta?: string;
  tenantId?: string | null;
  userId?: string | null;
  userNama?: string | null;
  userRole?: string | null;
  ip?: string | null;
  data?: Prisma.InputJsonValue;
}

export interface ListAuditParams {
  q?: string;
  kategori?: string;
  tingkat?: string;
  tenantId?: string;
  hari?: string; // jumlah hari ke belakang; 0/kosong = semua waktu
  cursor?: string;
  limit?: string;
}

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Catat satu event. TIDAK PERNAH melempar error — kegagalan audit tidak
   * boleh menggagalkan operasi bisnis yang sedang berjalan.
   */
  async log(input: AuditLogInput): Promise<void> {
    try {
      let userNama = input.userNama ?? null;
      let userRole = input.userRole ?? null;

      // Kalau hanya userId yang diberikan, lengkapi nama & role dari tabel user.
      if (input.userId && (!userNama || !userRole)) {
        const u = await this.prisma.user.findUnique({
          where: { id: input.userId },
          select: { nama: true, role: true },
        });
        userNama = userNama ?? u?.nama ?? null;
        userRole = userRole ?? (u?.role ? String(u.role) : null);
      }

      await this.prisma.auditLog.create({
        data: {
          tenantId: input.tenantId ?? null,
          userId: input.userId ?? null,
          userNama,
          userRole,
          action: input.action,
          entity: input.entity,
          entityId: input.entityId ?? null,
          kategori: input.kategori ?? AuditKategori.DATA,
          tingkat: input.tingkat ?? AuditTingkat.INFO,
          judul: input.judul ?? null,
          deskripsi: input.deskripsi ?? null,
          meta: input.meta ?? null,
          ip: input.ip ?? null,
          data: input.data,
        },
      });
    } catch (e) {
      this.logger.warn(`Gagal mencatat audit log (${input.action}): ${(e as Error).message}`);
    }
  }

  async list(p: ListAuditParams) {
    const limit = Math.min(Math.max(parseInt(p.limit ?? '20', 10) || 20, 1), 100);

    const where: Prisma.AuditLogWhereInput = {};

    if (p.kategori && (Object.values(AuditKategori) as string[]).includes(p.kategori)) {
      where.kategori = p.kategori as AuditKategori;
    }
    if (p.tingkat && (Object.values(AuditTingkat) as string[]).includes(p.tingkat)) {
      where.tingkat = p.tingkat as AuditTingkat;
    }
    if (p.tenantId) where.tenantId = p.tenantId;

    const hari = parseInt(p.hari ?? '0', 10) || 0;
    if (hari > 0) {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      start.setDate(start.getDate() - (hari - 1));
      where.createdAt = { gte: start };
    }

    const q = p.q?.trim();
    if (q) {
      where.OR = [
        { judul: { contains: q } },
        { deskripsi: { contains: q } },
        { userNama: { contains: q } },
        { ip: { contains: q } },
        { action: { contains: q } },
        { entity: { contains: q } },
      ];
    }

    const [rows, totalFilter, totalSemua, totalKeamanan] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: limit + 1,
        ...(p.cursor ? { cursor: { id: p.cursor }, skip: 1 } : {}),
      }),
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.count(),
      this.prisma.auditLog.count({ where: { kategori: AuditKategori.KEAMANAN } }),
    ]);

    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    return {
      items: await this.toDtos(page),
      nextCursor: hasMore ? page[page.length - 1].id : null,
      totalFilter,
      totalSemua,
      totalKeamanan,
    };
  }

  /** Event terbaru yang bukan mutasi data rutin — untuk kartu di dashboard. */
  async recent(n = 3) {
    const rows = await this.prisma.auditLog.findMany({
      where: { kategori: { not: AuditKategori.DATA } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: n,
    });
    return this.toDtos(rows);
  }

  // -------------------------------------------------------------------------

  private async toDtos(rows: AuditLog[]) {
    const ids = [...new Set(rows.map((r) => r.tenantId).filter((x): x is string => !!x))];
    const tenants = ids.length
      ? await this.prisma.tenant.findMany({
          where: { id: { in: ids } },
          select: { id: true, namaPondok: true, kodeTenant: true },
        })
      : [];
    const tenantMap = new Map(tenants.map((t) => [t.id, t]));

    return rows.map((r) => {
      const t = r.tenantId ? tenantMap.get(r.tenantId) : undefined;

      // Pelaku: untuk event login (belum ada user), tampilkan sumbernya.
      let aktor = roleLabel(r.userRole);
      let aktorDetail: string | null = r.userNama;
      if (r.action === 'LOGIN_BRUTE_FORCE') {
        aktor = 'Brute Force Alert';
        aktorDetail = r.ip;
      } else if (r.action === 'LOGIN_GAGAL') {
        aktor = 'Autentikasi';
        aktorDetail = r.ip;
      }

      return {
        id: r.id,
        aksi: r.action,
        judul: r.judul ?? `${VERB[r.action] ?? r.action} data ${r.entity}`,
        aktor,
        aktorDetail,
        tingkat: r.tingkat,
        kategori: r.kategori,
        waktu: r.createdAt.toISOString(),
        tenantId: r.tenantId,
        tenantNama: t?.namaPondok ?? 'Platform SIMPesantren',
        tenantHandle: t ? `@${t.kodeTenant}` : '@platform',
        deskripsi: r.deskripsi ?? '',
        meta: r.meta,
        ip: r.ip,
        data: r.data,
      };
    });
  }
}