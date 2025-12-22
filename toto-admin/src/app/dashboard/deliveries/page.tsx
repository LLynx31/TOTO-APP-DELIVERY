'use client';

import { useEffect, useState, useCallback } from 'react';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
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
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { getDeliveries, cancelDelivery } from '@/services/admin-service';
import type { Delivery, DeliveryStatus } from '@/types';
import { 
  MoreHorizontal, 
  Package,
  ChevronLeft,
  ChevronRight,
  MapPin,
  Eye,
  Search,
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

const statusColors: Record<DeliveryStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  accepted: 'bg-blue-100 text-blue-800',
  pickupInProgress: 'bg-purple-100 text-purple-800',
  pickedUp: 'bg-indigo-100 text-indigo-800',
  deliveryInProgress: 'bg-cyan-100 text-cyan-800',
  delivered: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-800',
};

const statusLabels: Record<DeliveryStatus, string> = {
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

export default function DeliveriesPage() {
  const router = useRouter();
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [pagination, setPagination] = useState({ page: 1, total: 0, totalPages: 0 });
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  const fetchDeliveries = useCallback(async (page: number = 1, searchTerm?: string) => {
    setIsLoading(true);
    try {
      const status = statusFilter === 'all' ? undefined : statusFilter;
      const data = await getDeliveries(page, 20, status, undefined, undefined, searchTerm);
      setDeliveries(data.data);
      setPagination({ page: data.page, total: data.total, totalPages: data.totalPages });
    } catch (error) {
      console.error('Error fetching deliveries:', error);
      toast.error('Erreur lors du chargement des livraisons');
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchDeliveries(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (search !== undefined) {
        fetchDeliveries(1, search);
      }
    }, 500);

    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search]);

  const handleCancel = async (delivery: Delivery) => {
    if (!confirm('Êtes-vous sûr de vouloir annuler cette livraison ?')) return;
    
    try {
      await cancelDelivery(delivery.id, 'Annulée par l\'administrateur');
      toast.success('Livraison annulée avec succès');
      fetchDeliveries(pagination.page);
    } catch (error) {
      console.error('Error cancelling delivery:', error);
      toast.error('Erreur lors de l\'annulation');
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="flex flex-col">
      <Header 
        title="Livraisons" 
        description="Suivez et gérez toutes les livraisons"
      />

      <div className="flex-1 space-y-6 p-6">
        {/* Search and Filters */}
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardContent className="pt-6">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Rechercher par destinataire, adresse, téléphone..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-9"
                />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="flex items-center gap-4 pt-6">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Statut:</span>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Tous les statuts" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Tous les statuts</SelectItem>
                    <SelectItem value="pending">En attente</SelectItem>
                    <SelectItem value="accepted">Acceptée</SelectItem>
                    <SelectItem value="pickupInProgress">Collecte en cours</SelectItem>
                    <SelectItem value="pickedUp">Collecté</SelectItem>
                    <SelectItem value="deliveryInProgress">Livraison en cours</SelectItem>
                    <SelectItem value="delivered">Livrée</SelectItem>
                    <SelectItem value="cancelled">Annulée</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Deliveries table */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Package className="h-5 w-5" />
              Liste des livraisons ({pagination.total})
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
                      <TableHead>ID</TableHead>
                      <TableHead>Destinataire</TableHead>
                      <TableHead>Adresses</TableHead>
                      <TableHead>Statut</TableHead>
                      <TableHead>Prix</TableHead>
                      <TableHead>Distance</TableHead>
                      <TableHead>Créée le</TableHead>
                      <TableHead className="w-12"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {deliveries.map((delivery) => (
                      <TableRow key={delivery.id}>
                        <TableCell className="font-mono text-xs">
                          {delivery.id.substring(0, 8)}...
                        </TableCell>
                        <TableCell className="font-medium">
                          {delivery.receiver_name}
                          <div className="text-xs text-muted-foreground">
                            {delivery.delivery_phone}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            <div className="flex items-center gap-1 text-xs">
                              <MapPin className="h-3 w-3 text-green-500" />
                              <span className="truncate max-w-[200px]">
                                {delivery.pickup_address}
                              </span>
                            </div>
                            <div className="flex items-center gap-1 text-xs">
                              <MapPin className="h-3 w-3 text-red-500" />
                              <span className="truncate max-w-[200px]">
                                {delivery.delivery_address}
                              </span>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge className={statusColors[delivery.status]}>
                            {statusLabels[delivery.status]}
                          </Badge>
                        </TableCell>
                        <TableCell className="font-medium">
                          {formatCurrency(delivery.price)}
                        </TableCell>
                        <TableCell>
                          {delivery.distance_km ? `${delivery.distance_km} km` : '-'}
                        </TableCell>
                        <TableCell className="text-xs">
                          {formatDate(delivery.created_at)}
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => router.push(`/dashboard/deliveries/${delivery.id}`)}>
                                <Eye className="mr-2 h-4 w-4" />
                                Voir les détails
                              </DropdownMenuItem>
                              {!['delivered', 'cancelled'].includes(delivery.status) && (
                                <DropdownMenuItem
                                  className="text-destructive"
                                  onClick={() => handleCancel(delivery)}
                                >
                                  Annuler
                                </DropdownMenuItem>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
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
                      onClick={() => fetchDeliveries(pagination.page - 1)}
                    >
                      <ChevronLeft className="h-4 w-4" />
                      Précédent
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={pagination.page >= pagination.totalPages}
                      onClick={() => fetchDeliveries(pagination.page + 1)}
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
    </div>
  );
}


