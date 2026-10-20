import {
  IsArray,
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { Role } from '@prisma/client';

/** Role yang boleh dibuat/diubah admin tenant. SUPER_ADMIN sengaja tidak ada. */
export const ROLE_TENANT: string[] = [
  Role.ADMIN,
  Role.USTADZ,
  Role.MUSYRIF,
  Role.PIMPINAN,
  Role.WALI_SANTRI,
  Role.SANTRI,
];

/** Nilai `hubungan` di tabel WaliSantri (sama dengan data seed). */
export const HUBUNGAN_WALI: string[] = ['Ayah', 'Ibu', 'Wali'];

export class CreateUserDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama wajib diisi' })
  nama: string;

  @IsEmail({}, { message: 'Email tidak valid' })
  email: string;

  @IsString()
  @MinLength(6, { message: 'Password minimal 6 karakter' })
  password: string;

  @IsIn(ROLE_TENANT, { message: 'Role tidak valid' })
  role: Role;

  @IsOptional()
  @IsString()
  noHp?: string;

  /** Khusus WALI_SANTRI: tautkan akun ke data wali yang SUDAH ada (belum punya akun). */
  @IsOptional()
  @IsString()
  waliSantriId?: string;

  /** Khusus WALI_SANTRI: ayah/ibu/wali. Dipakai kalau data wali baru dibuat. */
  @IsOptional()
  @IsIn(HUBUNGAN_WALI, { message: 'Hubungan tidak valid' })
  hubungan?: string;

  /** Khusus WALI_SANTRI: daftar santri (anak) yang langsung ditautkan ke wali ini. */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  santriIds?: string[];

  @IsOptional()
  @IsString()
  ustadzId?: string;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsEmail({}, { message: 'Email tidak valid' })
  email?: string;

  @IsOptional()
  @IsIn(ROLE_TENANT, { message: 'Role tidak valid' })
  role?: Role;
}