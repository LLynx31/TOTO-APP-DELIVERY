'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { getDelivererById, getDelivererEarnings, updateDeliverer, approveKyc } from '@/services/admin-service';
import type { Deliverer } from '@/types';
import { 
  ArrowLeft, 
  Phone, 
  Mail, 
  Truck, 
  Star, 
  CheckCircle, 
  XCircle, 
  Clock,
  Calendar,
  MapPin,
  Power,
} from 'lucide-react';
import { toast } from 'sonner';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

const kycStatusConfig = {
  pending: { label: 'En attente', color: 'bg-yellow-100 text-yellow-800', icon: Clock },
  approved: { label: 'Approuvé', color: 'bg-green-100 text-green-800', icon: CheckCircle },
  rejected: { label: 'Rejeté', color: 'bg-red-100 text-red-800', icon: XCircle },
};

export default function DelivererDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const [deliverer, setDeliverer] = useState<Deliverer | null>(null);
  const [delivererData, setDelivererData] = useState<any>(null);
  const [earnings, setEarnings] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [rejectReason, setRejectReason] = useState('');

  const fetchData = async () => {
    try {
      const [delivererDataResponse, earningsData] = await Promise.all([
        getDelivererById(params.id as string),
        getDelivererEarnings(params.id as string),
      ]);
      setDelivererData(delivererDataResponse);
      setDeliverer(delivererDataResponse.deliverer || delivererDataResponse);
      setEarnings(earningsData);
    } catch (error) {
      console.error('Error fetching deliverer details:', error);
      toast.error('Erreur lors du chargement des détails');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (params.id) {
      fetchData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.id]);

  const handleToggleActive = async () => {
    if (!deliverer) return;
    try {
      await updateDeliverer(deliverer.id, { is_active: !deliverer.is_active });
      toast.success(`Livreur ${!deliverer.is_active ? 'activé' : 'désactivé'} avec succès`);
      fetchData();
    } catch (error) {
      console.error('Error updating deliverer:', error);
      toast.error('Erreur lors de la mise à jour');
    }
  };

  const handleKycAction = async (status: 'approved' | 'rejected') => {
    if (!deliverer) return;
    try {
      await approveKyc(deliverer.id, {
        kyc_status: status,
        rejection_reason: status === 'rejected' ? rejectReason : undefined,
      });
      toast.success(`KYC ${status === 'approved' ? 'approuvé' : 'rejeté'} avec succès`);
      setRejectReason('');
      fetchData();
    } catch (error) {
      console.error('Error updating KYC:', error);
      toast.error('Erreur lors de la mise à jour du KYC');
    }
  };

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!deliverer) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-muted-foreground">Livreur introuvable</p>
      </div>
    );
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const kycConfig = kycStatusConfig[deliverer.kyc_status];

  return (
    <div className="flex flex-col">
      <Header title="Détails livreur" description={deliverer.full_name} />

      <div className="flex-1 space-y-6 p-6">
        <div className="flex items-center justify-between">
          <Button
            variant="ghost"
            onClick={() => router.back()}
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Retour
          </Button>
          <div className="flex gap-2">
            <Button
              variant={deliverer.is_active ? 'destructive' : 'default'}
              onClick={handleToggleActive}
            >
              <Power className="mr-2 h-4 w-4" />
              {deliverer.is_active ? 'Désactiver' : 'Activer'}
            </Button>
          </div>
        </div>

        {/* Deliverer Info */}
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Informations personnelles</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-3">
                <Phone className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Téléphone</p>
                  <p className="font-medium">{deliverer.phone_number}</p>
                </div>
              </div>
              {deliverer.email && (
                <div className="flex items-center gap-3">
                  <Mail className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="font-medium">{deliverer.email}</p>
                  </div>
                </div>
              )}
              <div className="flex items-center gap-3">
                <Calendar className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Inscrit le</p>
                  <p className="font-medium">{formatDate(deliverer.created_at)}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 flex-wrap">
                <Badge variant={deliverer.is_active ? 'default' : 'secondary'}>
                  {deliverer.is_active ? 'Actif' : 'Inactif'}
                </Badge>
                <Badge className={kycConfig.color}>
                  {kycConfig.label}
                </Badge>
                {deliverer.is_available && (
                  <Badge variant="outline">Disponible</Badge>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Informations véhicule</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-3">
                <Truck className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Type de véhicule</p>
                  <p className="font-medium">{deliverer.vehicle_type || '-'}</p>
                </div>
              </div>
              {deliverer.license_plate && (
                <div className="flex items-center gap-3">
                  <MapPin className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Plaque d'immatriculation</p>
                    <p className="font-medium">{deliverer.license_plate}</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Stats */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Note moyenne</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Star className="h-5 w-5 fill-yellow-400 text-yellow-400" />
                <span className="text-2xl font-bold">
                  {Number(deliverer.rating).toFixed(1)}
                </span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Total livraisons</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{deliverer.total_deliveries}</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Gains totaux</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">
                {formatCurrency(earnings?.total_earnings || 0)}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* KYC Documents */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Documents KYC</CardTitle>
              {deliverer.kyc_status === 'pending' && (
                <Badge className="bg-yellow-100 text-yellow-800">
                  <Clock className="mr-1 h-3 w-3" />
                  En attente de validation
                </Badge>
              )}
              {deliverer.kyc_status === 'approved' && (
                <Badge className="bg-green-100 text-green-800">
                  <CheckCircle className="mr-1 h-3 w-3" />
                  Approuvé
                </Badge>
              )}
              {deliverer.kyc_status === 'rejected' && (
                <Badge className="bg-red-100 text-red-800">
                  <XCircle className="mr-1 h-3 w-3" />
                  Rejeté
                </Badge>
              )}
            </div>
          </CardHeader>
          <CardContent>
            {deliverer.id_card_front_url || deliverer.id_card_back_url || deliverer.driver_license_url ? (
              <div className="space-y-6">
                {/* Document Preview Grid */}
                <div className="grid gap-4 md:grid-cols-3">
                  {deliverer.id_card_front_url && (
                    <div className="space-y-2">
                      <p className="text-sm font-medium">Carte d'identité (recto)</p>
                      <div className="relative aspect-video rounded-lg border overflow-hidden bg-muted">
                        <img
                          src={deliverer.id_card_front_url}
                          alt="Carte d'identité recto"
                          className="w-full h-full object-contain cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => window.open(deliverer.id_card_front_url, '_blank')}
                        />
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="w-full"
                        onClick={() => window.open(deliverer.id_card_front_url, '_blank')}
                      >
                        Voir en grand
                      </Button>
                    </div>
                  )}
                  {deliverer.id_card_back_url && (
                    <div className="space-y-2">
                      <p className="text-sm font-medium">Carte d'identité (verso)</p>
                      <div className="relative aspect-video rounded-lg border overflow-hidden bg-muted">
                        <img
                          src={deliverer.id_card_back_url}
                          alt="Carte d'identité verso"
                          className="w-full h-full object-contain cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => window.open(deliverer.id_card_back_url, '_blank')}
                        />
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="w-full"
                        onClick={() => window.open(deliverer.id_card_back_url, '_blank')}
                      >
                        Voir en grand
                      </Button>
                    </div>
                  )}
                  {deliverer.driver_license_url && (
                    <div className="space-y-2">
                      <p className="text-sm font-medium">Permis de conduire</p>
                      <div className="relative aspect-video rounded-lg border overflow-hidden bg-muted">
                        <img
                          src={deliverer.driver_license_url}
                          alt="Permis de conduire"
                          className="w-full h-full object-contain cursor-pointer hover:opacity-80 transition-opacity"
                          onClick={() => window.open(deliverer.driver_license_url, '_blank')}
                        />
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="w-full"
                        onClick={() => window.open(deliverer.driver_license_url, '_blank')}
                      >
                        Voir en grand
                      </Button>
                    </div>
                  )}
                </div>

                {/* KYC Action Buttons */}
                {deliverer.kyc_status === 'pending' && (
                  <div className="flex items-center gap-4 pt-4 border-t">
                    <div className="flex-1 space-y-2">
                      <Label>Raison du rejet (optionnel)</Label>
                      <Input
                        placeholder="Ex: Documents illisibles, informations incorrectes..."
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                      />
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="destructive"
                        onClick={() => handleKycAction('rejected')}
                      >
                        <XCircle className="mr-2 h-4 w-4" />
                        Rejeter
                      </Button>
                      <Button onClick={() => handleKycAction('approved')}>
                        <CheckCircle className="mr-2 h-4 w-4" />
                        Approuver
                      </Button>
                    </div>
                  </div>
                )}

                {deliverer.kyc_status === 'rejected' && deliverer.kyc_reviewed_at && (
                  <div className="pt-4 border-t">
                    <p className="text-sm text-muted-foreground">
                      Rejeté le {formatDate(typeof deliverer.kyc_reviewed_at === 'string' ? deliverer.kyc_reviewed_at : deliverer.kyc_reviewed_at.toString())}
                    </p>
                  </div>
                )}

                {deliverer.kyc_status === 'approved' && deliverer.kyc_reviewed_at && (
                  <div className="pt-4 border-t">
                    <p className="text-sm text-muted-foreground">
                      Approuvé le {formatDate(typeof deliverer.kyc_reviewed_at === 'string' ? deliverer.kyc_reviewed_at : deliverer.kyc_reviewed_at.toString())}
                    </p>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                Aucun document KYC soumis
              </div>
            )}
          </CardContent>
        </Card>
      </div>

    </div>
  );
}






