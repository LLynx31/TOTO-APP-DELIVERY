import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../auth/entities/user.entity';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { Delivery } from '../deliveries/entities/delivery.entity';
import { DeliveryQuota } from '../quotas/entities/delivery-quota.entity';
import { QuotaTransaction } from '../quotas/entities/quota-transaction.entity';
import { Admin } from '../auth/entities/admin.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Deliverer,
      Delivery,
      DeliveryQuota,
      QuotaTransaction,
      Admin,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
