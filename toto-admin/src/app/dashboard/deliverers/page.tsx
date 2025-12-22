'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { getDeliverers, approveKyc, updateDeliverer } from '@/services/admin-service';
import type { Deliverer } from '@/types';
import { 
  MoreHorizontal, 
  CheckCircle, 
  XCircle, 
  Clock, 
  Star,
  ChevronLeft,
  ChevronRight,
  Truck,
  Eye,
  Search,
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { useCallback } from 'react';

const kycStatusConfig = {
  pending: { label: 'En attente', color: 'bg-yellow-100 text-yellow-800', icon: Clock },
  approved: { label: 'Approuvé', color: 'bg-green-100 text-green-800', icon: CheckCircle },
  rejected: { label: 'Rejeté', color: 'bg-red-100 text-red-800', icon: XCircle },
};

export default function DeliverersPage() {
  const router = useRouter();
  const [deliverers, setDeliverers] = useState<Deliverer[]>([]);
  const [pagination, setPagination] = useState({ page: 1, total: 0, totalPages: 0 });
  const [kycFilter, setKycFilter] = useState<string>('');
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [selectedDeliverer, setSelectedDeliverer] = useState<Deliverer | null>(null);
  const [kycDialogOpen, setKycDialogOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');

  const fetchDeliverers = useCallback(async (page: number = 1, searchTerm?: string) => {
    setIsLoading(true);
    try {
      const data = await getDeliverers(page, 20, kycFilter || undefined, undefined, undefined, searchTerm);
      setDeliverers(data.data);
      setPagination({ page: data.page, total: data.total, totalPages: data.totalPages });
    } catch (error) {
      console.error('Error fetching deliverers:', error);
      toast.error('Erreur lors du chargement des livreurs');
    } finally {
      setIsLoading(false);
    }
  }, [kycFilter]);

  useEffect(() => {
    fetchDeliverers(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [kycFilter]);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (search !== undefined) {
        fetchDeliverers(1, search);
      }
    }, 500);

    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search]);

  const handleKycAction = async (status: 'approved' | 'rejected') => {
    if (!selectedDeliverer) return;
    
    try {
      await approveKyc(selectedDeliverer.id, {
        kyc_status: status,
        rejection_reason: status === 'rejected' ? rejectReason : undefined,
      });
      toast.success(`KYC ${status === 'approved' ? 'approuvé' : 'rejeté'} avec succès`);
      setKycDialogOpen(false);
      setRejectReason('');
      setSelectedDeliverer(null);
      fetchDeliverers(pagination.page);
    } catch (error) {
      console.error('Error updating KYC:', error);
      toast.error('Erreur lors de la mise à jour du KYC');
    }
  };

  const handleToggleActive = async (deliverer: Deliverer) => {
    try {
      await updateDeliverer(deliverer.id, { is_active: !deliverer.is_active });
      toast.success(`Livreur ${!deliverer.is_active ? 'activé' : 'désactivé'} avec succès`);
      fetchDeliverers(pagination.page);
    } catch (error) {
      console.error('Error updating deliverer:', error);
      toast.error('Erreur lors de la mise à jour');
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  return (
    <div className="flex flex-col">
      <Header 
        title="Livreurs" 
        description="Gérez les livreurs et les demandes KYC"
      />

      <div className="flex-1 space-y-6 p-6">
        {/* KYC Stats */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card 
            className={`cursor-pointer transition-colors ${kycFilter === 'pending' ? 'ring-2 ring-primary' : ''}`}
            onClick={() => setKycFilter(kycFilter === 'pending' ? '' : 'pending')}
          >
            <CardContent className="flex items-center gap-4 pt-6">
              <div className="rounded-full bg-yellow-100 p-3">
                <Clock className="h-6 w-6 text-yellow-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">En attente KYC</p>
                <p className="text-2xl font-bold">
                  {deliverers.filter(d => d.kyc_status === 'pending').length}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card 
            className={`cursor-pointer transition-colors ${kycFilter === 'approved' ? 'ring-2 ring-primary' : ''}`}
            onClick={() => setKycFilter(kycFilter === 'approved' ? '' : 'approved')}
          >
            <CardContent className="flex items-center gap-4 pt-6">
              <div className="rounded-full bg-green-100 p-3">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">KYC Approuvés</p>
                <p className="text-2xl font-bold">
                  {deliverers.filter(d => d.kyc_status === 'approved').length}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card 
            className={`cursor-pointer transition-colors ${kycFilter === 'rejected' ? 'ring-2 ring-primary' : ''}`}
            onClick={() => setKycFilter(kycFilter === 'rejected' ? '' : 'rejected')}
          >
            <CardContent className="flex items-center gap-4 pt-6">
              <div className="rounded-full bg-red-100 p-3">
                <XCircle className="h-6 w-6 text-red-600" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">KYC Rejetés</p>
                <p className="text-2xl font-bold">
                  {deliverers.filter(d => d.kyc_status === 'rejected').length}
                </p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Search */}
        <Card>
          <CardContent className="pt-6">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Rechercher par nom, email, téléphone, plaque..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-9"
              />
            </div>
          </CardContent>
        </Card>

        {/* Deliverers table */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Truck className="h-5 w-5" />
              Liste des livreurs ({pagination.total})
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex h-48 items-center justify-center">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
              </div>
            ) : (
              <>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nom</TableHead>
                      <TableHead>Téléphone</TableHead>
                      <TableHead>Véhicule</TableHead>
                      <TableHead>KYC</TableHead>
                      <TableHead>Statut</TableHead>
                      <TableHead>Note</TableHead>
                      <TableHead>Livraisons</TableHead>
                      <TableHead>Inscrit le</TableHead>
                      <TableHead className="w-12"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {deliverers.map((deliverer) => {
                      const kycConfig = kycStatusConfig[deliverer.kyc_status];
                      return (
                        <TableRow key={deliverer.id}>
                          <TableCell className="font-medium">{deliverer.full_name}</TableCell>
                          <TableCell>{deliverer.phone_number}</TableCell>
                          <TableCell>
                            {deliverer.vehicle_type || '-'}
                            {deliverer.license_plate && (
                              <span className="ml-1 text-xs text-muted-foreground">
                                ({deliverer.license_plate})
                              </span>
                            )}
                          </TableCell>
                          <TableCell>
                            <Badge className={kycConfig.color}>
                              {kycConfig.label}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <Badge variant={deliverer.is_active ? 'default' : 'secondary'}>
                              {deliverer.is_active ? 'Actif' : 'Inactif'}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1">
                              <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                              <span>{Number(deliverer.rating).toFixed(1)}</span>
                            </div>
                          </TableCell>
                          <TableCell>{deliverer.total_deliveries}</TableCell>
                          <TableCell>{formatDate(deliverer.created_at)}</TableCell>
                          <TableCell>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                {deliverer.kyc_status === 'pending' && (
                                  <>
                                    <DropdownMenuItem
                                      onClick={() => {
                                        setSelectedDeliverer(deliverer);
                                        setKycDialogOpen(true);
                                      }}
                                    >
                                      Traiter KYC
                                    </DropdownMenuItem>
                                    <DropdownMenuSeparator />
                                  </>
                                )}
                                <DropdownMenuItem onClick={() => router.push(`/dashboard/deliverers/${deliverer.id}`)}>
                                  <Eye className="mr-2 h-4 w-4" />
                                  Voir les détails
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => router.push(`/dashboard/deliverers/${deliverer.id}/earnings`)}>
                                  Voir les gains
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem onClick={() => handleToggleActive(deliverer)}>
                                  {deliverer.is_active ? 'Désactiver' : 'Activer'}
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>

                {/* Pagination */}
                <div className="mt-4 flex items-center justify-between">
                  <p className="text-sm text-muted-foreground">
                    Page {pagination.page} sur {pagination.totalPages}
                  </p>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={pagination.page <= 1}
                      onClick={() => fetchDeliverers(pagination.page - 1)}
                    >
                      <ChevronLeft className="h-4 w-4" />
                      Précédent
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={pagination.page >= pagination.totalPages}
                      onClick={() => fetchDeliverers(pagination.page + 1)}
                    >
                      Suivant
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* KYC Dialog */}
      <Dialog open={kycDialogOpen} onOpenChange={setKycDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Traitement KYC - {selectedDeliverer?.full_name}</DialogTitle>
            <DialogDescription>
              Approuvez ou rejetez la demande de vérification de ce livreur.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Téléphone:</span>
                <p className="font-medium">{selectedDeliverer?.phone_number}</p>
              </div>
              <div>
                <span className="text-muted-foreground">Véhicule:</span>
                <p className="font-medium">{selectedDeliverer?.vehicle_type || '-'}</p>
              </div>
              <div>
                <span className="text-muted-foreground">Plaque:</span>
                <p className="font-medium">{selectedDeliverer?.license_plate || '-'}</p>
              </div>
            </div>

            <div className="space-y-2">
              <Label>Raison du rejet (optionnel)</Label>
              <Input
                placeholder="Ex: Documents illisibles, informations incorrectes..."
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
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
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}


