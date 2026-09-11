import { IsEmail, IsNotEmpty, IsOptional, IsString, Matches, MinLength } from 'class-validator';
import { registerDecorator, ValidationOptions } from 'class-validator';

function IsUrlOrDataUri(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'IsUrlOrDataUri',
      target: object.constructor,
      propertyName,
      options: {
        message: 'Logo harus berupa URL atau data URI base64',
        ...validationOptions,
      },
      validator: {
        validate(value: unknown) {
          if (typeof value !== 'string' || value.length === 0) return true;
          if (value.startsWith('data:')) return value.length < 2_000_000;
          try {
            new URL(value);
            return true;
          } catch {
            return false;
          }
        },
      },
    });
  };
}

export class SignupTenantDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama pondok wajib diisi' })
  namaPondok: string;

  @IsString()
  @IsNotEmpty({ message: 'Kode tenant wajib diisi' })
  @Matches(/^[a-z0-9-]+$/, {
    message: 'Kode tenant hanya boleh huruf kecil, angka, dan tanda strip (-)',
  })
  kodeTenant: string;

  @IsOptional()
  @IsUrlOrDataUri()
  logoUrl?: string;

  @IsString()
  @IsNotEmpty({ message: 'Nama admin awal wajib diisi' })
  adminNama: string;

  @IsEmail({}, { message: 'Email admin tidak valid' })
  adminEmail: string;

  @IsString()
  @MinLength(6, { message: 'Password minimal 6 karakter' })
  adminPassword: string;
}

export class UpdateBrandingDto {
  @IsOptional()
  @IsString()
  namaPondok?: string;

  @IsOptional()
  @IsUrlOrDataUri()
  logoUrl?: string;

  @IsOptional()
  @Matches(/^#[0-9a-fA-F]{6}$/, { message: 'Warna tema harus format hex (mis. #10b981)' })
  warnaTema?: string;
}

export class ApproveTenantDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;
}

export class RejectTenantDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsOptional()
  @IsString()
  alasan?: string;
}