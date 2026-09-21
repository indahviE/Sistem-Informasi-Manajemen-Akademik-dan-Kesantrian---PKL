import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { AuditKategori, AuditTingkat } from '@prisma/client';
import { Observable, tap } from 'rxjs';
import { AuditService } from '../../audit/audit.service';
import {
  ENTITY_LABEL,
  KATEGORI_BY_ENTITY,
  SENSITIVE_ENTITIES,
  VERB,
} from '../../audit/audit.util';
import { RequestUser } from '../decorators/current-user.decorator';

const MUTATION_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];

/**
 * Route yang dicatat MANUAL lewat AuditService (dengan konteks lebih kaya),
 * jadi dilewati di sini supaya tidak tercatat dua kali.
 */
const SKIP_ROUTES = [
  '/auth/login',
  '/auth/refresh',
  '/tenants/signup',
  '/tenants/approve',
  '/tenants/suspend',
];

/** Judul & kategori khusus untuk route tertentu ("METHOD /path"). */
const ROUTE_OVERRIDES: Record<string, { judul: string; kategori: AuditKategori }> = {
  'POST /auth/change-password': {
    judul: 'Perubahan Password',
    kategori: AuditKategori.KEAMANAN,
  },
};

/** Field dengan nama seperti ini tidak pernah disimpan nilainya. */
const REDACT_KEY = /pass|token|secret|authorization|credential|kredensial/i;

function sanitize(v: any, depth = 0): any {
  if (v === null || v === undefined) return v;
  if (depth > 4) return '[...]';
  if (typeof v === 'string') return v.length > 300 ? `${v.slice(0, 300)}…` : v;
  if (Array.isArray(v)) {
    const out = v.slice(0, 10).map((x) => sanitize(x, depth + 1));
    if (v.length > 10) out.push(`[+${v.length - 10} item lainnya]`);
    return out;
  }
  if (typeof v === 'object') {
    const out: Record<string, any> = {};
    for (const [k, val] of Object.entries(v)) {
      out[k] = REDACT_KEY.test(k) ? '[REDACTED]' : sanitize(val, depth + 1);
    }
    return out;
  }
  return v;
}

@Injectable()
export class AuditLogInterceptor implements NestInterceptor {
  constructor(private audit: AuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const method: string = req.method;

    if (!MUTATION_METHODS.includes(method)) {
      return next.handle();
    }

    const routePath: string = req.route?.path ?? (req.originalUrl ?? '').split('?')[0];
    if (SKIP_ROUTES.some((r) => routePath.endsWith(r))) {
      return next.handle();
    }

    const user: RequestUser | undefined = req.user;
    // '/api/paket/:id' -> 'paket'
    const segments = routePath.split('/').filter(Boolean);
    const entity = (segments[0] === 'api' ? segments[1] : segments[0]) ?? 'unknown';

    return next.handle().pipe(
      tap({
        next: (res: any) => {
          const body = req.body ?? {};
          const entityId = res?.id ?? res?.data?.id ?? req.params?.id;

          // Super Admin tidak punya tenantId sendiri; ambil tenant yang dituju
          // dari body (mis. buat invoice) atau dari hasil (mis. update invoice).
          const targetTenant =
            typeof body?.tenantId === 'string'
              ? body.tenantId
              : typeof res?.tenantId === 'string'
                ? res.tenantId
                : null;
          const tenantId = user?.tenantId ?? targetTenant;

          const override = ROUTE_OVERRIDES[`${method} ${routePath.replace(/^\/api/, '')}`];
          const label = ENTITY_LABEL[entity] ?? entity;
          const verb = VERB[method] ?? method;
          const actor = user?.email ?? 'Pengunjung (publik)';

          void this.audit.log({
            action: method,
            entity,
            entityId: entityId ? String(entityId) : null,
            kategori: override?.kategori ?? KATEGORI_BY_ENTITY[entity] ?? AuditKategori.DATA,
            tingkat: method === 'DELETE' ? AuditTingkat.WARNING : AuditTingkat.INFO,
            judul: override?.judul ?? `${verb} data ${label}`,
            deskripsi: `${actor} ${verb.toLowerCase()} data ${label}${
              entityId ? ` (ID \`${entityId}\`)` : ''
            }.`,
            tenantId,
            userId: user?.userId ?? null,
            userNama: actor,
            userRole: user?.role ? String(user.role) : null,
            ip: req.ip ?? null,
            data: {
              url: (req.originalUrl ?? '').split('?')[0],
              // Data sensitif anak: simpan hanya nama field, bukan isinya.
              body: SENSITIVE_ENTITIES.has(entity)
                ? { fields: Object.keys(body) }
                : sanitize(body),
            },
          });
        },
      }),
    );
  }
}