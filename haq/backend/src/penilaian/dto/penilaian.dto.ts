import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { StatusKehadiranUjian } from '@prisma/client';

export class CreateUjianDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama ujian wajib diisi' })
  nama: string;

  @IsOptional()
  @IsString()
  jenis?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  tanggal?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durasiMenit?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  kkm?: number;
}

export class UpdateUjianDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsString()
  jenis?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  tanggal?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durasiMenit?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  kkm?: number;
}

export class InputNilaiUjianDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  // Wajib diisi jika status HADIR (default). Untuk SAKIT/IZIN/ALPA nilai diabaikan (disimpan kosong).
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  nilai?: number;

  @IsOptional()
  @IsEnum(StatusKehadiranUjian, { message: 'Status kehadiran harus HADIR, SAKIT, IZIN, atau ALPA' })
  status?: StatusKehadiranUjian;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class BukaKunciDto {
  @IsString()
  @IsNotEmpty({ message: 'Alasan buka kunci wajib diisi' })
  @MinLength(10, { message: 'Alasan buka kunci minimal 10 karakter' })
  @MaxLength(500)
  alasan: string;
}

export class CreateRemedialDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsOptional()
  @IsString()
  ujianId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsString()
  @IsNotEmpty({ message: 'Keterangan remedial wajib diisi' })
  keterangan: string;

  @IsOptional()
  @IsString()
  hasil?: string;

  @IsOptional()
  @IsString()
  tanggal?: string;
}

export class UpdateRemedialDto {
  @IsOptional()
  @IsString()
  keterangan?: string;

  @IsOptional()
  @IsString()
  hasil?: string;

  @IsOptional()
  @IsString()
  tanggal?: string;
}

export class GenerateRaporDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsString()
  @IsNotEmpty({ message: 'Periode wajib diisi' })
  periode: string;

  @IsOptional()
  @IsString()
  status?: string;
}

export class CreateKelulusanDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  tanggalKelulusan?: string;

  @IsOptional()
  @IsString()
  predikat?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  juzYangDiHafal?: number;

  @IsOptional()
  @IsString()
  catatan?: string;
}

export class UpdateKelulusanDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  tanggalKelulusan?: string;

  @IsOptional()
  @IsString()
  predikat?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  juzYangDiHafal?: number;

  @IsOptional()
  @IsString()
  catatan?: string;
}