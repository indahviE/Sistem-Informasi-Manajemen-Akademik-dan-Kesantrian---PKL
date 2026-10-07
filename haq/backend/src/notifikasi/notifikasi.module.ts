import { Module } from '@nestjs/common';
import { NotifikasiService } from './notifikasi.service';
import { NotifikasiController } from './notifikasi.controller';
import { NotifikasiScheduler } from './notifikasi.scheduler';

@Module({
  controllers: [NotifikasiController],
  providers: [NotifikasiService, NotifikasiScheduler],
  exports: [NotifikasiService],
})
export class NotifikasiModule {}