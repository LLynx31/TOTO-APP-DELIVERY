'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { Header } from '@/components/layout/header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { getUserById, getUserTransactions, updateUser } from '@/services/admin-service';
import type { User } from '@/types';
import { ArrowLeft, UserCheck, UserX, Phone, Mail, Calendar, Power, Edit } from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

export default function UserDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [transactions, setTransactions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [userData, setUserData] = useState<any>(null);

  const fetchData = async () => {
    try {
      const [userDataResponse, transactionsData] = await Promise.all([
        getUserById(params.id as string),
        getUserTransactions(params.id as string),
      ]);
      setUserData(userDataResponse);
      setUser(userDataResponse.user || userDataResponse);
      setTransactions(transactionsData);
    } catch (error) {
      console.error('Error fetching user details:', error);
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
    if (!user) return;
    try {
      await updateUser(user.id, { is_active: !user.is_active });
      toast.success(`Utilisateur ${!user.is_active ? 'activé' : 'désactivé'} avec succès`);
      fetchData();
    } catch (error) {
      console.error('Error updating user:', error);
      toast.error('Erreur lors de la mise à jour');
    }
  };

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-muted-foreground">Utilisateur introuvable</p>
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
      <Header title="Détails utilisateur" description={user.full_name} />

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
              variant={user.is_active ? 'destructive' : 'default'}
              onClick={handleToggleActive}
            >
              <Power className="mr-2 h-4 w-4" />
              {user.is_active ? 'Désactiver' : 'Activer'}
            </Button>
          </div>
        </div>

        {/* User Info */}
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
                  <p className="font-medium">{user.phone_number}</p>
                </div>
              </div>
              {user.email && (
                <div className="flex items-center gap-3">
                  <Mail className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="font-medium">{user.email}</p>
                  </div>
                </div>
              )}
              <div className="flex items-center gap-3">
                <Calendar className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">Inscrit le</p>
                  <p className="font-medium">{formatDate(user.created_at)}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant={user.is_active ? 'default' : 'secondary'}>
                  {user.is_active ? 'Actif' : 'Inactif'}
                </Badge>
                {user.is_verified ? (
                  <Badge variant="outline" className="gap-1">
                    <UserCheck className="h-3 w-3" />
                    Vérifié
                  </Badge>
                ) : (
                  <Badge variant="outline" className="gap-1">
                    <UserX className="h-3 w-3" />
                    Non vérifié
                  </Badge>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Statistiques</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Total transactions</p>
                <p className="text-2xl font-bold">{transactions.length}</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Transactions */}
        <Card>
          <CardHeader>
            <CardTitle>Historique des transactions</CardTitle>
          </CardHeader>
          <CardContent>
            {transactions.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                Aucune transaction
              </p>
            ) : (
              <div className="space-y-4">
                {transactions.map((transaction) => (
                  <div
                    key={transaction.id}
                    className="flex items-center justify-between rounded-lg border p-4"
                  >
                    <div>
                      <p className="font-medium">
                        {transaction.quota?.quota_type || 'N/A'}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        {formatDate(transaction.created_at)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-medium">
                        {transaction.quota?.price_paid
                          ? new Intl.NumberFormat('fr-FR', {
                              style: 'currency',
                              currency: 'XOF',
                            }).format(parseFloat(transaction.quota.price_paid.toString()))
                          : '-'}
                      </p>
                      <Badge variant="outline">{transaction.transaction_type}</Badge>
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






