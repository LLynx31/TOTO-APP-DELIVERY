# 📱 Guide de Navigation - Application TOTO Client

## Flow de Navigation Complet

```
┌─────────────────────────────────────────────────────────────────┐
│                    DÉMARRAGE DE L'APP                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Login Screen    │
                    │ (Connexion)      │
                    └──────────────────┘
                         │        │
                         │        └──────────────┐
                         │                       │
                         ▼                       ▼
              ┌─────────────────┐    ┌──────────────────┐
              │  Main Screen    │    │ Register Screen  │
              │ (Bottom Nav)    │    │ (Inscription)    │
              └─────────────────┘    └──────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Home    │  │Notifica- │  │ Profile  │
│  Tab     │  │tions Tab │  │   Tab    │
└──────────┘  └──────────┘  └──────────┘
     │
     ├──────────────────────────────────┐
     │                                  │
     ▼                                  ▼
┌──────────────────┐          ┌─────────────────┐
│ New Delivery     │          │ Tracking Screen │
│   Screen         │          │  (Suivi)        │
└──────────────────┘          └─────────────────┘
     │
     ├─────────┬─────────┐
     ▼         ▼         ▼
┌─────────┬─────────┬─────────┐
│ Step 1  │ Step 2  │ Step 3  │
│Location │Package  │Summary  │
└─────────┴─────────┴─────────┘
```

---

## 🗺️ Détails des Écrans par Flow

### 1️⃣ Flow d'Authentification

**LoginScreen** → **MainScreen** (après connexion)
- Champs: Téléphone, Mot de passe
- Actions:
  - "Se connecter" → MainScreen
  - "Mot de passe oublié ?" → [À implémenter]
  - "S'inscrire" → RegisterScreen

**LoginScreen** ← **RegisterScreen** (lien "Se connecter")
- Champs: Prénom, Nom, Téléphone, Mot de passe, Confirmation
- Actions:
  - "S'inscrire" → MainScreen (après inscription)
  - "Se connecter" → LoginScreen

---

### 2️⃣ Flow Principal (MainScreen)

**MainScreen** - Container avec 3 tabs:

```
┌────────────────────────────────────┐
│  Tab 1: HOME                       │
│  - Avatar + Nom                    │
│  - Bouton "Nouvelle Livraison"     │
│  - Historique récent               │
├────────────────────────────────────┤
│  Tab 2: NOTIFICATIONS              │
│  - Badge compteur                  │
│  - Recherche                       │
│  - Liste notifications             │
├────────────────────────────────────┤
│  Tab 3: PROFILE                    │
│  - Photo de profil                 │
│  - Infos personnelles              │
│  - Adresses favorites              │
│  - Bouton déconnexion              │
└────────────────────────────────────┘
```

**Navigation Bottom Bar**:
- Icône Maison → HomeScreen
- Icône Cloche → NotificationsScreen
- Icône Personne → ProfileScreen

---

### 3️⃣ Flow Nouvelle Livraison (3 Étapes)

**HomeScreen** → "Nouvelle Livraison" → **NewDeliveryScreen**

```
Étape 1/3: LOCATION (LocationStep)
┌────────────────────────────────────┐
│ [Carte avec markers A et B]        │
│                                    │
│ Point A (départ)                   │
│ [___________________________]      │
│                                    │
│ Point B (arrivée)                  │
│ [___________________________]      │
│                                    │
│ [⊙ Utiliser ma position]           │
│                                    │
│         [Suivant →]                │
└────────────────────────────────────┘
                  │
                  ▼
Étape 2/3: PACKAGE DETAILS (PackageDetailsStep)
┌────────────────────────────────────┐
│ Photo du colis                     │
│ [📷 Zone d'upload]                 │
│                                    │
│ Taille: ○ Petit ● Moyen ○ Grand   │
│                                    │
│ Poids: [5.5] kg                    │
│                                    │
│ Description: [_____________]       │
│                                    │
│ Mode: ● Standard (2h)              │
│       ○ Express (45min)            │
│                                    │
│ Assurance: [Toggle ON/OFF]         │
│                                    │
│ Prix estimé: 3500 FCFA             │
│                                    │
│   [← Précédent]  [Suivant →]      │
└────────────────────────────────────┘
                  │
                  ▼
Étape 3/3: SUMMARY (SummaryStep)
┌────────────────────────────────────┐
│ [Image d'en-tête]                  │
│                                    │
│ Détails de la livraison            │
│                                    │
│ 📍 De: 123 Rue...                  │
│ 🚩 À: 456 Avenue...                │
│                                    │
│ Colis: Moyen, 2.5kg                │
│ Mode: Express (45 minutes)         │
│                                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━          │
│ Total: 3500 FCFA                   │
│                                    │
│ ℹ️ Paiement à la livraison         │
│                                    │
│   [← Précédent]  [Confirmer]      │
└────────────────────────────────────┘
                  │
                  ▼
           [Retour Home]
```

---

