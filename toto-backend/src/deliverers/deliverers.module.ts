import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeliverersController } from './deliverers.controller';
import { DeliverersService } from './deliverers.service';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { Delivery } from '../deliveries/entities/delivery.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Deliverer, Delivery]),
    AuthModule,
  ],
  controllers: [DeliverersController],
  providers: [DeliverersService],
  exports: [DeliverersService],
})
export class DeliverersModule {}
