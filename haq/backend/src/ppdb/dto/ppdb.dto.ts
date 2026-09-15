import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { StatusPendaftaran } from '@prisma/client';

export class DaftarPpdbDto {
  @IsString()
  @IsNotEmpty({ message: 'Kode pondok wajib diisi' })
  kodeTenant: string;

  @IsString()
  @IsNotEmpty({ message: 'Nama lengkap wajib diisi' })
  nama: string;

  @IsString()
  @IsNotEmpty({ message: 'Jenis kelamin wajib diisi' })
  jenisKelamin: string;

  @IsOptional()
  @IsDateString()
  tanggalLahir?: string;

  @IsOptional()
  @IsString()
  asalSekolah?: string;

  @IsOptional()
  @IsString()
  noHp?: string;

  @IsOptional()
  @IsString()
  email?: string;

  @IsOptional()
  @IsString()
  alamat?: string;

  @IsOptional()
  @IsString()
  jalur?: string;
}

export class LookupPpdbDto {
  @IsString()
  @IsNotEmpty({ message: 'Kode pondok wajib diisi' })
  kode: string;
}

export class UpdatePendaftaranDto {
  @IsOptional()
  @IsEnum(StatusPendaftaran, { message: 'Status tidak valid' })
  status?: StatusPendaftaran;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class QueryPpdbDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  q?: string;
}

export class CreatePlacementTestDto {
  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  nilai?: number;

  @IsOptional()
  @IsString()
  hasil?: string;

  @IsOptional()
  @IsString()
  catatan?: string;

  @IsOptional()
  @IsDateString()
  tanggal?: string;
}
