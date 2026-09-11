import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { Role, TenantStatus, UserStatus } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
  ) {}

  async login(kodeTenant: string | undefined, email: string, password: string) {
    const user = await this.prisma.user.findFirst({
      where: { email, ...(kodeTenant ? { tenant: { kodeTenant } } : { tenantId: null }) },
      include: { tenant: true },
    });

    if (!user) {
      throw new UnauthorizedException('Email, password, atau kode tenant salah.');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
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