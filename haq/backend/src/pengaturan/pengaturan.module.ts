import { Module } from '@nestjs/common';
import { PengaturanService } from './pengaturan.service';
import { PengaturanUstadzService } from './pengaturan-ustadz.service';
import { PengaturanController } from './pengaturan.controller';

@Module({
  controllers: [PengaturanController],
  providers: [PengaturanService, PengaturanUstadzService],
  exports: [PengaturanService],
})
export class PengaturanModule {}