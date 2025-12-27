import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Delivery, DeliveryStatus } from './entities/delivery.entity';
import { CreateDeliveryDto } from './dto/create-delivery.dto';
import { UpdateDeliveryDto } from './dto/update-delivery.dto';
import { QuotasService } from '../quotas/quotas.service';
import { randomBytes } from 'crypto';

@Injectable()
export class DeliveriesService {
  constructor(
    @InjectRepository(Delivery)
    private deliveryRepository: Repository<Delivery>,
    @Inject(forwardRef(() => QuotasService))
    private quotasService: QuotasService,
  ) {}

  // ==========================================
  // CREATE DELIVERY
  // ==========================================
  async create(createDeliveryDto: CreateDeliveryDto, clientId: string) {
    // Calculate distance (Haversine formula)
    const distance = this.calculateDistance(
      createDeliveryDto.pickup_latitude,
      createDeliveryDto.pickup_longitude,
      createDeliveryDto.delivery_latitude,
      createDeliveryDto.delivery_longitude,
    );

    // Calculate price based on distance (example: 1000 CFA base + 500 CFA per km)
    const price = 1000 + distance * 500;

    // Generate unique QR codes
    const qr_code_pickup = this.generateQRCode('pickup');
    const qr_code_delivery = this.generateQRCode('delivery');

    // Generate unique 4-digit delivery code
    const delivery_code = await this.generateDeliveryCode();

    // Create delivery
    const delivery = this.deliveryRepository.create({
      ...createDeliveryDto,
      client_id: clientId,
      distance_km: Number(distance.toFixed(2)),
      price: Number(price.toFixed(2)),
      qr_code_pickup,
      qr_code_delivery,
      delivery_code,
      status: DeliveryStatus.PENDING,
    });

    const savedDelivery = await this.deliveryRepository.save(delivery);

    // Note: Le quota est consommé par le LIVREUR lors de l'acceptation,
    // pas par le client lors de la création. Le client crée gratuitement
    // une demande de livraison, et c'est le livreur qui paye pour l'accepter.

    return savedDelivery;
  }

  // ==========================================
  // GET ALL DELIVERIES (with filters)
  // ==========================================
  async findAll(userId: string, userType: 'client' | 'deliverer', status?: DeliveryStatus) {
    const query = this.deliveryRepository.createQueryBuilder('delivery');

    if (userType === 'client') {
      query.where('delivery.client_id = :userId', { userId });
    } else {
      query.where('delivery.deliverer_id = :userId', { userId });
    }

    if (status) {
      query.andWhere('delivery.status = :status', { status });
    }

    query
      .leftJoinAndSelect('delivery.client', 'client')
      .leftJoinAndSelect('delivery.deliverer', 'deliverer')
      .orderBy('delivery.created_at', 'DESC');

    return await query.getMany();
  }

  // ==========================================
  // GET DELIVERY BY ID
  // ==========================================
  async findOne(id: string, userId: string, userType: 'client' | 'deliverer') {
    const delivery = await this.deliveryRepository.findOne({
      where: { id },
      relations: ['client', 'deliverer'],
    });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    // Check authorization
    if (userType === 'client' && delivery.client_id !== userId) {
      throw new ForbiddenException('You can only view your own deliveries');
    }

    if (userType === 'deliverer' && delivery.deliverer_id !== userId) {
      throw new ForbiddenException('You can only view deliveries assigned to you');
    }

    // Sanitize sensitive data before returning
    return this.sanitizeDeliveryResponse(delivery);
  }

  // ==========================================
  // HELPER: Sanitize Delivery Response
  // ==========================================
  private sanitizeDeliveryResponse(delivery: Delivery) {
    // Remove sensitive fields from deliverer
    if (delivery.deliverer) {
      const { password_hash, id_card_front_url, id_card_back_url, driver_license_url, ...safeDeliverer } = delivery.deliverer;
      (delivery as any).deliverer = safeDeliverer;
    }

    // Remove sensitive fields from client
    if (delivery.client) {
      const { password_hash, ...safeClient } = delivery.client as any;
      (delivery as any).client = safeClient;
    }

    return delivery;
  }

