import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rating } from './entities/rating.entity';
import { CreateRatingDto } from './dto/create-rating.dto';
import { RatingResponseDto } from './dto/rating-response.dto';
import { Delivery, DeliveryStatus } from '../deliveries/entities/delivery.entity';

@Injectable()
export class RatingsService {
  constructor(
    @InjectRepository(Rating)
    private ratingRepository: Repository<Rating>,
    @InjectRepository(Delivery)
    private deliveryRepository: Repository<Delivery>,
  ) {}

  // ==========================================
  // CREATE RATING
  // ==========================================
  async createRating(
    deliveryId: string,
    userId: string,
    createRatingDto: CreateRatingDto,
  ): Promise<RatingResponseDto> {
    // 1. Vérifier que la livraison existe
    const delivery = await this.deliveryRepository.findOne({
      where: { id: deliveryId },
      relations: ['client', 'deliverer'],
    });

    if (!delivery) {
      throw new NotFoundException('Livraison non trouvée');
    }

    // 2. Vérifier que la livraison est terminée
    if (delivery.status !== DeliveryStatus.DELIVERED) {
      throw new BadRequestException(
        'Vous ne pouvez noter qu\'une livraison terminée',
      );
    }

    // 3. Vérifier que l'utilisateur fait partie de la livraison
    const isClient = delivery.client_id === userId;
    const isDeliverer = delivery.deliverer_id === userId;

    if (!isClient && !isDeliverer) {
      throw new BadRequestException(
        'Vous ne pouvez noter que vos propres livraisons',
      );
    }

    // 4. Déterminer qui est noté
    const ratedUserId = isClient ? delivery.deliverer_id : delivery.client_id;

    // 5. Vérifier que l'utilisateur n'a pas déjà noté cette livraison
    const existingRating = await this.ratingRepository.findOne({
      where: {
        delivery_id: deliveryId,
        rated_by_id: userId,
      },
    });

    if (existingRating) {
      throw new ConflictException('Vous avez déjà noté cette livraison');
    }

    // 6. Créer la notation
    const rating = this.ratingRepository.create({
      delivery_id: deliveryId,
      rated_by_id: userId,
      rated_user_id: ratedUserId,
      stars: createRatingDto.stars,
      comment: createRatingDto.comment,
    });

    const savedRating = await this.ratingRepository.save(rating);

    return new RatingResponseDto(savedRating);
  }

  // ==========================================
  // GET RATING FOR DELIVERY
  // ==========================================
  async getRatingForDelivery(
    deliveryId: string,
    userId: string,
  ): Promise<RatingResponseDto | null> {
    const rating = await this.ratingRepository.findOne({
      where: {
        delivery_id: deliveryId,
        rated_by_id: userId,
      },
    });

    return rating ? new RatingResponseDto(rating) : null;
  }

  // ==========================================
  // CHECK IF USER HAS RATED DELIVERY
  // ==========================================
  async hasRated(deliveryId: string, userId: string): Promise<boolean> {
    const rating = await this.ratingRepository.findOne({
      where: {
        delivery_id: deliveryId,
        rated_by_id: userId,
      },
    });

    return !!rating;
  }

  // ==========================================
  // GET ALL RATINGS FOR A USER
  // ==========================================
  async getRatingsForUser(userId: string): Promise<RatingResponseDto[]> {
    const ratings = await this.ratingRepository.find({
      where: { rated_user_id: userId },
      order: { created_at: 'DESC' },
    });

    return ratings.map((rating) => new RatingResponseDto(rating));
  }

  // ==========================================
  // GET AVERAGE RATING FOR A USER
  // ==========================================
  async getAverageRating(userId: string): Promise<{ average: number; count: number }> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.stars)', 'average')
      .addSelect('COUNT(rating.id)', 'count')
      .where('rating.rated_user_id = :userId', { userId })
      .getRawOne();

    return {
      average: result.average ? parseFloat(result.average) : 0,
      count: parseInt(result.count) || 0,
    };
  }
}
