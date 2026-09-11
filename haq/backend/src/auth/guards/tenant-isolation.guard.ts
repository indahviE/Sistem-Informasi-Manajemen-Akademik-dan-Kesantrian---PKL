import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../../common/decorators/roles.decorator';
import { RequestUser } from '../../common/decorators/current-user.decorator';
import { Role, TenantStatus } from '@prisma/client';

@Injectable()
export class TenantIsolationGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const user: RequestUser | undefined = req.user;
    if (!user) {
      return true; // handled by JwtAuthGuard
    }

    if (user.role === Role.SUPER_ADMIN) {
      return true; // Super Admin operates at platform level, no tenant scoping
    }

    if (!user.tenantId) {
      throw new ForbiddenException(
        'Akun ini tidak terikat ke pondok mana pun. Hubungi administrator.',
      );
    }

    if (user.tenantStatus && user.tenantStatus !== TenantStatus.AKTIF) {
      throw new ForbiddenException(
        'Pondok Anda belum aktif. Hubungi Super Admin untuk aktivasi.',
      );
    }

    return true;
  }
}