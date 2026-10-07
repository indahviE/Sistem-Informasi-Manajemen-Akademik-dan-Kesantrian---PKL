import { Module } from '@nestjs/common';
import { JurnalMengajarController } from './jurnal-mengajar.controller';
import { JurnalMengajarService } from './jurnal-mengajar.service';

@Module({
  controllers: [JurnalMengajarController],
  providers: [JurnalMengajarService],
  exports: [JurnalMengajarService],
})
export class JurnalMengajarModule {}