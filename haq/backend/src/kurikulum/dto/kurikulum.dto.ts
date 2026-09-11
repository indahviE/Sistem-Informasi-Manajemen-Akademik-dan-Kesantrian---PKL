import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateKurikulumDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama kurikulum wajib diisi' })
  nama: string;

  @IsOptional()
  @IsString()
  tahunAjaranId?: string;

  @IsOptional()
  @IsString()
  deskripsi?: string;

  @IsOptional()
  aktif?: boolean;
}

export class UpdateKurikulumDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsString()
  tahunAjaranId?: string;

  @IsOptional()
  @IsString()
  deskripsi?: string;

  @IsOptional()
  aktif?: boolean;
}

export class CreateSilabusDto {
  @IsString()
  @IsNotEmpty({ message: 'Judul silabus wajib diisi' })
  judul: string;

  @IsOptional()
  @IsString()
  kurikulumId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsString()
  kompetensiDasar?: string;

  @IsOptional()
  @IsString()
  materiPokok?: string;

  @IsOptional()
  @IsString()
  alokasiWaktu?: string;

  @IsOptional()
  @IsString()
  fileUrl?: string;
}

export class UpdateSilabusDto {
  @IsOptional()
  @IsString()
  judul?: string;

  @IsOptional()
  @IsString()
  kurikulumId?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsString()
  kompetensiDasar?: string;

  @IsOptional()
  @IsString()
  materiPokok?: string;

  @IsOptional()
  @IsString()
  alokasiWaktu?: string;

  @IsOptional()
  @IsString()
  fileUrl?: string;
}

export class CreateRppDto {
  @IsString()
  @IsNotEmpty({ message: 'Judul RPP wajib diisi' })
  judul: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  pertemuan?: number;

  @IsOptional()
  @IsString()
  tujuan?: string;

  @IsOptional()
  @IsString()
  kegiatan?: string;

  @IsOptional()
  @IsString()
  penilaian?: string;

  @IsOptional()
  @IsString()
  fileUrl?: string;
}

export class UpdateRppDto {
  @IsOptional()
  @IsString()
  judul?: string;

  @IsOptional()
  @IsString()
  mapelId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  pertemuan?: number;

  @IsOptional()
  @IsString()
  tujuan?: string;

  @IsOptional()
  @IsString()
  kegiatan?: string;

  @IsOptional()
  @IsString()
  penilaian?: string;

  @IsOptional()
  @IsString()
  fileUrl?: string;
}