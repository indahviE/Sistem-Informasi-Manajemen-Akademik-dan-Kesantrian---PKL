import { Module } from '@nestjs/common';
import { KesantrianService } from './kesantrian.service';
import { KesantrianController } from './kesantrian.controller';

@Module({
  controllers: [KesantrianController],
  providers: [KesantrianService],
  exports: [KesantrianService],
})
export class KesantrianModule {}