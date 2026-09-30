import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export enum StatusRemedialDto {
  BELUM_TES = 'BELUM_TES',
  PROSES = 'PROSES',
  TUNTAS = 'TUNTAS',
}

export class SimpanRemedialDto {
  @IsString()
  santriId: string;

  @IsString()
  @MinLength(1)
  keterangan: string;

  @IsOptional()
  @IsEnum(StatusRemedialDto)
  status?: StatusRemedialDto;

  @IsOptional()
  @IsString()
  catatan?: string;

  @IsOptional()
  @IsNumber()
  nilaiRemedial?: number;

  @IsOptional()
  @IsDateString()
  jadwal?: string;

  @IsOptional()
  @IsString()
  ruang?: string;

  @IsOptional()
  @IsDateString()
  tenggat?: string;
}