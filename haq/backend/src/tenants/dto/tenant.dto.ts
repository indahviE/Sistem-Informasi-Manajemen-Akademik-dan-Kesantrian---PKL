import { IsArray, IsEmail, IsNotEmpty, IsOptional, IsString, Matches, MinLength } from 'class-validator';
import { IsUrlOrDataUri } from '../../common/validators/is-url-or-data-uri.validator';

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

  @IsOptional()
  @IsString()
  alamat?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  karakteristik?: string[];

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