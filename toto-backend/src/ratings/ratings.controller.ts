import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { RatingsService } from './ratings.service';
import { CreateRatingDto } from './dto/create-rating.dto';
import { RatingResponseDto } from './dto/rating-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('ratings')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('deliveries')
export class RatingsController {
  constructor(private readonly ratingsService: RatingsService) {}

  @Post(':id/rate')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Noter une livraison',
    description:
      'Permet à un client de noter son livreur ou à un livreur de noter son client après une livraison terminée',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 201,
    description: 'Notation créée avec succès',
    type: RatingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Livraison non terminée ou données invalides' })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  @ApiResponse({ status: 409, description: 'Vous avez déjà noté cette livraison' })
  async rateDelivery(
    @Param('id') deliveryId: string,
    @Body() createRatingDto: CreateRatingDto,
    @Request() req,
  ): Promise<RatingResponseDto> {
    return this.ratingsService.createRating(
      deliveryId,
      req.user.id,
      createRatingDto,
    );
  }

  @Get(':id/rating')
  @ApiOperation({
    summary: 'Obtenir la notation d\'une livraison',
    description: 'Récupère la notation que l\'utilisateur a donnée pour cette livraison',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Notation trouvée',
    type: RatingResponseDto,
  })
  @ApiResponse({
    status: 200,
    description: 'Aucune notation trouvée',
    schema: { type: 'null' },
  })
  async getDeliveryRating(
    @Param('id') deliveryId: string,
    @Request() req,
  ): Promise<RatingResponseDto | null> {
    return this.ratingsService.getRatingForDelivery(deliveryId, req.user.id);
  }

  @Get(':id/has-rated')
  @ApiOperation({
    summary: 'Vérifier si l\'utilisateur a déjà noté une livraison',
    description: 'Retourne true si l\'utilisateur a déjà noté cette livraison, false sinon',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Statut de notation',
    schema: {
      type: 'object',
      properties: {
        has_rated: { type: 'boolean' },
      },
    },
  })
  async hasRated(
    @Param('id') deliveryId: string,
    @Request() req,
  ): Promise<{ has_rated: boolean }> {
    const hasRated = await this.ratingsService.hasRated(
      deliveryId,
      req.user.id,
    );
    return { has_rated: hasRated };
  }
}
