import { IsEnum, IsOptional, IsString } from 'class-validator';

export class ApproveKycDto {
  @IsEnum(['approved', 'rejected'])
  kyc_status: 'approved' | 'rejected';

  @IsString()
  @IsOptional()
  rejection_reason?: string;
}
