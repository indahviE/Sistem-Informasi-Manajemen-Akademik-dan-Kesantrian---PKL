import { Module } from '@nestjs/common';
import { KesantrianService } from './kesantrian.service';
import { KesantrianController } from './kesantrian.controller';
import { NotifikasiModule } from '../notifikasi/notifikasi.module'; // sesuaikan path kalau beda

@Module({
  imports: [NotifikasiModule],
  controllers: [KesantrianController],
  providers: [KesantrianService],
  exports: [KesantrianService],
})
export class KesantrianModule {}