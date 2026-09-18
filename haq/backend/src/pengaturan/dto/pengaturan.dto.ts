import { IsBoolean, IsEmail, IsEnum, IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';
import { PlatformSubRole } from '@prisma/client';

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

export class CreateSubAdminDto {
  @IsString() nama: string;

  @IsEmail() email: string;

  @IsString() @MinLength(8) password: string;

  @IsEnum(PlatformSubRole) subRole: PlatformSubRole;
}