  // ==========================================
  // UPDATE DELIVERY
  // ==========================================
  async update(
    id: string,
    updateDeliveryDto: UpdateDeliveryDto,
    userId: string,
    userType: 'client' | 'deliverer',
  ) {
    const delivery = await this.findOne(id, userId, userType);

    // Clients can only update if delivery is still pending
    if (userType === 'client' && delivery.status !== DeliveryStatus.PENDING) {
      throw new BadRequestException('Can only update pending deliveries');
    }

    // Handle status changes
    if (updateDeliveryDto.status) {
      this.validateStatusTransition(delivery.status, updateDeliveryDto.status, userType);
      delivery.status = updateDeliveryDto.status;

      // Update timestamps based on status
      const now = new Date();
      switch (updateDeliveryDto.status) {
        case DeliveryStatus.ACCEPTED:
          delivery.accepted_at = now;
          break;
        case DeliveryStatus.PICKED_UP:
          delivery.picked_up_at = now;
          break;
        case DeliveryStatus.DELIVERED:
          delivery.delivered_at = now;
          break;
        case DeliveryStatus.CANCELLED:
          delivery.cancelled_at = now;
          break;
      }
    }

    // Update other fields
    Object.assign(delivery, updateDeliveryDto);

    return await this.deliveryRepository.save(delivery);
  }

  // ==========================================
  // ACCEPT DELIVERY (Deliverer)
  // ==========================================
  async acceptDelivery(id: string, delivererId: string) {
    // 1. Vérifier que le livreur n'a pas déjà une course en cours
    const activeDelivery = await this.deliveryRepository.findOne({
      where: {
        deliverer_id: delivererId,
        status: In([
          DeliveryStatus.ACCEPTED,
          DeliveryStatus.PICKUP_IN_PROGRESS,
          DeliveryStatus.PICKED_UP,
          DeliveryStatus.DELIVERY_IN_PROGRESS,
        ]),
      },
    });

    if (activeDelivery) {
      throw new BadRequestException(
        'Vous avez déjà une course en cours. Terminez-la avant d\'en accepter une nouvelle.',
      );
    }

    // 2. Vérifier que le livreur a un quota actif AVANT d'accepter
    const quota = await this.quotasService.getActiveQuota(delivererId);
    if (!quota) {
      throw new ForbiddenException(
        'Vous devez acheter un pack de courses pour accepter des livraisons. ' +
        'Rendez-vous dans l\'onglet Quotas pour recharger votre compte.',
      );
    }

    // 3. Récupérer la livraison
    const delivery = await this.deliveryRepository.findOne({ where: { id } });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    if (delivery.status !== DeliveryStatus.PENDING) {
      throw new BadRequestException('Delivery is not available');
    }

    // 4. Consommer le quota du livreur
    try {
      await this.quotasService.useQuota(delivererId, delivery.id);
    } catch (error) {
      throw new ForbiddenException(
        'Impossible de consommer votre quota. Veuillez réessayer ou recharger votre compte.',
      );
    }

    // 5. Mettre à jour la livraison
    delivery.deliverer_id = delivererId;
    delivery.status = DeliveryStatus.ACCEPTED;
    delivery.accepted_at = new Date();

    return await this.deliveryRepository.save(delivery);
  }

  // ==========================================
  // CANCEL DELIVERY
  // ==========================================
  async cancel(id: string, userId: string, userType: 'client' | 'deliverer') {
    const delivery = await this.findOne(id, userId, userType);

    // Cannot cancel if already delivered
    if (delivery.status === DeliveryStatus.DELIVERED) {
      throw new BadRequestException('Cannot cancel delivered delivery');
    }

    // Sauvegarder le deliverer_id avant annulation (pour remboursement quota)
    const delivererId = delivery.deliverer_id;
    const wasAccepted = delivery.status !== DeliveryStatus.PENDING;

    delivery.status = DeliveryStatus.CANCELLED;
    delivery.cancelled_at = new Date();

    const cancelledDelivery = await this.deliveryRepository.save(delivery);

    // Rembourser le quota au LIVREUR si la livraison avait été acceptée
    // (c'est le livreur qui a consommé un quota en acceptant, pas le client)
    if (wasAccepted && delivererId) {
      await this.quotasService.refundQuota(delivererId, id);
    }

    return cancelledDelivery;
  }

