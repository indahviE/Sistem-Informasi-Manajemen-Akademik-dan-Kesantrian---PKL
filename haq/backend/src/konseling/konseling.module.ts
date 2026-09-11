import { Module } from '@nestjs/common';
import { KonselingController } from './konseling.controller';
import { KonselingService } from './konseling.service';

@Module({
  controllers: [KonselingController],
  providers: [KonselingService],
})
export class KonselingModule {}
