import { Module } from '@nestjs/common';
import { PenilaianController } from './penilaian.controller';
import { PenilaianService } from './penilaian.service';

@Module({
  controllers: [PenilaianController],
  providers: [PenilaianService],
})
export class PenilaianModule {}
