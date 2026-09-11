import {
  IsDateString,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
} from 'class-validator';
import { AbsensiStatus, JenisNilai } from '@prisma/client';

export class CreateAbsensiDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsDateString({}, { message: 'Tanggal tidak valid' })
  tanggal: string;

  @IsEnum(AbsensiStatus, { message: 'Status absensi tidak valid' })
  status: AbsensiStatus;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class BulkAbsensiDto {
  @IsString()
  @IsNotEmpty()
  kelasId: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsDateString({}, { message: 'Tanggal tidak valid' })
  tanggal: string;

  @IsString({ each: true })
  items: {
    santriId: string;
    status: AbsensiStatus;
    catatan?: string;
  }[];
}

export class CreateNilaiDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsString()
  @IsNotEmpty()
  mapelId: string;

  @IsEnum(JenisNilai, { message: 'Jenis nilai tidak valid' })
  jenis: JenisNilai;

  @IsNumber({}, { message: 'Nilai harus angka' })
  @Min(0)
  @Max(100)
  nilai: number;

  @IsOptional()
  @IsString()
  keterangan?: string;

  @IsDateString()
  tanggal: string;
}

export class CreateTahfidzDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsInt({ message: 'Juz harus angka' })
  juz: number;

  @IsInt({ message: 'Halaman harus angka' })
  halaman: number;

  @IsOptional()
  @IsString()
  catatanUstadz?: string;

  @IsDateString()
  tanggalSetor: string;
}

export class QueryAbsensiDto {
  @IsOptional()
  @IsString()
  santriId?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}