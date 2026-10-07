import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';
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
  waliSantriId?: string;

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