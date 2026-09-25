import { Module } from '@nestjs/common';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';

import { NotifikasiModule } from '../notifikasi/notifikasi.module';

@Module({
  imports: [NotifikasiModule],
  controllers: [BillingController],
  providers: [BillingService],
})
export class BillingModule {}