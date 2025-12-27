import { IsString, IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({
    example: '+22507123456',
    description: 'Numéro de téléphone international au format +XXXXXXXXXXX',
    pattern: '^\\+[1-9]\\d{6,14}$'
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+[1-9]\d{6,14}$/, {
    message: 'Le numéro de téléphone doit commencer par + suivi de l\'indicatif pays et du numéro',
  })
  phone_number: string;

  @ApiProperty({
    example: 'motdepasse123',
    description: 'Mot de passe'
  })
  @IsString()
  @IsNotEmpty()
  password: string;
}
