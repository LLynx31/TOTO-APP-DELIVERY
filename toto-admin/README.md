# TOTO Admin Dashboard

Dashboard d'administration pour la plateforme TOTO de livraison.

## Technologies

- **Next.js 16** - Framework React
- **TypeScript** - Typage statique
- **Tailwind CSS v4** - Styling
- **shadcn/ui** - Composants UI
- **Zustand** - State management
- **Axios** - HTTP client
- **Recharts** - Graphiques

## Prérequis

- Node.js 18+
- Backend TOTO en cours d'exécution sur `http://localhost:3000`

## Installation

```bash
npm install
```

## Configuration

Créez un fichier `.env.local` :

```env
NEXT_PUBLIC_API_URL=http://localhost:3000
```

## Développement

```bash
npm run dev
```

L'application sera disponible sur `http://localhost:3001`

## Production

```bash
npm run build
npm start
```

## Fonctionnalités

### Dashboard
- Vue d'ensemble des statistiques
- Nombre d'utilisateurs, livreurs, livraisons
- Revenus totaux
- Livraisons récentes

### Gestion des Utilisateurs
- Liste paginée des utilisateurs
- Recherche par téléphone
- Activation/Désactivation des comptes

### Gestion des Livreurs
- Liste des livreurs avec statut KYC
- Filtrage par statut KYC (en attente, approuvé, rejeté)
- Approbation/Rejet des demandes KYC
- Gestion des comptes livreurs

### Gestion des Livraisons
- Liste de toutes les livraisons
- Filtrage par statut
- Annulation de livraisons

### Quotas
- Vue des revenus par type de pack
- Statistiques de ventes

### Analytics
- Revenus par période
- Statistiques de livraisons
- Répartition par statut

## Authentification

Utilisez les identifiants du super admin créé par le seed :

- **Email:** admin@toto.com
- **Password:** Admin@2025

## Structure du projet

```
src/
├── app/                    # Pages Next.js (App Router)
│   ├── dashboard/         # Pages du dashboard
│   │   ├── analytics/    # Analytics
│   │   ├── deliverers/   # Gestion livreurs
│   │   ├── deliveries/   # Gestion livraisons
│   │   ├── quotas/       # Gestion quotas
│   │   └── users/        # Gestion utilisateurs
│   └── login/            # Page de connexion
├── components/            # Composants React
│   ├── dashboard/        # Composants dashboard
│   ├── layout/           # Layout (sidebar, header)
│   └── ui/               # Composants shadcn/ui
├── lib/                   # Utilitaires
│   ├── api.ts            # Client API Axios
│   └── utils.ts          # Helpers
├── services/             # Services API
│   └── admin-service.ts  # Appels API admin
├── store/                # State management
│   └── auth-store.ts     # Store authentification
└── types/                # Types TypeScript
    └── index.ts          # Définitions de types
```
