import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { AuditKategori, AuditTingkat, Role, TenantStatus, UserStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';

/** Batas login gagal per (email + IP) dalam satu jendela waktu. */
const MAX_LOGIN_GAGAL = 5;
const JENDELA_MENIT = 30;

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private audit: AuditService,
  ) {}

  async login(kodeTenant: string | undefined, email: string, password: string, ip?: string) {
    await this.pastikanTidakTerkunci(email, ip);

    const user = await this.prisma.user.findFirst({
      where: { email, ...(kodeTenant ? { tenant: { kodeTenant } } : { tenantId: null }) },
      include: { tenant: true },
    });

    if (!user) {
      await this.catatLoginGagal(kodeTenant, email, ip, 'akun tidak ditemukan');
      throw new UnauthorizedException('Email, password, atau kode tenant salah.');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      await this.catatLoginGagal(kodeTenant, email, ip, 'password salah');
      throw new UnauthorizedException('Email, password, atau kode tenant salah.');
    }

    if (user.status !== UserStatus.AKTIF) {
      throw new UnauthorizedException('Akun tidak aktif.');
    }

    if (user.role !== Role.SUPER_ADMIN && user.tenant?.status !== TenantStatus.AKTIF) {
      throw new ForbiddenException(
        'Pondok belum aktif. Hubungi Super Admin untuk aktivasi.',
      );
    }

    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      tenantId: user.tenantId,
      tenantKode: user.tenant?.kodeTenant,
      tenantStatus: user.tenant?.status,
    };

    const tokens = await this.generateTokens(payload);

    // Login Super Admin selalu dicatat (akses ROOT). Login user biasa tidak,
    // supaya log tidak dibanjiri.
    if (user.role === Role.SUPER_ADMIN) {
      await this.audit.log({
        action: 'LOGIN_SUPER_ADMIN',
        entity: 'auth',
        kategori: AuditKategori.KEAMANAN,
        tingkat: AuditTingkat.INFO,
        judul: 'Login Super Admin',
        deskripsi: `Akun ROOT \`${user.email}\` berhasil login.`,
        userId: user.id,
        userRole: String(user.role),
        ip,
      });
    }

    return {
      ...tokens,
      user: {
        id: user.id,
        nama: user.nama,
        email: user.email,
        role: user.role,
        tenant: user.tenant
          ? {
              id: user.tenant.id,
              namaPondok: user.tenant.namaPondok,
              kodeTenant: user.tenant.kodeTenant,
              status: user.tenant.status,
            }
          : null,
      },
    };
  }

  async refresh(refreshToken: string) {
    let payload: any;
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET,
      });
    } catch {
      throw new UnauthorizedException('Refresh token tidak valid.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { tenant: true },
    });
    if (!user || user.status !== UserStatus.AKTIF) {
      throw new UnauthorizedException('Akun tidak aktif.');
    }

    const newPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      tenantId: user.tenantId,
      tenantKode: user.tenant?.kodeTenant,
      tenantStatus: user.tenant?.status,
    };

    return this.generateTokens(newPayload);
  }

  async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('User tidak ditemukan.');

    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) throw new BadRequestException('Password saat ini salah.');

    const hash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash: hash } });
    return { message: 'Password berhasil diubah.' };
  }

  // -------------------------------------------------------------------------
  // Proteksi brute force + pencatatan audit
  // -------------------------------------------------------------------------

  private async hitungLoginGagal(email: string, ip?: string) {
    const sejak = new Date(Date.now() - JENDELA_MENIT * 60 * 1000);
    return this.prisma.auditLog.count({
      where: {
        action: 'LOGIN_GAGAL',
        userNama: email.trim().toLowerCase(),
        ...(ip ? { ip } : {}),
        createdAt: { gte: sejak },
      },
    });
  }

  /** Tolak login bila akun ini sudah gagal >= MAX kali dari IP yang sama dalam jendela waktu. */
  private async pastikanTidakTerkunci(email: string, ip?: string) {
    const jumlah = await this.hitungLoginGagal(email, ip);
    if (jumlah >= MAX_LOGIN_GAGAL) {
      throw new HttpException(
        `Terlalu banyak percobaan login gagal. Coba lagi dalam ${JENDELA_MENIT} menit.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async catatLoginGagal(
    kodeTenant: string | undefined,
    email: string,
    ip: string | undefined,
    alasan: string,
  ) {
    const emailNorm = email.trim().toLowerCase();
    const tenant = kodeTenant
      ? await this.prisma.tenant.findUnique({ where: { kodeTenant }, select: { id: true } })
      : null;

    await this.audit.log({
      action: 'LOGIN_GAGAL',
      entity: 'auth',
      kategori: AuditKategori.KEAMANAN,
      tingkat: AuditTingkat.INFO,
      judul: 'Login Gagal',
      deskripsi: `Percobaan login gagal untuk akun \`${emailNorm}\`.`,
      meta: ip ? `IP ${ip}` : undefined,
      tenantId: tenant?.id ?? null,
      userNama: emailNorm, // email yang dicoba; dipakai untuk menghitung percobaan
      ip,
      data: { alasan, kodeTenant: kodeTenant ?? null },
    });

    // Tepat saat mencapai batas, catat satu event peringatan.
    const jumlah = await this.hitungLoginGagal(email, ip);
    if (jumlah === MAX_LOGIN_GAGAL) {
      await this.audit.log({
        action: 'LOGIN_BRUTE_FORCE',
        entity: 'auth',
        kategori: AuditKategori.KEAMANAN,
        tingkat: AuditTingkat.WARNING,
        judul: 'Percobaan Login Gagal Berulang',
        deskripsi: `${MAX_LOGIN_GAGAL}x gagal sandi dalam ${JENDELA_MENIT} menit pada akun \`${emailNorm}\`. Login dari IP ini untuk akun tersebut diblokir selama ${JENDELA_MENIT} menit.`,
        meta: 'Rate limit aktif',
        tenantId: tenant?.id ?? null,
        userNama: emailNorm,
        ip,
      });
    }
  }

  private async generateTokens(payload: any) {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload, {
        secret: process.env.JWT_ACCESS_SECRET,
        expiresIn: process.env.JWT_ACCESS_EXPIRES || '15m',
      }),
      this.jwt.signAsync({ sub: payload.sub }, {
        secret: process.env.JWT_REFRESH_SECRET,
        expiresIn: process.env.JWT_REFRESH_EXPIRES || '30d',
      }),
    ]);
    return { accessToken, refreshToken };
  }
}