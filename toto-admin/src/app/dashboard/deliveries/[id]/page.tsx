'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { getDeliveryById, cancelDelivery } from '@/services/admin-service';
import type { Delivery } from '@/types';
import { 
  ArrowLeft, 
  MapPin, 
  Phone, 
  Package, 
  Calendar,
  User,
  Truck,
  X,
} from 'lucide-react';
import { toast } from 'sonner';

const statusColors: Record<string, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  accepted: 'bg-blue-100 text-blue-800',
  pickupInProgress: 'bg-purple-100 text-purple-800',
  pickedUp: 'bg-indigo-100 text-indigo-800',
  deliveryInProgress: 'bg-cyan-100 text-cyan-800',
  delivered: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-800',
};

const statusLabels: Record<string, string> = {
  pending: 'En attente',
  accepted: 'Acceptée',
  pickupInProgress: 'Collecte en cours',
  pickedUp: 'Collecté',
  deliveryInProgress: 'Livraison en cours',
  delivered: 'Livrée',
  cancelled: 'Annulée',
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount);
};

export default function DeliveryDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const [delivery, setDelivery] = useState<Delivery | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await getDeliveryById(params.id as string);
        setDelivery(data);
      } catch (error) {
        console.error('Error fetching delivery details:', error);
        toast.error('Erreur lors du chargement des détails');
      } finally {
        setIsLoading(false);
      }
    };

    if (params.id) {
      fetchData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.id]);

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!delivery) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-muted-foreground">Livraison introuvable</p>
      </div>
    );
  }

  const formatDate = (date: string | null) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleCancel = async () => {
    if (!confirm('Êtes-vous sûr de vouloir annuler cette livraison ?')) return;
    
    try {
      await cancelDelivery(delivery.id, 'Annulée par l\'administrateur');
      toast.success('Livraison annulée avec succès');
      router.back();
    } catch (error) {
      console.error('Error cancelling delivery:', error);
      toast.error('Erreur lors de l\'annulation');
    }
  };

  return (
    <div className="flex flex-col">
      <Header title="Détails livraison" description={`ID: ${delivery.id.substring(0, 8)}...`} />

      <div className="flex-1 space-y-6 p-6">
        <div className="flex items-center justify-between">
          <Button
            variant="ghost"
            onClick={() => router.back()}
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Retour
          </Button>
          {!['delivered', 'cancelled'].includes(delivery.status) && (
            <Button
              variant="destructive"
              onClick={handleCancel}
            >
              <X className="mr-2 h-4 w-4" />
              Annuler la livraison
            </Button>
          )}
        </div>

        {/* Status and Price */}
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Statut</CardTitle>
            </CardHeader>
            <CardContent>
              <Badge className={statusColors[delivery.status]} size="lg">
                {statusLabels[delivery.status]}
              </Badge>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Prix</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{formatCurrency(delivery.price)}</p>
              {delivery.distance_km && (
                <p className="text-sm text-muted-foreground mt-1">
                  Distance: {delivery.distance_km} km
                </p>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Addresses */}
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5 text-green-500" />
                Point de collecte
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-sm text-muted-foreground">Adresse</p>
                <p className="font-medium">{delivery.pickup_address}</p>
              </div>
              {delivery.pickup_phone && (
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{delivery.pickup_phone}</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5 text-red-500" />
                Point de livraison
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-sm text-muted-foreground">Adresse</p>
                <p className="font-medium">{delivery.delivery_address}</p>
              </div>
              <div className="flex items-center gap-2">
                <User className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">{delivery.receiver_name}</span>
              </div>
              <div className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm">{delivery.delivery_phone}</span>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Package Info */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Package className="h-5 w-5" />
              Informations du colis
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {delivery.package_description && (
              <div>
                <p className="text-sm text-muted-foreground">Description</p>
                <p className="font-medium">{delivery.package_description}</p>
              </div>
            )}
            {delivery.package_weight && (
              <div>
                <p className="text-sm text-muted-foreground">Poids</p>
                <p className="font-medium">{delivery.package_weight} kg</p>
              </div>
            )}
            {delivery.special_instructions && (
              <div>
                <p className="text-sm text-muted-foreground">Instructions spéciales</p>
                <p className="font-medium">{delivery.special_instructions}</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Timeline */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Chronologie
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="h-2 w-2 rounded-full bg-primary" />
              <div>
                <p className="text-sm text-muted-foreground">Créée le</p>
                <p className="font-medium">{formatDate(delivery.created_at)}</p>
              </div>
            </div>
            {delivery.accepted_at && (
              <div className="flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-blue-500" />
                <div>
                  <p className="text-sm text-muted-foreground">Acceptée le</p>
                  <p className="font-medium">{formatDate(delivery.accepted_at)}</p>
                </div>
              </div>
            )}
            {delivery.picked_up_at && (
              <div className="flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-indigo-500" />
                <div>
                  <p className="text-sm text-muted-foreground">Collectée le</p>
                  <p className="font-medium">{formatDate(delivery.picked_up_at)}</p>
                </div>
              </div>
            )}
            {delivery.delivered_at && (
              <div className="flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-green-500" />
                <div>
                  <p className="text-sm text-muted-foreground">Livrée le</p>
                  <p className="font-medium">{formatDate(delivery.delivered_at)}</p>
                </div>
              </div>
            )}
            {delivery.cancelled_at && (
              <div className="flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-red-500" />
                <div>
                  <p className="text-sm text-muted-foreground">Annulée le</p>
                  <p className="font-medium">{formatDate(delivery.cancelled_at)}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}






