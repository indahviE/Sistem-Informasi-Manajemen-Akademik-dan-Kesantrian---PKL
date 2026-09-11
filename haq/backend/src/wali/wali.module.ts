import { Module } from '@nestjs/common';
import { WaliService } from './wali.service';
import { WaliController } from './wali.controller';

@Module({
  controllers: [WaliController],
  providers: [WaliService],
  exports: [WaliService],
})
export class WaliModule {}