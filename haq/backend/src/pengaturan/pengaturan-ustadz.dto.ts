import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotifikasiUstadzDto {
  @IsOptional() @IsBoolean() pengingatAbsensi?: boolean;
  @IsOptional() @IsBoolean() pengingatNilai?: boolean;
  @IsOptional() @IsBoolean() jadwalMengajar?: boolean;
  @IsOptional() @IsBoolean() pengumumanPondok?: boolean;
}