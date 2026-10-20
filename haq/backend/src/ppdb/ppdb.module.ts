import { Module } from '@nestjs/common';
import { PpdbController } from './ppdb.controller';
import { PpdbService } from './ppdb.service';
import { NotifikasiModule } from '../notifikasi/notifikasi.module';

@Module({
  imports: [NotifikasiModule],
  controllers: [PpdbController],
  providers: [PpdbService],
})
export class PpdbModule {}
