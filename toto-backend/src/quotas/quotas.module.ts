import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuotasService } from './quotas.service';
import { QuotasController } from './quotas.controller';
import { DeliveryQuota } from './entities/delivery-quota.entity';
import { QuotaTransaction } from './entities/quota-transaction.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DeliveryQuota, QuotaTransaction]),
    AuthModule,
  ],
  providers: [QuotasService],
  controllers: [QuotasController],
  exports: [QuotasService],
})
export class QuotasModule {}
