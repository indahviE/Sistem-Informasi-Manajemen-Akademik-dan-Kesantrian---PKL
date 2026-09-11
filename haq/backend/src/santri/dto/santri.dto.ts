import {
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateSantriDto {
  @IsString()
  @IsNotEmpty({ message: 'NIS wajib diisi' })
  nis: string;

  @IsString()
  @IsNotEmpty({ message: 'Nama wajib diisi' })
  nama: string;

  @IsIn(['L', 'P'], { message: 'Jenis kelamin harus L atau P' })
  jenisKelamin: string;

  @IsOptional()
  @IsDateString({}, { message: 'Tanggal lahir tidak valid' })
  tanggalLahir?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  asrama?: string;

  @IsOptional()
  @IsString()
  waliId?: string;

  @IsInt({ message: 'Tahun masuk harus angka' })
  tahunMasuk: number;
}

export class UpdateSantriDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsIn(['L', 'P'])
  jenisKelamin?: string;

  @IsOptional()
  @IsDateString()
  tanggalLahir?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  asrama?: string;

  @IsOptional()
  @IsString()
  waliId?: string;
}

export class QuerySantriDto {
  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  perPage?: number;
}
