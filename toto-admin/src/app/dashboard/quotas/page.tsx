'use client';

import { useEffect, useState } from 'react';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { getQuotaPurchases, getQuotaRevenue } from '@/services/admin-service';
import { 
  CreditCard,
  TrendingUp,
  Package,
} from 'lucide-react';

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount);
};

export default function QuotasPage() {
  const [revenue, setRevenue] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const revenueData = await getQuotaRevenue('month');
        setRevenue(revenueData);
      } catch (error) {
        console.error('Error fetching quota data:', error);
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
        title="Quotas" 
        description="Gestion des packs de livraisons"
      />

      <div className="flex-1 space-y-6 p-6">
        {/* Revenue Stats */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Revenus du mois</CardTitle>
              <TrendingUp className="h-5 w-5 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(revenue?.total_revenue || 0)}
              </div>
              <p className="text-xs text-muted-foreground">
                {revenue?.total_purchases || 0} achats
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Pack BASIC</CardTitle>
              <Package className="h-5 w-5 text-blue-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(revenue?.revenue_by_type?.basic || 0)}
              </div>
              <p className="text-xs text-muted-foreground">10 livraisons / 8 000 FCFA</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Pack PREMIUM</CardTitle>
              <CreditCard className="h-5 w-5 text-purple-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {formatCurrency(revenue?.revenue_by_type?.premium || 0)}
              </div>
              <p className="text-xs text-muted-foreground">100 livraisons / 60 000 FCFA</p>
            </CardContent>
          </Card>
        </div>

        {/* Revenue by type */}
        <Card>
          <CardHeader>
            <CardTitle>Revenus par type de pack</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {Object.entries(revenue?.revenue_by_type || {}).map(([type, amount]) => (
                <div key={type} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="h-3 w-3 rounded-full bg-primary" />
                    <span className="font-medium capitalize">{type}</span>
                  </div>
                  <span className="font-bold">{formatCurrency(amount as number)}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}


