import { ApiProperty } from '@nestjs/swagger';

export class RatingResponseDto {
  @ApiProperty({ description: 'ID de la notation' })
  id: string;

  @ApiProperty({ description: 'ID de la livraison' })
  delivery_id: string;

  @ApiProperty({ description: 'ID de celui qui note' })
  rated_by_id: string;

  @ApiProperty({ description: 'ID de celui qui est noté' })
  rated_user_id: string;

  @ApiProperty({ description: 'Nombre d\'étoiles (1-5)', minimum: 1, maximum: 5 })
  stars: number;

  @ApiProperty({ description: 'Commentaire', required: false })
  comment?: string;

  @ApiProperty({ description: 'Date de création' })
  created_at: Date;

  constructor(rating: any) {
    this.id = rating.id;
    this.delivery_id = rating.delivery_id;
    this.rated_by_id = rating.rated_by_id;
    this.rated_user_id = rating.rated_user_id;
    this.stars = rating.stars;
    this.comment = rating.comment;
    this.created_at = rating.created_at;
  }
}
