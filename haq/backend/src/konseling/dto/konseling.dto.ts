import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateKonselingDto {
  @IsString()
  @IsNotEmpty()
  santriId: string;

  @IsOptional()
  @IsString()
  tanggal?: string;

  @IsOptional()
  @IsString()
  konselorId?: string;

  @IsString()
  @IsNotEmpty({ message: 'Topik konseling wajib diisi' })
  topik: string;

  @IsString()
  @IsNotEmpty({ message: 'Catatan konseling wajib diisi' })
  catatan: string;

  @IsOptional()
  @IsString()
  tindakLanjut?: string;

  @IsOptional()
  privat?: boolean;
}

export class UpdateKonselingDto {
  @IsOptional()
  @IsString()
  tanggal?: string;

  @IsOptional()
  @IsString()
  konselorId?: string;

  @IsOptional()
  @IsString()
  topik?: string;

  @IsOptional()
  @IsString()
  catatan?: string;

  @IsOptional()
  @IsString()
  tindakLanjut?: string;

  @IsOptional()
  privat?: boolean;
}