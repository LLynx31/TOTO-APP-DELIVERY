import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RefreshTokenDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'Refresh token JWT obtenu lors de la connexion ou du dernier rafraîchissement'
  })
  @IsString()
  @IsNotEmpty()
  refresh_token: string;
}
