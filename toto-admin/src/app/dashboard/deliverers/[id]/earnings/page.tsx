'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { getDelivererById, getDelivererEarnings } from '@/services/admin-service';
import { 
  ArrowLeft, 
  TrendingUp,
  Package,
  Calendar,
  DollarSign,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount);
};

export default function DelivererEarningsPage() {
  const params = useParams();
  const router = useRouter();
  const [deliverer, setDeliverer] = useState<any>(null);
  const [earnings, setEarnings] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [delivererData, earningsData] = await Promise.all([
          getDelivererById(params.id as string),
          getDelivererEarnings(params.id as string),
        ]);
        setDeliverer(delivererData.deliverer || delivererData);
        setEarnings(earningsData);
      } catch (error) {
        console.error('Error fetching earnings:', error);
        toast.error('Erreur lors du chargement des gains');
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

  if (!deliverer || !earnings) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-muted-foreground">Données introuvables</p>
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

  return (
    <div className="flex flex-col">
      <Header 
        title="Gains du livreur" 
        description={deliverer.full_name}
      />

      <div className="flex-1 space-y-6 p-6">
        <Button
          variant="ghost"
          onClick={() => router.back()}
          className="mb-4"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Retour
        </Button>

        {/* Stats Cards */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Gains totaux</CardTitle>
              <DollarSign className="h-5 w-5 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(earnings.total_earnings || 0)}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Tous les temps
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Livraisons complétées</CardTitle>
              <Package className="h-5 w-5 text-blue-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {earnings.total_deliveries || 0}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Livraisons livrées
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Gain moyen</CardTitle>
              <TrendingUp className="h-5 w-5 text-purple-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {earnings.total_deliveries > 0
                  ? formatCurrency(earnings.total_earnings / earnings.total_deliveries)
                  : formatCurrency(0)}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Par livraison
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Earnings Table */}
        <Card>
          <CardHeader>
            <CardTitle>Historique des gains</CardTitle>
          </CardHeader>
          <CardContent>
            {earnings.deliveries && earnings.deliveries.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>ID Livraison</TableHead>
                    <TableHead>Montant</TableHead>
                    <TableHead>Statut</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {earnings.deliveries.map((delivery: any) => (
                    <TableRow key={delivery.id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          {formatDate(delivery.date)}
                        </div>
                      </TableCell>
                      <TableCell className="font-mono text-xs">
                        {delivery.id.substring(0, 8)}...
                      </TableCell>
                      <TableCell className="font-medium">
                        {formatCurrency(parseFloat(delivery.price.toString()))}
                      </TableCell>
                      <TableCell>
                        <Badge className="bg-green-100 text-green-800">
                          Livrée
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                Aucune livraison complétée
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}






