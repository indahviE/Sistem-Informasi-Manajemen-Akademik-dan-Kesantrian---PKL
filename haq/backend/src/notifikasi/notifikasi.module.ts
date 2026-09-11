import { Module } from '@nestjs/common';
import { NotifikasiService } from './notifikasi.service';
import { NotifikasiController } from './notifikasi.controller';

@Module({
  controllers: [NotifikasiController],
  providers: [NotifikasiService],
  exports: [NotifikasiService],
})
export class NotifikasiModule {}