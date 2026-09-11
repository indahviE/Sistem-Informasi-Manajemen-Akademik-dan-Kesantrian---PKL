import { Module } from '@nestjs/common';
import { SantriService } from './santri.service';
import { SantriController } from './santri.controller';

@Module({
  controllers: [SantriController],
  providers: [SantriService],
  exports: [SantriService],
})
export class SantriModule {}