### 4️⃣ Flow Suivi de Livraison

**HomeScreen** → Clic sur livraison → **TrackingScreen**

```
┌────────────────────────────────────┐
│ SUIVI DE LIVRAISON                 │
├────────────────────────────────────┤
│ [Carte avec position livreur]      │
│                                    │
│ ┌──────────────────────────────┐  │
│ │ 🏍️ En route vers B           │  │
│ │    12 min                     │  │
│ └──────────────────────────────┘  │
└────────────────────────────────────┘
│                                    │
│ 👤 Marie Dubois     [70%]          │
│    12 min restantes                │
│                                    │
│ Timeline:                          │
│ ✓ Commande créée        14:30      │
│ ✓ Livreur en route A    14:45      │
│ ✓ Colis récupéré        15:00      │
│ → En route vers B       En cours   │
│ ○ Livraison effectuée   À venir    │
│                                    │
│ ┌──────────────────────────────┐  │
│ │   [QR CODE]                  │  │
│ │   Montrez au livreur         │  │
│ │   Valable: 04:59             │  │
│ │   [🔄 Actualiser QR]         │  │
│ └──────────────────────────────┘  │
│                                    │
│ [💬 Contacter le livreur]          │
└────────────────────────────────────┘
```

---

### 5️⃣ Flow Notifications

**MainScreen** → Tab Notifications

```
┌────────────────────────────────────┐
│ Notifications (3)  [Tout marquer]  │
├────────────────────────────────────┤
│ [🔍 Rechercher...]                 │
├────────────────────────────────────┤
│ 🏍️ Livreur en route vers A    ●   │
│    Il arrive dans 3 min            │
│    Il y a 2 min                    │
├────────────────────────────────────┤
│ 📟 Code de réception prêt      ●   │
│    Montrez-le au livreur           │
│    Il y a 1h                       │
├────────────────────────────────────┤
│ ✅ Colis livré avec succès         │
│    Évaluez votre livreur           │
│    Il y a 2h                       │
└────────────────────────────────────┘
```

Actions:
- Clic sur notification → TrackingScreen (si deliveryId existe)
- Recherche filtre la liste
- "Tout marquer lu" marque toutes comme lues

---

### 6️⃣ Flow Profil

**MainScreen** → Tab Profil

```
┌────────────────────────────────────┐
│ PROFIL                         🔔   │
├────────────────────────────────────┤
│         [👤 Photo]                 │
│      Jean Dupont                   │
│  +225 07 12 34 56 78               │
│                                    │
│ Informations personnelles   [✏️]   │
│ └─ Nom: Dupont                     │
│ └─ Prénom: Jean                    │
│ └─ Téléphone: +225...              │
│                                    │
│ Adresses favorites                 │
│ ┌─ 📍 Maison              [🗑️]    │
│ │  123, Rue des Fleurs...         │
│ └─ 📍 Bureau              [🗑️]    │
│    456, Boulevard...               │
│                                    │
│ [+ Ajouter une adresse]            │
│                                    │
│                                    │
│ [🚪 Se déconnecter]                │
└────────────────────────────────────┘
```

Actions:
- Clic photo → [Upload/Modifier photo]
- ✏️ Edit → [Modal édition infos]
- 🗑️ Supprimer adresse → Confirmation
- "+ Ajouter" → [Modal ajout adresse]
- "Se déconnecter" → Confirmation → LoginScreen

---

## 🔄 Actions Transversales

### De n'importe quel écran:
- 🔔 Icône notifications → NotificationsScreen
- ← Back button → Écran précédent

### Bottom Navigation (disponible partout):
- 🏠 Home → HomeScreen
- 🔔 Notifications → NotificationsScreen
- 👤 Profil → ProfileScreen

---

## 📊 États des Écrans

### Loading States
Tous les écrans peuvent afficher:
- `LoadingIndicator` (spinner)
- `FullScreenLoader` (overlay)

### Error States
Tous les écrans peuvent afficher:
- `ErrorView` avec bouton "Réessayer"

### Empty States
- HomeScreen: "Aucune livraison"
- NotificationsScreen: "Aucune notification"

---

## 🎯 Points d'Entrée Principaux

1. **LoginScreen** - Point d'entrée de l'app
2. **HomeScreen** - Hub central après connexion
3. **NewDeliveryScreen** - Création de livraison
4. **TrackingScreen** - Suivi en temps réel

---

## 🚀 Navigation à Implémenter

### Manquant (à faire avec GoRouter):
- [ ] Deep links vers livraisons spécifiques
- [ ] Historique complet des livraisons
- [ ] Édition du profil (modal/écran)
- [ ] Ajout/Édition adresse (modal)
- [ ] Mot de passe oublié
- [ ] Conditions d'utilisation
- [ ] FAQ / Support détaillé
- [ ] Historique des transactions
- [ ] Recharge de quota

---

**Note**: Cette structure de navigation est prête à être implémentée avec **GoRouter** pour une navigation plus robuste et des deep links.
