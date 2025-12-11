import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeliveriesController } from './deliveries.controller';
import { DeliveriesService } from './deliveries.service';
import { Delivery } from './entities/delivery.entity';
import { AuthModule } from '../auth/auth.module';
import { QuotasModule } from '../quotas/quotas.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Delivery]),
    AuthModule,
    forwardRef(() => QuotasModule),
  ],
  controllers: [DeliveriesController],
  providers: [DeliveriesService],
  exports: [DeliveriesService],
})
export class DeliveriesModule {}
