import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateDelivererDto {
  @IsBoolean()
  @IsOptional()
  is_active?: boolean;

  @IsBoolean()
  @IsOptional()
  is_available?: boolean;
}
