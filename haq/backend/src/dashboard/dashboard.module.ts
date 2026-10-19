import { Module } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';
import { MudirService } from '../mudir/mudir.service'; // BARU
import { MudirController } from '../mudir/mudir.controller'; // BARU
 

@Module({
  controllers: [DashboardController, MudirController],
  providers: [DashboardService, MudirService],
  exports: [DashboardService],
})
export class DashboardModule {}