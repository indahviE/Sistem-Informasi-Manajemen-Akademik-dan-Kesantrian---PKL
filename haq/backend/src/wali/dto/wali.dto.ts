import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateWaliDto {
  @IsString()
  @IsNotEmpty()
  nama: string;

  @IsOptional()
  @IsString()
  noHp?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  @IsNotEmpty()
  hubungan: string;

  @IsOptional()
  @IsString()
  userId?: string;
}

export class LinkWaliUserDto {
  @IsString()
  @IsNotEmpty()
  waliId: string;

  @IsString()
  @IsNotEmpty()
  userId: string;
}