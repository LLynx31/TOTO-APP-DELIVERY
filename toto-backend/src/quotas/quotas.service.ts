import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { DeliveryQuota, QuotaType } from './entities/delivery-quota.entity';
import { QuotaTransaction, TransactionType } from './entities/quota-transaction.entity';
import { PurchaseQuotaDto } from './dto/purchase-quota.dto';

interface QuotaPackage {
  deliveries: number;
  price: number;
  validity_days: number;
}

@Injectable()
export class QuotasService {
  private readonly quotaPackages: Record<QuotaType, QuotaPackage> = {
    [QuotaType.BASIC]: {
      deliveries: 10,
      price: 8000, // 8000 CFA
      validity_days: 30,
    },
    [QuotaType.STANDARD]: {
      deliveries: 50,
      price: 35000, // 35000 CFA (économie de 15%)
      validity_days: 60,
    },
    [QuotaType.PREMIUM]: {
      deliveries: 100,
      price: 60000, // 60000 CFA (économie de 25%)
      validity_days: 90,
    },
    [QuotaType.CUSTOM]: {
      deliveries: 0,
      price: 700, // 700 CFA par livraison
      validity_days: 90,
    },
  };

  constructor(
    @InjectRepository(DeliveryQuota)
    private quotaRepository: Repository<DeliveryQuota>,
    @InjectRepository(QuotaTransaction)
    private transactionRepository: Repository<QuotaTransaction>,
  ) {}

  // ==========================================
  // PURCHASE QUOTA
  // ==========================================
  async purchaseQuota(userId: string, purchaseDto: PurchaseQuotaDto) {
    const { quota_type, custom_quantity, payment_method, payment_reference } = purchaseDto;

    let totalDeliveries: number;
    let price: number;
    let validityDays: number;

    if (quota_type === QuotaType.CUSTOM) {
      if (!custom_quantity || custom_quantity < 1) {
        throw new BadRequestException('Custom quantity is required for custom quota type');
      }
      totalDeliveries = custom_quantity;
      price = custom_quantity * this.quotaPackages[QuotaType.CUSTOM].price;
      validityDays = this.quotaPackages[QuotaType.CUSTOM].validity_days;
    } else {
      const packageInfo = this.quotaPackages[quota_type];
      totalDeliveries = packageInfo.deliveries;
      price = packageInfo.price;
      validityDays = packageInfo.validity_days;
    }

    // Vérifier s'il existe déjà un quota actif
    const existingQuota = await this.quotaRepository.findOne({
      where: {
        user_id: userId,
        is_active: true,
      },
    });

    console.log(`💰 Purchase for user ${userId}`);
    console.log(`📦 Package: ${quota_type} (${totalDeliveries} deliveries, ${price} FCFA)`);
    console.log(`🔍 Existing active quota found: ${existingQuota ? 'YES' : 'NO'}`);
    if (existingQuota) {
      console.log(`📊 Current quota: ${existingQuota.remaining_deliveries}/${existingQuota.total_deliveries}`);
    }

    let savedQuota: DeliveryQuota;

    if (existingQuota) {
      // Additionner au quota existant
      const balanceBefore = existingQuota.remaining_deliveries;
      existingQuota.total_deliveries += totalDeliveries;
      existingQuota.remaining_deliveries += totalDeliveries;

      // Accumuler le prix payé
      existingQuota.price_paid += price;

      // Mettre à jour la méthode de paiement avec la dernière utilisée
      if (payment_method) {
        existingQuota.payment_method = payment_method;
      }
      if (payment_reference) {
        existingQuota.payment_reference = payment_reference;
      }

      // Étendre la date d'expiration si le nouveau package a une durée plus longue
      const newExpiresAt = new Date();
      newExpiresAt.setDate(newExpiresAt.getDate() + validityDays);
      if (newExpiresAt > existingQuota.expires_at) {
        existingQuota.expires_at = newExpiresAt;
      }

      savedQuota = await this.quotaRepository.save(existingQuota);

      console.log(`✅ Quota updated: ${balanceBefore} → ${savedQuota.remaining_deliveries} deliveries`);
      console.log(`💵 Total price accumulated: ${savedQuota.price_paid} FCFA`);

      // Créer la transaction d'achat avec le balance correct
      const transaction = this.transactionRepository.create({
        quota_id: savedQuota.id,
        transaction_type: TransactionType.PURCHASE,
        amount: totalDeliveries,
        balance_before: balanceBefore,
        balance_after: savedQuota.remaining_deliveries,
        description: `Purchase of ${quota_type} package (${totalDeliveries} deliveries)`,
      });

      await this.transactionRepository.save(transaction);
    } else {
      // Créer un nouveau quota
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + validityDays);

      const quota = this.quotaRepository.create({
        user_id: userId,
        quota_type,
        total_deliveries: totalDeliveries,
        used_deliveries: 0,
        remaining_deliveries: totalDeliveries,
        price_paid: price,
        payment_method,
        payment_reference,
        expires_at: expiresAt,
        is_active: true,
      });

      savedQuota = await this.quotaRepository.save(quota);

      console.log(`✨ New quota created: ${savedQuota.remaining_deliveries} deliveries`);
      console.log(`💵 Price: ${savedQuota.price_paid} FCFA`);

      const transaction = this.transactionRepository.create({
        quota_id: savedQuota.id,
        transaction_type: TransactionType.PURCHASE,
        amount: totalDeliveries,
        balance_before: 0,
        balance_after: totalDeliveries,
        description: `Purchase of ${quota_type} package (${totalDeliveries} deliveries)`,
      });

      await this.transactionRepository.save(transaction);
    }

