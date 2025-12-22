import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min, Max, IsString, IsOptional, MaxLength } from 'class-validator';

export class CreateRatingDto {
  @ApiProperty({
    description: 'Nombre d\'étoiles (1-5)',
    minimum: 1,
    maximum: 5,
    example: 5,
  })
  @IsInt()
  @Min(1)
  @Max(5)
  stars: number;

  @ApiProperty({
    description: 'Commentaire optionnel sur la livraison',
    required: false,
    maxLength: 500,
    example: 'Excellent service, très rapide et professionnel !',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
