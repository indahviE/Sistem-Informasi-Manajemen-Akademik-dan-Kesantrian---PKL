import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';
import { RequestUser } from '../decorators/current-user.decorator';

const MUTATION_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];

@Injectable()
export class AuditLogInterceptor implements NestInterceptor {
  constructor(private prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const method: string = req.method;
    const isMutation = MUTATION_METHODS.includes(method);
    if (!isMutation) {
      return next.handle();
    }

    const user: RequestUser | undefined = req.user;
    const entity = this.extractEntity(req.route?.path || req.originalUrl || '');

    return next.handle().pipe(
      tap({
        next: (res: any) => {
          const entityId = res?.id ?? res?.data?.id;
          this.prisma.auditLog
            .create({
              data: {
                tenantId: user?.tenantId ?? null,
                userId: user?.userId ?? null,
                userNama: user?.email ?? null,
                action: method,
                entity,
                entityId: entityId ? String(entityId) : null,
                data: {
                  url: req.originalUrl,
                  body: req.body ?? {},
                },
              },
            })
            .catch(() => {});
        },
      }),
    );
  }

  private extractEntity(url: string): string {
    const clean = url.replace(/\/([0-9a-zA-Z]+)(\/|$)/g, '/:id/');
    const seg = clean.split('?')[0];
    return seg;
  }
}