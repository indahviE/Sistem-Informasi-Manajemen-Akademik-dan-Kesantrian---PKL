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

export class UpdateProfilDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
}

export class UbahPasswordDto {
  @IsString()
  passwordLama: string;

  @IsString()
  @MinLength(6)
  passwordBaru: string;
}