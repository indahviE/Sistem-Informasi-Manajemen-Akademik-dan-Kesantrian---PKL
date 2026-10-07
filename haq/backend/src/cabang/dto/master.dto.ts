import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { JenisUstadz } from '@prisma/client';

export class CreateUstadzDto {
  @IsString()
  @IsNotEmpty()
  nama: string;

  @IsEnum(JenisUstadz, { message: 'Jenis harus GURU atau MUSYRIF' })
  jenis: JenisUstadz;

  @IsOptional()
  @IsString()
  noHp?: string;
}

export class UpdateUstadzDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsEnum(JenisUstadz)
  jenis?: JenisUstadz;

  @IsOptional()
  @IsString()
  noHp?: string;
}

export class CreateKelasDto {
  @IsString()
  @IsNotEmpty()
  namaKelas: string;

  @IsString()
  @IsNotEmpty()
  tingkat: string;

  @IsOptional()
  @IsString()
  waliKelasId?: string;

  @IsOptional()
  @IsString()
  tahunAjaranId?: string;
}

export class UpdateKelasDto {
  @IsOptional()
  @IsString()
  namaKelas?: string;

  @IsOptional()
  @IsString()
  tingkat?: string;

  @IsOptional()
  @IsString()
  waliKelasId?: string;

  @IsOptional()
  @IsString()
  tahunAjaranId?: string;
}

export class CreateMapelDto {
  @IsString()
  @IsNotEmpty()
  namaMapel: string;

  @IsOptional()
  @IsString()
  kode?: string;

  @IsOptional()
  @IsString()
  jenis?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  kkm?: number;
}

export class UpdateMapelDto {
  @IsOptional()
  @IsString()
  namaMapel?: string;

  @IsOptional()
  @IsString()
  kode?: string;

  @IsOptional()
  @IsString()
  jenis?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  kkm?: number;
}

export class CreateTahunAjaranDto {
  @IsString()
  @IsNotEmpty()
  nama: string;
}