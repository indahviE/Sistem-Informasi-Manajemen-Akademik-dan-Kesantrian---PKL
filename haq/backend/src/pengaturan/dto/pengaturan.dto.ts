import { IsBoolean, IsEmail, IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class UpdateKebijakanOnboardingDto {
  @IsOptional() @IsBoolean() autoApproveTenant?: boolean;

  @IsOptional() @IsInt() @Min(1) @Max(90) graceDaysPending?: number;
}

export class UpdateNotifikasiDto {
  @IsOptional() @IsBoolean() notifTenantBaru?: boolean;
  @IsOptional() @IsBoolean() notifTagihan?: boolean;
  @IsOptional() @IsBoolean() notifKeamanan?: boolean;
  @IsOptional() @IsBoolean() notifLaporanMingguan?: boolean;
}

export class UpdateNotifikasiAdminDto {
  @IsOptional() @IsBoolean() perizinanBaru?: boolean;
  @IsOptional() @IsBoolean() pelanggaranBaru?: boolean;
  @IsOptional() @IsBoolean() waliBelumAktivasi?: boolean;
  @IsOptional() @IsBoolean() eskalasiDarurat?: boolean;
  @IsOptional() @IsBoolean() rekapAbsensiShalat?: boolean;
}

export class UpdateNotifikasiWaliDto {
  @IsOptional() @IsBoolean() perizinanAnak?: boolean;
  @IsOptional() @IsBoolean() pelanggaranAnak?: boolean;
  @IsOptional() @IsBoolean() kesehatanAnak?: boolean;
  @IsOptional() @IsBoolean() nilaiRapor?: boolean;
  @IsOptional() @IsBoolean() absensiAnak?: boolean;
}

export class UpdateProfilDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  noHp?: string;
}

export class UbahPasswordDto {
  @IsString()
  passwordLama: string;

  @IsString()
  @MinLength(6)
  passwordBaru: string;
}