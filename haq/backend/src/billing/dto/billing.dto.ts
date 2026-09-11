import { Type } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { StatusInvoice, StatusSubscription } from '@prisma/client';

export class CreatePaketDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama paket wajib diisi' })
  nama: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  harga: number;

  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limitSantri: number;

  @IsOptional()
  fitur?: any;
}

export class UpdatePaketDto {
  @IsOptional()
  @IsString()
  nama?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  harga?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limitSantri?: number;

  @IsOptional()
  fitur?: any;

  @IsOptional()
  aktif?: boolean;
}

export class AssignSubscriptionDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsNotEmpty()
  paketId: string;
}

export class UpdateSubscriptionDto {
  @IsOptional()
  @IsEnum(StatusSubscription)
  status?: StatusSubscription;

  @IsOptional()
  @Type(() => Date)
  tanggalAkhir?: Date;
}

export class CreateInvoiceDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  jumlah: number;

  @IsOptional()
  @IsString()
  metodeBayar?: string;
}

export class UpdateInvoiceDto {
  @IsOptional()
  @IsEnum(StatusInvoice)
  status?: StatusInvoice;

  @IsOptional()
  @IsString()
  metodeBayar?: string;
}