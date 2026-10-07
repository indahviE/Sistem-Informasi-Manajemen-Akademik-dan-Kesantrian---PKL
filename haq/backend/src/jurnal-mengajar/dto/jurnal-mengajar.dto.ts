import { IsDateString, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateJurnalMengajarDto {
  @IsDateString()
  tanggal: string;

  @IsString()
  @IsNotEmpty()
  kelasId: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsString()
  @IsNotEmpty({ message: 'Materi wajib diisi' })
  @MaxLength(500, { message: 'Materi maksimal 500 karakter' })
  materi: string;

  @IsOptional()
  @IsString()
  @MaxLength(300, { message: 'Catatan maksimal 300 karakter' })
  catatan?: string;
}

export class UpdateJurnalMengajarDto {
  @IsOptional()
  @IsDateString()
  tanggal?: string;

  @IsOptional()
  @IsString()
  kelasId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'Materi wajib diisi' })
  @MaxLength(500, { message: 'Materi maksimal 500 karakter' })
  materi?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300, { message: 'Catatan maksimal 300 karakter' })
  catatan?: string;
}

export class QueryJurnalMengajarDto {
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