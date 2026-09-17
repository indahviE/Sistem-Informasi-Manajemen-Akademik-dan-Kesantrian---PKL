import { IsDateString, IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { StatusDarurat, StatusIbadah } from '@prisma/client';

// ===== Pembinaan Karakter =====
export class CreatePembinaanKarakterDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsDateString()
  tanggal: string;

  @IsString()
  @IsNotEmpty({ message: 'Kategori wajib diisi' })
  kategori: string;

  @IsString()
  @IsNotEmpty({ message: 'Catatan wajib diisi' })
  catatan: string;
}

// ===== Pembinaan Ibadah =====
export class CreatePembinaanIbadahDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsDateString()
  tanggal: string;

  @IsString()
  @IsNotEmpty({ message: 'Jenis ibadah wajib diisi' })
  jenisIbadah: string;

  @IsOptional()
  @IsEnum(StatusIbadah, { message: 'Status ibadah tidak valid' })
  status?: StatusIbadah;

  @IsOptional()
  @IsString()
  catatan?: string;
}

// ===== Keadaan Darurat =====
export class CreateKeadaanDaruratDto {
  @IsOptional()
  @IsString()
  santriId?: string;

  @IsString()
  @IsNotEmpty({ message: 'Jenis kedaruratan wajib diisi' })
  jenis: string;

  @IsOptional()
  @IsString()
  lokasi?: string;

  @IsString()
  @IsNotEmpty({ message: 'Deskripsi wajib diisi' })
  deskripsi: string;
}

export class UpdateKeadaanDaruratDto {
  @IsEnum(StatusDarurat, { message: 'Status tidak valid' })
  status: StatusDarurat;

  @IsOptional()
  @IsString()
  tindakLanjut?: string;
}

export class QueryPembinaanDto {
  @IsOptional()
  @IsString()
  santriId?: string;
}