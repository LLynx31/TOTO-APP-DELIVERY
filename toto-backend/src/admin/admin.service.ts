import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, In } from 'typeorm';
import { User } from '../auth/entities/user.entity';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { KycDocument, KycDocumentType } from '../auth/entities/kyc-document.entity';
import { Delivery } from '../deliveries/entities/delivery.entity';
import { DeliveryQuota } from '../quotas/entities/delivery-quota.entity';
import { QuotaTransaction } from '../quotas/entities/quota-transaction.entity';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateDelivererDto } from './dto/update-deliverer.dto';
import { ApproveKycDto } from './dto/approve-kyc.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Deliverer)
    private delivererRepository: Repository<Deliverer>,
    @InjectRepository(Delivery)
    private deliveryRepository: Repository<Delivery>,
    @InjectRepository(DeliveryQuota)
    private quotaRepository: Repository<DeliveryQuota>,
    @InjectRepository(QuotaTransaction)
    private transactionRepository: Repository<QuotaTransaction>,
    @InjectRepository(KycDocument)
    private kycDocumentRepository: Repository<KycDocument>,
  ) {}

  // ==========================================
  // DASHBOARD & ANALYTICS
  // ==========================================

  async getDashboardStats() {
    const [
      totalUsers,
      totalDeliverers,
      activeDeliveries,
      totalDeliveries,
      newUsersToday,
      deliveriesToday,
    ] = await Promise.all([
      this.userRepository.count(),
      this.delivererRepository.count(),
      this.deliveryRepository.count({
        where: { status: In(['accepted', 'pickup_in_progress', 'picked_up', 'delivery_in_progress']) },
      }),
      this.deliveryRepository.count(),
      this.userRepository.count({
        where: {
          created_at: Between(
            new Date(new Date().setHours(0, 0, 0, 0)),
            new Date(new Date().setHours(23, 59, 59, 999)),
          ),
        },
      }),
      this.deliveryRepository.count({
        where: {
          created_at: Between(
            new Date(new Date().setHours(0, 0, 0, 0)),
            new Date(new Date().setHours(23, 59, 59, 999)),
          ),
        },
      }),
    ]);

    // Calculate total revenue from completed deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { status: 'delivered' },
    });
    const totalRevenue = deliveries.reduce((sum, d) => sum + parseFloat(d.price.toString()), 0);

    return {
      total_users: totalUsers,
      total_deliverers: totalDeliverers,
      active_deliveries: activeDeliveries,
      total_deliveries: totalDeliveries,
      total_revenue: totalRevenue,
      new_users_today: newUsersToday,
      deliveries_today: deliveriesToday,
    };
  }

  async getRevenueAnalytics(period: 'day' | 'week' | 'month' | 'year' = 'week') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
      case 'year':
        startDate = new Date(now.setFullYear(now.getFullYear() - 1));
        break;
    }

    const deliveries = await this.deliveryRepository.find({
      where: {
        status: 'delivered',
        created_at: Between(startDate, new Date()),
      },
      order: { created_at: 'ASC' },
    });

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total_revenue: deliveries.reduce((sum, d) => sum + parseFloat(d.price.toString()), 0),
      total_deliveries: deliveries.length,
      deliveries: deliveries.map(d => ({
        date: d.created_at,
        price: d.price,
      })),
    };
  }

  async getDeliveriesAnalytics(status?: string, period: 'day' | 'week' | 'month' = 'week') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
    }

    const where: any = {
      created_at: Between(startDate, new Date()),
    };

    if (status) {
      where.status = status;
    }

    const deliveries = await this.deliveryRepository.find({
      where,
      order: { created_at: 'ASC' },
    });

    // Group by status
    const byStatus = deliveries.reduce((acc, d) => {
      acc[d.status] = (acc[d.status] || 0) + 1;
      return acc;
    }, {});

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total: deliveries.length,
      by_status: byStatus,
    };
  }

  // ==========================================
  // USER MANAGEMENT
  // ==========================================

  async getAllUsers(page = 1, limit = 20, search?: string, isActive?: boolean) {
    const where: any = {};

    if (search) {
      where.phone_number = search;
    }

    if (isActive !== undefined) {
      where.is_active = isActive;
    }

    const [users, total] = await this.userRepository.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { created_at: 'DESC' },
    });

    return {
      data: users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUserById(id: string) {
    const user = await this.userRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get user's deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { client_id: id },
      order: { created_at: 'DESC' },
      take: 10,
    });

    return {
      user,
      deliveries_count: deliveries.length,
      recent_deliveries: deliveries,
    };
  }

  async updateUser(id: string, updateDto: UpdateUserDto) {
    const user = await this.userRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    Object.assign(user, updateDto);
    return this.userRepository.save(user);
  }

  async getUserTransactions(id: string) {
    const transactions = await this.transactionRepository.find({
      where: { user_id: id },
      order: { created_at: 'DESC' },
    });

    return transactions;
  }

  // ==========================================
  // DELIVERER MANAGEMENT
  // ==========================================

  async getAllDeliverers(
    page = 1,
    limit = 20,
    kycStatus?: string,
    isActive?: boolean,
    isAvailable?: boolean,
  ) {
    const where: any = {};

    if (kycStatus) {
      where.kyc_status = kycStatus;
    }

    if (isActive !== undefined) {
      where.is_active = isActive;
    }

    if (isAvailable !== undefined) {
      where.is_available = isAvailable;
    }

    const [deliverers, total] = await this.delivererRepository.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { created_at: 'DESC' },
    });

    return {
      data: deliverers,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDelivererById(id: string) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    // Get deliverer's deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { deliverer_id: id },
      order: { created_at: 'DESC' },
      take: 10,
    });

    // Calculate earnings
    const completedDeliveries = deliveries.filter(d => d.status === 'delivered');
    const totalEarnings = completedDeliveries.reduce(
      (sum, d) => sum + parseFloat(d.price.toString()),
      0,
    );

    return {
      deliverer,
      total_deliveries: deliveries.length,
      completed_deliveries: completedDeliveries.length,
      total_earnings: totalEarnings,
      recent_deliveries: deliveries,
    };
  }

  async updateDeliverer(id: string, updateDto: UpdateDelivererDto) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    Object.assign(deliverer, updateDto);
    return this.delivererRepository.save(deliverer);
  }

  async approveKyc(id: string, approveDto: ApproveKycDto) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    deliverer.kyc_status = approveDto.kyc_status;
    deliverer.kyc_reviewed_at = new Date();

    if (approveDto.kyc_status === 'approved') {
      deliverer.is_verified = true;
    }

    return this.delivererRepository.save(deliverer);
  }

  async getDelivererEarnings(id: string, startDate?: Date, endDate?: Date) {
    const where: any = {
      deliverer_id: id,
      status: 'delivered',
    };

    if (startDate && endDate) {
      where.created_at = Between(startDate, endDate);
    }

    const deliveries = await this.deliveryRepository.find({
      where,
      order: { created_at: 'DESC' },
    });

    const totalEarnings = deliveries.reduce(
      (sum, d) => sum + parseFloat(d.price.toString()),
      0,
    );

    return {
      total_earnings: totalEarnings,
      total_deliveries: deliveries.length,
      deliveries: deliveries.map(d => ({
        id: d.id,
        date: d.created_at,
        price: d.price,
      })),
    };
  }

  // ==========================================
  // DELIVERY MANAGEMENT
  // ==========================================

  async getAllDeliveries(
    page = 1,
    limit = 20,
    status?: string,
    startDate?: Date,
    endDate?: Date,
  ) {
    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (startDate && endDate) {
      where.created_at = Between(startDate, endDate);
    }

    const [deliveries, total] = await this.deliveryRepository.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { created_at: 'DESC' },
    });

    return {
      data: deliveries,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDeliveryById(id: string) {
    const delivery = await this.deliveryRepository.findOne({ where: { id } });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    return delivery;
  }

  async cancelDeliveryAsAdmin(id: string, reason: string) {
    const delivery = await this.deliveryRepository.findOne({ where: { id } });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    delivery.status = 'cancelled';
    await this.deliveryRepository.save(delivery);

    // TODO: Refund quota automatically (implement in DeliveriesService)
    // For now, return the updated delivery
    return delivery;
  }

  // ==========================================
  // QUOTA MANAGEMENT
  // ==========================================

  async getQuotaPurchases(
    page = 1,
    limit = 20,
    startDate?: Date,
    endDate?: Date,
    userType?: 'client' | 'deliverer',
  ) {
    const where: any = {
      transaction_type: 'purchase',
    };

    if (startDate && endDate) {
      where.created_at = Between(startDate, endDate);
    }

    const [transactions, total] = await this.transactionRepository.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { created_at: 'DESC' },
    });

    return {
      data: transactions,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getQuotaRevenue(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
      case 'year':
        startDate = new Date(now.setFullYear(now.getFullYear() - 1));
        break;
    }

    const transactions = await this.transactionRepository.find({
      where: {
        transaction_type: 'purchase',
        created_at: Between(startDate, new Date()),
      },
    });

    const totalRevenue = transactions.reduce(
      (sum, t) => sum + parseFloat(t.amount_cfa.toString()),
      0,
    );

    // Group by quota type
    const byType = transactions.reduce((acc, t) => {
      const type = t.quota_type || 'unknown';
      acc[type] = (acc[type] || 0) + parseFloat(t.amount_cfa.toString());
      return acc;
    }, {});

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total_revenue: totalRevenue,
      total_purchases: transactions.length,
      revenue_by_type: byType,
    };
  }

  // ==========================================
  // KYC DOCUMENT MANAGEMENT
  // ==========================================

  async uploadKycDocument(
    delivererId: string,
    documentType: KycDocumentType,
    file: Express.Multer.File,
  ) {
    const deliverer = await this.delivererRepository.findOne({ where: { id: delivererId } });
    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    const newDocument = this.kycDocumentRepository.create({
      deliverer_id: delivererId,
      document_type: documentType,
      file_name: file.filename,
      file_path: file.path,
      file_type: file.mimetype,
    });

    return this.kycDocumentRepository.save(newDocument);
  }

  async getKycDocumentsForDeliverer(delivererId: string) {
    const deliverer = await this.delivererRepository.findOne({ where: { id: delivererId } });
    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    return this.kycDocumentRepository.find({
      where: { deliverer_id: delivererId },
      order: { created_at: 'DESC' },
    });
  }

  async getKycDocumentById(documentId: string) {
    const document = await this.kycDocumentRepository.findOne({ where: { id: documentId } });
    if (!document) {
      throw new NotFoundException('KYC document not found');
    }
    return document;
  }
}
