'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { getRevenueAnalytics, getDeliveriesAnalytics } from '@/services/admin-service';
import { 
  TrendingUp,
  Package,
  Calendar,
} from 'lucide-react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { toast } from 'sonner';

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount);
};

export default function AnalyticsPage() {
  const [period, setPeriod] = useState<'day' | 'week' | 'month'>('week');
  const [revenueData, setRevenueData] = useState<any>(null);
  const [deliveriesData, setDeliveriesData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        const [revenue, deliveries] = await Promise.all([
          getRevenueAnalytics(period),
          getDeliveriesAnalytics(period),
        ]);
        setRevenueData(revenue);
        setDeliveriesData(deliveries);
      } catch (error) {
        console.error('Error fetching analytics:', error);
        toast.error('Erreur lors du chargement des analytics');
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, [period]);

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
        title="Analytics" 
        description="Statistiques et analyses de performance"
      />

      <div className="flex-1 space-y-6 p-6">
        {/* Period selector */}
        <Card>
          <CardContent className="flex items-center gap-4 pt-6">
            <Calendar className="h-5 w-5 text-muted-foreground" />
            <div className="flex gap-2">
              <Button
                variant={period === 'day' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('day')}
              >
                Aujourd'hui
              </Button>
              <Button
                variant={period === 'week' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('week')}
              >
                Cette semaine
              </Button>
              <Button
                variant={period === 'month' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('month')}
              >
                Ce mois
              </Button>
            </div>
          </CardContent>
        </Card>

        {isLoading ? (
          <div className="flex h-48 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
          </div>
        ) : (
          <>
            {/* Revenue analytics */}
            <div className="grid gap-4 md:grid-cols-2">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle className="flex items-center gap-2">
                    <TrendingUp className="h-5 w-5 text-green-500" />
                    Revenus
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-3xl font-bold">
                    {formatCurrency(revenueData?.total_revenue || 0)}
                  </div>
                  <p className="text-sm text-muted-foreground mt-1">
                    {revenueData?.total_deliveries || 0} livraisons complétées
                  </p>
                  <p className="text-xs text-muted-foreground mt-2">
                    Du {formatDate(revenueData?.start_date)} au {formatDate(revenueData?.end_date)}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle className="flex items-center gap-2">
                    <Package className="h-5 w-5 text-blue-500" />
                    Livraisons
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-3xl font-bold">
                    {deliveriesData?.total || 0}
                  </div>
                  <p className="text-sm text-muted-foreground mt-1">
                    Livraisons créées
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Revenue Chart */}
            {revenueData?.daily_revenue && revenueData.daily_revenue.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Évolution des revenus</CardTitle>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={revenueData.daily_revenue}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis 
                        dataKey="date" 
                        tickFormatter={(value) => formatDate(value)}
                      />
                      <YAxis 
                        tickFormatter={(value) => `${(value / 1000).toFixed(0)}k`}
                      />
                      <Tooltip 
                        formatter={(value: number) => formatCurrency(value)}
                        labelFormatter={(label) => formatDate(label)}
                      />
                      <Legend />
                      <Line 
                        type="monotone" 
                        dataKey="revenue" 
                        stroke="#8884d8" 
                        name="Revenus"
                        strokeWidth={2}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            )}

            {/* Deliveries by status */}
            <Card>
              <CardHeader>
                <CardTitle>Répartition par statut</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-6">
                  {Object.entries(deliveriesData?.by_status || {}).map(([status, count]) => (
                    <div key={status} className="rounded-lg border p-4">
                      <p className="text-sm text-muted-foreground capitalize">
                        {status.replace(/([A-Z])/g, ' $1').trim()}
                      </p>
                      <p className="text-2xl font-bold">{count as number}</p>
                    </div>
                  ))}
                </div>
                {Object.keys(deliveriesData?.by_status || {}).length > 0 && (
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={Object.entries(deliveriesData.by_status || {}).map(([status, count]) => ({
                      status: status.replace(/([A-Z])/g, ' $1').trim(),
                      count,
                    }))}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="status" />
                      <YAxis />
                      <Tooltip />
                      <Legend />
                      <Bar dataKey="count" fill="#8884d8" name="Nombre de livraisons" />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </div>
  );
}


