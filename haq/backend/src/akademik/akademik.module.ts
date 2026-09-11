import { Module } from '@nestjs/common';
import { AkademikService } from './akademik.service';
import { AkademikController } from './akademik.controller';

@Module({
  controllers: [AkademikController],
  providers: [AkademikService],
  exports: [AkademikService],
})
export class AkademikModule {}