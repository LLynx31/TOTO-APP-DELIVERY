import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeliveryTracking } from '../entities/delivery-tracking.entity';
import { LocationUpdateDto } from '../dto/location-update.dto';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/tracking',
})
@Injectable()
export class TrackingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private activeDeliveries: Map<string, Set<string>> = new Map();

  constructor(
    @InjectRepository(DeliveryTracking)
    private trackingRepository: Repository<DeliveryTracking>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ==========================================
  // CONNECTION HANDLING
  // ==========================================
  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get('JWT_SECRET'),
      });

      client.data.userId = payload.sub;
      client.data.userType = payload.type;

      console.log(`Client connected: ${client.id} (${payload.type})`);
    } catch (error) {
      console.error('Connection error:', error.message);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);

    this.activeDeliveries.forEach((clients, deliveryId) => {
      clients.delete(client.id);
      if (clients.size === 0) {
        this.activeDeliveries.delete(deliveryId);
      }
    });
  }

  // ==========================================
  // JOIN DELIVERY TRACKING ROOM
  // ==========================================
  @SubscribeMessage('join_delivery')
  async handleJoinDelivery(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { delivery_id: string },
  ) {
    const { delivery_id } = data;
    const room = `delivery_${delivery_id}`;

    await client.join(room);

    if (!this.activeDeliveries.has(delivery_id)) {
      this.activeDeliveries.set(delivery_id, new Set());
    }
    this.activeDeliveries.get(delivery_id)?.add(client.id);

    console.log(`Client ${client.id} joined delivery ${delivery_id}`);

    return {
      event: 'joined',
      data: {
        delivery_id,
        message: 'Successfully joined delivery tracking',
      },
    };
  }

  // ==========================================
  // LEAVE DELIVERY TRACKING ROOM
  // ==========================================
  @SubscribeMessage('leave_delivery')
  async handleLeaveDelivery(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { delivery_id: string },
  ) {
    const { delivery_id } = data;
    const room = `delivery_${delivery_id}`;

    await client.leave(room);

    if (this.activeDeliveries.has(delivery_id)) {
      const deliveryClients = this.activeDeliveries.get(delivery_id);
      if (deliveryClients) {
        deliveryClients.delete(client.id);
        if (deliveryClients.size === 0) {
          this.activeDeliveries.delete(delivery_id);
        }
      }
    }

    console.log(`Client ${client.id} left delivery ${delivery_id}`);

    return {
      event: 'left',
      data: {
        delivery_id,
        message: 'Successfully left delivery tracking',
      },
    };
  }

  // ==========================================
  // UPDATE LOCATION (DELIVERER)
  // ==========================================
  @SubscribeMessage('update_location')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody() locationData: LocationUpdateDto,
  ) {
    const { userId, userType } = client.data;

    if (userType !== 'deliverer') {
      return {
        event: 'error',
        data: {
          message: 'Only deliverers can update location',
        },
      };
    }

    try {
      const tracking = this.trackingRepository.create({
        delivery_id: locationData.delivery_id,
        deliverer_id: userId,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        speed: locationData.speed,
        heading: locationData.heading,
        accuracy: locationData.accuracy,
      });

      await this.trackingRepository.save(tracking);

      const room = `delivery_${locationData.delivery_id}`;
      this.server.to(room).emit('location_updated', {
        delivery_id: locationData.delivery_id,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        speed: locationData.speed,
        heading: locationData.heading,
        accuracy: locationData.accuracy,
        timestamp: tracking.recorded_at,
      });

      return {
        event: 'location_saved',
        data: {
          message: 'Location updated successfully',
        },
      };
    } catch (error) {
      console.error('Error updating location:', error);
      return {
        event: 'error',
        data: {
          message: 'Failed to update location',
        },
      };
    }
  }

  // ==========================================
  // GET DELIVERY TRACKING HISTORY
  // ==========================================
  @SubscribeMessage('get_tracking_history')
  async handleGetTrackingHistory(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { delivery_id: string },
  ) {
    try {
      const history = await this.trackingRepository.find({
        where: { delivery_id: data.delivery_id },
        order: { recorded_at: 'ASC' },
      });

      return {
        event: 'tracking_history',
        data: {
          delivery_id: data.delivery_id,
          history,
        },
      };
    } catch (error) {
      console.error('Error fetching tracking history:', error);
      return {
        event: 'error',
        data: {
          message: 'Failed to fetch tracking history',
        },
      };
    }
  }

  // ==========================================
  // BROADCAST DELIVERY STATUS CHANGE
  // ==========================================
  broadcastDeliveryStatus(deliveryId: string, status: string, data: any) {
    const room = `delivery_${deliveryId}`;
    this.server.to(room).emit('delivery_status_changed', {
      delivery_id: deliveryId,
      status,
      ...data,
    });
  }
}
