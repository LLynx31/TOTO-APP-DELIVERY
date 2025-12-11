import { IsNotEmpty, IsString } from 'class-validator';

export class CancelDeliveryDto {
  @IsString()
  @IsNotEmpty()
  reason: string;
}
