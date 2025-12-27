import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { unlink } from 'fs/promises';
import { join } from 'path';

export type DocumentType = 'driving_license' | 'id_card' | 'vehicle_photo';

@Injectable()
export class UploadsService {
  constructor(
    @InjectRepository(Deliverer)
    private delivererRepository: Repository<Deliverer>,
    private configService: ConfigService,
  ) {}

  /**
   * Upload KYC document for a deliverer
   */
  async uploadKycDocument(
    delivererId: string,
    documentType: DocumentType,
    file: Express.Multer.File,
  ): Promise<{ url: string; documentType: DocumentType }> {
    const deliverer = await this.delivererRepository.findOne({
      where: { id: delivererId },
    });

    if (!deliverer) {
      // Delete the uploaded file if deliverer not found
      await this.deleteFile(file.path);
      throw new NotFoundException('Livreur non trouvé');
    }

    // Build the URL for the uploaded file
    const baseUrl = this.configService.get('API_BASE_URL') || 'http://localhost:3000';
    const fileUrl = `${baseUrl}/uploads/${file.filename}`;

    // Delete old file if exists
    const oldUrl = this.getOldUrl(deliverer, documentType);
    if (oldUrl) {
      await this.deleteOldFile(oldUrl);
    }

    // Update the appropriate field based on document type
    switch (documentType) {
      case 'driving_license':
        deliverer.driver_license_url = fileUrl;
        break;
      case 'id_card':
        deliverer.id_card_front_url = fileUrl;
        break;
      case 'vehicle_photo':
        // Use id_card_back_url for vehicle photo (or create a new field)
        deliverer.id_card_back_url = fileUrl;
        break;
    }

    // Update KYC submission date if first document
    if (!deliverer.kyc_submitted_at) {
      deliverer.kyc_submitted_at = new Date();
    }

    await this.delivererRepository.save(deliverer);

    return {
      url: fileUrl,
      documentType,
    };
  }

  /**
   * Upload multiple KYC documents at once
   */
  async uploadMultipleKycDocuments(
    delivererId: string,
    files: {
      driving_license?: Express.Multer.File;
      id_card?: Express.Multer.File;
      vehicle_photo?: Express.Multer.File;
    },
  ): Promise<{
    driving_license_url?: string;
    id_card_url?: string;
    vehicle_photo_url?: string;
    kyc_status: string;
  }> {
    const deliverer = await this.delivererRepository.findOne({
      where: { id: delivererId },
    });

    if (!deliverer) {
      // Delete all uploaded files
      for (const file of Object.values(files)) {
        if (file) await this.deleteFile(file.path);
      }
      throw new NotFoundException('Livreur non trouvé');
    }

    const baseUrl = this.configService.get('API_BASE_URL') || 'http://localhost:3000';
    const result: {
      driving_license_url?: string;
      id_card_url?: string;
      vehicle_photo_url?: string;
      kyc_status: string;
    } = { kyc_status: deliverer.kyc_status };

    // Process driving license
    if (files.driving_license) {
      if (deliverer.driver_license_url) {
        await this.deleteOldFile(deliverer.driver_license_url);
      }
      deliverer.driver_license_url = `${baseUrl}/uploads/${files.driving_license.filename}`;
      result.driving_license_url = deliverer.driver_license_url;
    }

    // Process ID card
    if (files.id_card) {
      if (deliverer.id_card_front_url) {
        await this.deleteOldFile(deliverer.id_card_front_url);
      }
      deliverer.id_card_front_url = `${baseUrl}/uploads/${files.id_card.filename}`;
      result.id_card_url = deliverer.id_card_front_url;
    }

    // Process vehicle photo
    if (files.vehicle_photo) {
      if (deliverer.id_card_back_url) {
        await this.deleteOldFile(deliverer.id_card_back_url);
      }
      deliverer.id_card_back_url = `${baseUrl}/uploads/${files.vehicle_photo.filename}`;
      result.vehicle_photo_url = deliverer.id_card_back_url;
    }

    // Update KYC status
    if (!deliverer.kyc_submitted_at) {
      deliverer.kyc_submitted_at = new Date();
    }
    deliverer.kyc_status = 'pending';
    result.kyc_status = 'pending';

    await this.delivererRepository.save(deliverer);

    return result;
  }

  /**
   * Get KYC documents status for a deliverer
   */
  async getKycDocuments(delivererId: string): Promise<{
    driving_license_url: string | null;
    id_card_url: string | null;
    vehicle_photo_url: string | null;
    kyc_status: string;
    kyc_submitted_at: Date | null;
    kyc_reviewed_at: Date | null;
  }> {
    const deliverer = await this.delivererRepository.findOne({
      where: { id: delivererId },
    });

    if (!deliverer) {
      throw new NotFoundException('Livreur non trouvé');
    }

    return {
      driving_license_url: deliverer.driver_license_url,
      id_card_url: deliverer.id_card_front_url,
      vehicle_photo_url: deliverer.id_card_back_url,
      kyc_status: deliverer.kyc_status,
      kyc_submitted_at: deliverer.kyc_submitted_at,
      kyc_reviewed_at: deliverer.kyc_reviewed_at,
    };
  }

  /**
   * Delete a file from storage
   */
  private async deleteFile(filePath: string): Promise<void> {
    try {
      await unlink(filePath);
    } catch (error) {
      console.error('Error deleting file:', error);
    }
  }

  /**
   * Delete old file when replacing
   */
  private async deleteOldFile(fileUrl: string): Promise<void> {
    try {
      const filename = fileUrl.split('/').pop();
      if (!filename) return;
      const uploadPath = this.configService.get('UPLOAD_DEST') || './uploads';
      const filePath = join(uploadPath, filename);
      await unlink(filePath);
    } catch (error) {
      console.error('Error deleting old file:', error);
    }
  }

  /**
   * Get old URL for a document type
   */
  private getOldUrl(deliverer: Deliverer, documentType: DocumentType): string | null {
    switch (documentType) {
      case 'driving_license':
        return deliverer.driver_license_url;
      case 'id_card':
        return deliverer.id_card_front_url;
      case 'vehicle_photo':
        return deliverer.id_card_back_url;
      default:
        return null;
    }
  }
}