    // Retourner le quota complet avec tous les champs nécessaires
    return this.quotaRepository.findOne({ where: { id: savedQuota.id } });
  }

  // ==========================================
  // GET USER QUOTAS
  // ==========================================
  async getUserQuotas(userId: string) {
    return await this.quotaRepository.find({
      where: { user_id: userId },
      order: { purchased_at: 'DESC' },
    });
  }

  // ==========================================
  // GET ACTIVE QUOTA
  // ==========================================
  async getActiveQuota(userId: string): Promise<DeliveryQuota | null> {
    const quota = await this.quotaRepository
      .createQueryBuilder('quota')
      .where('quota.user_id = :userId', { userId })
      .andWhere('quota.is_active = :isActive', { isActive: true })
      .andWhere('quota.remaining_deliveries > 0')
      .andWhere('(quota.expires_at IS NULL OR quota.expires_at > :now)', { now: new Date() })
      .orderBy('quota.expires_at', 'ASC')
      .getOne();

    return quota;
  }

  // ==========================================
  // CHECK AND USE QUOTA
  // ==========================================
  async useQuota(userId: string, deliveryId: string): Promise<void> {
    const quota = await this.getActiveQuota(userId);

    if (!quota) {
      throw new ForbiddenException(
        'No active delivery quota found. Please purchase a delivery package.',
      );
    }

    if (quota.remaining_deliveries <= 0) {
      throw new ForbiddenException('Delivery quota exhausted. Please purchase a new package.');
    }

    const balanceBefore = quota.remaining_deliveries;
    quota.used_deliveries += 1;
    quota.remaining_deliveries -= 1;

    if (quota.remaining_deliveries === 0) {
      quota.is_active = false;
    }

    await this.quotaRepository.save(quota);

    const transaction = this.transactionRepository.create({
      quota_id: quota.id,
      delivery_id: deliveryId,
      transaction_type: TransactionType.USAGE,
      amount: -1,
      balance_before: balanceBefore,
      balance_after: quota.remaining_deliveries,
      description: `Used quota for delivery ${deliveryId}`,
    });

    await this.transactionRepository.save(transaction);
  }

  // ==========================================
  // REFUND QUOTA (if delivery cancelled)
  // ==========================================
  async refundQuota(userId: string, deliveryId: string): Promise<void> {
    const transaction = await this.transactionRepository.findOne({
      where: {
        delivery_id: deliveryId,
        transaction_type: TransactionType.USAGE,
      },
      relations: ['quota'],
    });

    if (!transaction) {
      return;
    }

    const quota = await this.quotaRepository.findOne({
      where: { id: transaction.quota_id },
    });

    if (!quota) {
      return;
    }

    const balanceBefore = quota.remaining_deliveries;
    quota.used_deliveries -= 1;
    quota.remaining_deliveries += 1;

    if (!quota.is_active && quota.remaining_deliveries > 0) {
      const now = new Date();
      if (!quota.expires_at || quota.expires_at > now) {
        quota.is_active = true;
      }
    }

    await this.quotaRepository.save(quota);

    const refundTransaction = this.transactionRepository.create({
      quota_id: quota.id,
      delivery_id: deliveryId,
      transaction_type: TransactionType.REFUND,
      amount: 1,
      balance_before: balanceBefore,
      balance_after: quota.remaining_deliveries,
      description: `Refund for cancelled delivery ${deliveryId}`,
    });

    await this.transactionRepository.save(refundTransaction);
  }

  // ==========================================
  // GET QUOTA HISTORY
  // ==========================================
  async getQuotaHistory(userId: string, quotaId: string) {
    const quota = await this.quotaRepository.findOne({
      where: { id: quotaId, user_id: userId },
    });

    if (!quota) {
      throw new NotFoundException('Quota not found');
    }

    const transactions = await this.transactionRepository.find({
      where: { quota_id: quotaId },
      order: { created_at: 'DESC' },
    });

    return {
      quota,
      transactions,
    };
  }

  // ==========================================
  // GET ALL USER TRANSACTIONS (PURCHASE HISTORY)
  // ==========================================
  async getUserTransactions(userId: string) {
    console.log(`📜 getUserTransactions: Fetching transactions for user ${userId}`);

    // Récupérer tous les quotas de l'utilisateur
    const quotas = await this.quotaRepository.find({
      where: { user_id: userId },
    });

    console.log(`✅ Found ${quotas.length} quotas for user`);

    if (quotas.length === 0) {
      console.log('⚠️ No quotas found, returning empty array');
      return [];
    }

    const quotaIds = quotas.map(q => q.id);

    // Récupérer toutes les transactions de type PURCHASE avec relation quota
    const transactions = await this.transactionRepository.find({
      where: {
        quota_id: In(quotaIds),
        transaction_type: TransactionType.PURCHASE,
      },
      relations: ['quota'],
      order: { created_at: 'DESC' },
    });

    console.log(`✅ Found ${transactions.length} purchase transactions`);

    // Enrichir les transactions avec les données du quota
    const enrichedTransactions = transactions.map(transaction => ({
      id: transaction.id,
      quota_id: transaction.quota_id,
      transaction_type: transaction.transaction_type,
      amount: transaction.amount,
      balance_before: transaction.balance_before,
      balance_after: transaction.balance_after,
      description: transaction.description,
      created_at: transaction.created_at,
      // Données du quota associé
      quota_type: transaction.quota?.quota_type,
      // Convertir price_paid de string (decimal) en number
      price_paid: transaction.quota?.price_paid ? parseFloat(transaction.quota.price_paid.toString()) : null,
      payment_method: transaction.quota?.payment_method,
    }));

    console.log('📦 Sample transaction:', JSON.stringify(enrichedTransactions[0], null, 2));

    return enrichedTransactions;
  }

  // ==========================================
  // GET AVAILABLE PACKAGES
  // ==========================================
  getAvailablePackages() {
    return Object.entries(this.quotaPackages).map(([type, info]) => ({
      quota_type: type,
      deliveries: info.deliveries || 'Custom',
      price: info.price,
      price_per_delivery: type === QuotaType.CUSTOM ? info.price : (info.price / info.deliveries).toFixed(0),
      validity_days: info.validity_days,
      savings: type === QuotaType.CUSTOM ? 0 : this.calculateSavings(type as QuotaType),
    }));
  }

  private calculateSavings(type: QuotaType): number {
    if (type === QuotaType.CUSTOM || type === QuotaType.BASIC) return 0;

    const packageInfo = this.quotaPackages[type];
    const standardPrice = packageInfo.deliveries * 800; // Prix de base: 800 CFA par livraison
    const savings = ((standardPrice - packageInfo.price) / standardPrice) * 100;
    return Math.round(savings);
  }

  // ==========================================
  // DEACTIVATE EXPIRED QUOTAS (CRON)
  // ==========================================
  async deactivateExpiredQuotas() {
    const now = new Date();
    const expiredQuotas = await this.quotaRepository
      .createQueryBuilder('quota')
      .where('quota.is_active = :isActive', { isActive: true })
      .andWhere('quota.expires_at IS NOT NULL')
      .andWhere('quota.expires_at <= :now', { now })
      .getMany();

    for (const quota of expiredQuotas) {
      const balanceBefore = quota.remaining_deliveries;
      quota.is_active = false;

      await this.quotaRepository.save(quota);

      if (quota.remaining_deliveries > 0) {
        const transaction = this.transactionRepository.create({
          quota_id: quota.id,
          transaction_type: TransactionType.EXPIRATION,
          amount: -quota.remaining_deliveries,
          balance_before: balanceBefore,
          balance_after: 0,
          description: `Quota expired with ${quota.remaining_deliveries} unused deliveries`,
        });

        await this.transactionRepository.save(transaction);
      }
    }

    return expiredQuotas.length;
  }
}
