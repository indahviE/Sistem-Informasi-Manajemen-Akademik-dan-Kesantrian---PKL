import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Role } from '@prisma/client';

export interface RequestUser {
  userId: string;
  email: string;
  role: Role;
  tenantId?: string;
  tenantKode?: string;
  tenantStatus?: string;
}

export const CurrentUser = createParamDecorator(
  (field: keyof RequestUser | undefined, ctx: ExecutionContext): RequestUser | any => {
    const req = ctx.switchToHttp().getRequest();
    const user: RequestUser = req.user;
    if (field) {
      return user?.[field];
    }
    return user;
  },
);

export const TenantId = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string | undefined => {
    const req = ctx.switchToHttp().getRequest();
    return req.user?.tenantId;
  },
);