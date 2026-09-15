import { Module } from '@nestjs/common';
import { AkademikService } from './akademik.service';
import { AkademikController } from './akademik.controller';
import { WaliModule } from '../wali/wali.module';

@Module({
  imports: [WaliModule], 
  controllers: [AkademikController],
  providers: [AkademikService],
  exports: [AkademikService],
})
export class AkademikModule {}