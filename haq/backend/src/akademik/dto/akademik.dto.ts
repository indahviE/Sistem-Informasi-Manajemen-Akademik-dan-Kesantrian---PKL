import {
  ArrayMinSize,
  IsArray,
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
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { AbsensiStatus, JenisNilai, JenisSetoran, KualitasSetoran } from '@prisma/client';

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

export class BulkAbsensiItemDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsEnum(AbsensiStatus, { message: 'Status absensi tidak valid' })
  status: AbsensiStatus;

  @IsOptional()
  @IsString()
  @MaxLength(150, { message: 'Keterangan maksimal 150 karakter' })
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

  @IsArray()
  @ArrayMinSize(1, { message: 'Daftar santri tidak boleh kosong' })
  @ValidateNested({ each: true })
  @Type(() => BulkAbsensiItemDto)
  items: BulkAbsensiItemDto[];
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
  @Min(1)
  @Max(30)
  juz: number;

  // LAMA: masih diterima supaya Flutter lama tidak rusak
  @IsOptional()
  @IsInt({ message: 'Halaman harus angka' })
  @Min(1)
  @Max(20)
  halaman?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  halamanMulai?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  halamanSelesai?: number;

  @IsOptional()
  @IsEnum(JenisSetoran, { message: 'Jenis setoran tidak valid' })
  jenis?: JenisSetoran;

  @IsOptional()
  @IsEnum(KualitasSetoran, { message: 'Kualitas setoran tidak valid' })
  kualitas?: KualitasSetoran;

  @IsOptional()
  @IsString()
  catatanUstadz?: string;

  // DEPRECATED: diabaikan, tanggal diisi server
  @IsOptional()
  @IsDateString()
  tanggalSetor?: string;
}

export class QueryAbsensiDto {
  @IsOptional()
  @IsString()
  santriId?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}