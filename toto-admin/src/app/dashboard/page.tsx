'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/layout/header';
import { StatsCard } from '@/components/dashboard/stats-card';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { getDashboardStats, getDeliveries } from '@/services/admin-service';
import type { DashboardStats, Delivery } from '@/types';
import {
  Users,
  Truck,
  Package,
  TrendingUp,
  Clock,
  CheckCircle,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount);
};

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

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentDeliveries, setRecentDeliveries] = useState<Delivery[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, deliveriesData] = await Promise.all([
          getDashboardStats(),
          getDeliveries(1, 5),
        ]);
        setStats(statsData);
        setRecentDeliveries(deliveriesData.data);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="flex flex-col">
      <Header 
        title="Dashboard" 
        description="Vue d'ensemble de votre plateforme TOTO"
      />

      <div className="flex-1 space-y-6 p-6">
        {/* Stats Grid */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <StatsCard
            title="Utilisateurs"
            value={stats?.total_users || 0}
            description={`+${stats?.new_users_today || 0} aujourd'hui`}
            icon={Users}
          />
          <StatsCard
            title="Livreurs"
            value={stats?.total_deliverers || 0}
            icon={Truck}
          />
          <StatsCard
            title="Livraisons actives"
            value={stats?.active_deliveries || 0}
            description={`${stats?.deliveries_today || 0} aujourd'hui`}
            icon={Package}
          />
          <StatsCard
            title="Revenus totaux"
            value={formatCurrency(stats?.total_revenue || 0)}
            icon={TrendingUp}
          />
        </div>

        {/* Stats secondaires */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total livraisons</CardTitle>
              <CheckCircle className="h-5 w-5 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.total_deliveries || 0}</div>
              <p className="text-xs text-muted-foreground">Toutes les livraisons</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Livraisons aujourd'hui</CardTitle>
              <Clock className="h-5 w-5 text-blue-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.deliveries_today || 0}</div>
              <p className="text-xs text-muted-foreground">Créées aujourd'hui</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Nouveaux utilisateurs</CardTitle>
              <Users className="h-5 w-5 text-purple-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats?.new_users_today || 0}</div>
              <p className="text-xs text-muted-foreground">Inscrits aujourd'hui</p>
            </CardContent>
          </Card>
        </div>

        {/* Recent deliveries */}
        <Card>
          <CardHeader>
            <CardTitle>Livraisons récentes</CardTitle>
          </CardHeader>
          <CardContent>
            {recentDeliveries.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                Aucune livraison récente
              </p>
            ) : (
              <div className="space-y-4">
                {recentDeliveries.map((delivery) => (
                  <div
                    key={delivery.id}
                    className="flex items-center justify-between rounded-lg border p-4"
                  >
                    <div className="space-y-1">
                      <p className="font-medium">{delivery.receiver_name}</p>
                      <p className="text-sm text-muted-foreground">
                        {delivery.pickup_address.substring(0, 30)}... → {delivery.delivery_address.substring(0, 30)}...
                      </p>
                    </div>
                    <div className="flex items-center gap-4">
                      <Badge className={statusColors[delivery.status]}>
                        {statusLabels[delivery.status]}
                      </Badge>
                      <span className="font-medium">
                        {formatCurrency(delivery.price)}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}


