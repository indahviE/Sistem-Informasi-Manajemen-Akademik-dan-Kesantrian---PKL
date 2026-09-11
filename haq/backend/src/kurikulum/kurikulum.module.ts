import { Module } from '@nestjs/common';
import { KurikulumController } from './kurikulum.controller';
import { KurikulumService } from './kurikulum.service';

@Module({
  controllers: [KurikulumController],
  providers: [KurikulumService],
})
export class KurikulumModule {}
