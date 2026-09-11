import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { JenisPerizinan, StatusApproval, StatusKesehatan } from '@prisma/client';

export class CreatePelanggaranDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsString()
  @IsNotEmpty()
  jenisPelanggaran: string;

  @IsInt({ message: 'Poin harus angka' })
  poin: number;

  @IsDateString()
  tanggal: string;

  @IsOptional()
  @IsString()
  pelaporId?: string;

  @IsOptional()
  @IsString()
  tindakLanjut?: string;
}

export class UpdatePelanggaranDto {
  @IsOptional()
  @IsString()
  jenisPelanggaran?: string;

  @IsOptional()
  @IsInt()
  poin?: number;

  @IsOptional()
  @IsString()
  tindakLanjut?: string;

  @IsOptional()
  @IsString()
  status?: string;
}

export class CreatePerizinanDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsEnum(JenisPerizinan, { message: 'Jenis perizinan tidak valid' })
  jenis: JenisPerizinan;

  @IsDateString()
  tanggalKeluar: string;

  @IsOptional()
  @IsDateString()
  tanggalKembali?: string;

  @IsString()
  @IsNotEmpty()
  alasan: string;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class UpdatePerizinanDto {
  @IsEnum(StatusApproval, { message: 'Status approval tidak valid' })
  statusApproval: StatusApproval;

  @IsOptional()
  @IsString()
  disetujuiOleh?: string;

  @IsOptional()
  @IsDateString()
  tanggalKembali?: string;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class CreateKesehatanDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsString()
  @IsNotEmpty()
  keluhan: string;

  @IsOptional()
  @IsString()
  diagnosa?: string;

  @IsOptional()
  @IsString()
  tindakan?: string;

  @IsOptional()
  @IsString()
  obat?: string;

  @IsOptional()
  @IsString()
  tempat?: string;

  @IsDateString()
  tanggal: string;

  @IsOptional()
  @IsEnum(StatusKesehatan)
  status?: StatusKesehatan;
}

export class CreateKunjunganDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsOptional()
  @IsString()
  waliId?: string;

  @IsDateString()
  tanggal: string;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class CreateTataTertibDto {
  @IsString()
  @IsNotEmpty()
  judul: string;

  @IsString()
  @IsNotEmpty()
  isi: string;
}

export class QueryKesantrianDto {
  @IsOptional()
  @IsString()
  santriId?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;
}