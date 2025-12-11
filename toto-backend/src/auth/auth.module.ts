import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User } from './entities/user.entity';
import { Deliverer } from './entities/deliverer.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import { Admin } from './entities/admin.entity';
import { JwtStrategy } from './strategies/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UserTypeGuard } from './guards/user-type.guard';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Deliverer, RefreshToken, Admin]),
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get('JWT_EXPIRES_IN'),
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [AuthService, JwtStrategy, JwtAuthGuard, UserTypeGuard],
  controllers: [AuthController],
  exports: [AuthService, JwtAuthGuard, UserTypeGuard],
})
export class AuthModule {}
