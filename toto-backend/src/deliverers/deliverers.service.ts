import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { Delivery, DeliveryStatus } from '../deliveries/entities/delivery.entity';
import { UpdateDelivererDto } from './dto/update-deliverer.dto';

@Injectable()
export class DeliverersService {
  constructor(
    @InjectRepository(Deliverer)
    private deliverersRepository: Repository<Deliverer>,
    @InjectRepository(Delivery)
    private deliveryRepository: Repository<Delivery>,
  ) {}

  async findById(id: string): Promise<Deliverer> {
    const deliverer = await this.deliverersRepository.findOne({
      where: { id },
    });

    if (!deliverer) {
      throw new NotFoundException('Livreur non trouvé');
    }

    return deliverer;
  }

  async getProfile(delivererId: string): Promise<Omit<Deliverer, 'password_hash'>> {
    const deliverer = await this.findById(delivererId);

    // Remove sensitive data
    const { password_hash, ...profile } = deliverer;
    return profile;
  }

  async updateProfile(delivererId: string, updateDto: UpdateDelivererDto): Promise<Omit<Deliverer, 'password_hash'>> {
    const deliverer = await this.findById(delivererId);

    // Update allowed fields
    if (updateDto.full_name !== undefined) {
      deliverer.full_name = updateDto.full_name;
    }
    if (updateDto.email !== undefined) {
      deliverer.email = updateDto.email;
    }
    if (updateDto.photo_url !== undefined) {
      deliverer.photo_url = updateDto.photo_url;
    }
    if (updateDto.vehicle_type !== undefined) {
      deliverer.vehicle_type = updateDto.vehicle_type;
    }
    if (updateDto.license_plate !== undefined) {
      deliverer.license_plate = updateDto.license_plate;
    }

    const updated = await this.deliverersRepository.save(deliverer);

    // Remove sensitive data
    const { password_hash, ...profile } = updated;
    return profile;
  }

  async updateAvailability(delivererId: string, isAvailable: boolean): Promise<{ is_available: boolean }> {
    const deliverer = await this.findById(delivererId);
    deliverer.is_available = isAvailable;
    await this.deliverersRepository.save(deliverer);

    return { is_available: deliverer.is_available };
  }

  async getStats(delivererId: string): Promise<{
    total_deliveries: number;
    rating: number;
    is_verified: boolean;
    kyc_status: string;
  }> {
    const deliverer = await this.findById(delivererId);

    return {
      total_deliveries: deliverer.total_deliveries,
      rating: Number(deliverer.rating),
      is_verified: deliverer.is_verified,
      kyc_status: deliverer.kyc_status,
    };
  }

  // ==========================================
  // GET DAILY STATS
  // ==========================================
  async getDailyStats(delivererId: string): Promise<{
    deliveries_today: number;
    earnings_today: number;
    completed_today: number;
    in_progress: number;
  }> {
    // Get start and end of today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Count deliveries completed today
    const completedToday = await this.deliveryRepository.count({
      where: {
        deliverer_id: delivererId,
        status: DeliveryStatus.DELIVERED,
        delivered_at: Between(today, tomorrow),
      },
    });

    // Calculate earnings today (sum of prices of delivered orders today)
    const earningsResult = await this.deliveryRepository
      .createQueryBuilder('delivery')
      .select('SUM(delivery.price)', 'total')
      .where('delivery.deliverer_id = :delivererId', { delivererId })
      .andWhere('delivery.status = :status', { status: DeliveryStatus.DELIVERED })
      .andWhere('delivery.delivered_at >= :today', { today })
      .andWhere('delivery.delivered_at < :tomorrow', { tomorrow })
      .getRawOne();

    const earningsToday = parseFloat(earningsResult?.total || '0');

    // Count deliveries accepted today (total work today)
    const deliveriesToday = await this.deliveryRepository.count({
      where: {
        deliverer_id: delivererId,
        accepted_at: Between(today, tomorrow),
      },
    });

    // Count in-progress deliveries
    const inProgress = await this.deliveryRepository.count({
      where: {
        deliverer_id: delivererId,
        status: DeliveryStatus.ACCEPTED,
      },
    });
    const inProgressPickup = await this.deliveryRepository.count({
      where: {
        deliverer_id: delivererId,
        status: DeliveryStatus.PICKUP_IN_PROGRESS,
      },
    });
    const inProgressDelivery = await this.deliveryRepository.count({
      where: {
        deliverer_id: delivererId,
        status: DeliveryStatus.DELIVERY_IN_PROGRESS,
      },
    });

    return {
      deliveries_today: deliveriesToday,
      earnings_today: earningsToday,
      completed_today: completedToday,
      in_progress: inProgress + inProgressPickup + inProgressDelivery,
    };
  }

  // ==========================================
  // GET EARNINGS
  // ==========================================
  async getEarnings(
    delivererId: string,
    period: 'today' | 'week' | 'month' = 'today',
  ): Promise<{
    total: number;
    period: string;
    deliveries_count: number;
    details: Array<{
      id: string;
      amount: number;
      delivered_at: Date;
      pickup_address: string;
      delivery_address: string;
    }>;
  }> {
    // Calculate date range based on period
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'week':
        startDate = new Date(now);
        startDate.setDate(now.getDate() - 7);
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'month':
        startDate = new Date(now);
        startDate.setMonth(now.getMonth() - 1);
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'today':
      default:
        startDate = new Date(now);
        startDate.setHours(0, 0, 0, 0);
        break;
    }

    // Get all delivered deliveries in the period
    const deliveries = await this.deliveryRepository.find({
      where: {
        deliverer_id: delivererId,
        status: DeliveryStatus.DELIVERED,
        delivered_at: MoreThanOrEqual(startDate),
      },
      order: { delivered_at: 'DESC' },
    });

    // Calculate total earnings
    const total = deliveries.reduce((sum, d) => sum + Number(d.price), 0);

    // Format details
    const details = deliveries.map((d) => ({
      id: d.id,
      amount: Number(d.price),
      delivered_at: d.delivered_at,
      pickup_address: d.pickup_address,
      delivery_address: d.delivery_address,
    }));

    return {
      total,
      period,
      deliveries_count: deliveries.length,
      details,
    };
  }
}
