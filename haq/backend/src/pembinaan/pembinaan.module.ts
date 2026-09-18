import { Module } from '@nestjs/common';
import { PembinaanController } from './pembinaan.controller';
import { PembinaanService } from './pembinaan.service';

@Module({
  controllers: [PembinaanController],
  providers: [PembinaanService],
})
export class PembinaanModule {}