  // ==========================================
  // VERIFY QR CODE
  // ==========================================
  async verifyQRCode(deliveryId: string, qrCode: string, type: 'pickup' | 'delivery') {
    const delivery = await this.deliveryRepository.findOne({
      where: { id: deliveryId },
    });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    const expectedQR = type === 'pickup' ? delivery.qr_code_pickup : delivery.qr_code_delivery;

    if (qrCode !== expectedQR) {
      throw new BadRequestException('Invalid QR code');
    }

    // Update status based on QR type
    // Pickup: accepte ACCEPTED ou PICKUP_IN_PROGRESS
    if (type === 'pickup' && (delivery.status === DeliveryStatus.ACCEPTED || delivery.status === DeliveryStatus.PICKUP_IN_PROGRESS)) {
      delivery.status = DeliveryStatus.PICKED_UP;
      delivery.picked_up_at = new Date();
    }
    // Delivery: accepte PICKED_UP ou DELIVERY_IN_PROGRESS
    else if (type === 'delivery' && (delivery.status === DeliveryStatus.PICKED_UP || delivery.status === DeliveryStatus.DELIVERY_IN_PROGRESS)) {
      delivery.status = DeliveryStatus.DELIVERED;
      delivery.delivered_at = new Date();
    }

    return await this.deliveryRepository.save(delivery);
  }

  // ==========================================
  // GET AVAILABLE DELIVERIES (for deliverers)
  // ==========================================
  async getAvailableDeliveries() {
    return await this.deliveryRepository.find({
      where: { status: DeliveryStatus.PENDING },
      relations: ['client'],
      order: { created_at: 'DESC' },
    });
  }

  // ==========================================
  // HELPER: Generate QR Code
  // ==========================================
  private generateQRCode(type: 'pickup' | 'delivery'): string {
    const timestamp = Date.now();
    const random = randomBytes(16).toString('hex');
    return `TOTO-${type.toUpperCase()}-${timestamp}-${random}`;
  }

  // ==========================================
  // HELPER: Generate Unique 4-Digit Delivery Code
  // ==========================================
  private async generateDeliveryCode(): Promise<string> {
    let code = '';
    let exists = true;

    // Keep generating until we get a unique code
    while (exists) {
      // Generate random 4-digit number (1000-9999)
      code = Math.floor(1000 + Math.random() * 9000).toString();

      // Check if code already exists
      const existingDelivery = await this.deliveryRepository.findOne({
        where: { delivery_code: code },
      });

      exists = !!existingDelivery;
    }

    return code;
  }

  // ==========================================
  // HELPER: Calculate Distance (Haversine)
  // ==========================================
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  // ==========================================
  // HELPER: Validate Status Transition
  // ==========================================
  private validateStatusTransition(
    currentStatus: DeliveryStatus,
    newStatus: DeliveryStatus,
    userType: 'client' | 'deliverer',
  ): void {
    const allowedTransitions: Record<DeliveryStatus, DeliveryStatus[]> = {
      [DeliveryStatus.PENDING]: [DeliveryStatus.ACCEPTED, DeliveryStatus.CANCELLED],
      [DeliveryStatus.ACCEPTED]: [
        DeliveryStatus.PICKUP_IN_PROGRESS,
        DeliveryStatus.CANCELLED,
      ],
      [DeliveryStatus.PICKUP_IN_PROGRESS]: [DeliveryStatus.PICKED_UP, DeliveryStatus.CANCELLED],
      [DeliveryStatus.PICKED_UP]: [
        DeliveryStatus.DELIVERY_IN_PROGRESS,
        DeliveryStatus.CANCELLED,
      ],
      [DeliveryStatus.DELIVERY_IN_PROGRESS]: [
        DeliveryStatus.DELIVERED,
        DeliveryStatus.CANCELLED,
      ],
      [DeliveryStatus.DELIVERED]: [],
      [DeliveryStatus.CANCELLED]: [],
    };

    const allowed = allowedTransitions[currentStatus] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestException(
        `Invalid status transition from ${currentStatus} to ${newStatus}`,
      );
    }

    // Clients can only cancel
    if (userType === 'client' && newStatus !== DeliveryStatus.CANCELLED) {
      throw new ForbiddenException('Clients can only cancel deliveries');
    }
  }
}
