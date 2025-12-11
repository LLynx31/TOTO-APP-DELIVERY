# 🎨 Améliorations UI/UX - Application TOTO Client

## ✅ Modifications Appliquées

### 1. **Couleurs Mises à Jour**
- Vert primaire: `#00D97E` (boutons)
- Bleu secondaire: `#29B6F6` (logo, accents)
- Background: `#F5F7FA`

---

## 📋 Modifications à Appliquer

### **LoginScreen** (Page 11 du PDF)

**Changements clés:**
- Logo: Icône de colis 3D (`Icons.inventory_2_rounded`) avec background bleu cyan rond (20px radius)
- Titre "Bienvenue !" centré en gros
- Pas de sous-titre "Connectez-vous pour continuer"
- Champs avec labels simples
- Bouton "Mot de passe oublié ?" en bleu sous le bouton principal
- Lien "Pas de compte ? S'inscrire" en bas avec "S'inscrire" en bleu

---

### **RegisterScreen** (Page 10 du PDF)

**Changements clés:**
- Logo en haut avec "Destinee" (à remplacer par "TOTO")
- Titre "Créer votre compte" centré
- Champs avec background très clair (#F5F7FA)
- Téléphone avec préfixe "+225" séparé
- Checkbox avec lien "les conditions d'utilisation" en bleu
- "Déjà un compte ? Se connecter" en bas

---

### **HomeScreen** (Page 1 du PDF)

**Changements clés:**
- Avatar utilisateur en haut à gauche avec point vert (statut en ligne)
- "Bienvenue, Jean !" à côté de l'avatar (pas "Bienvenue, Jean !")
- Cloche notification BLEUE en haut à droite (pas rouge)
- Illustration livreur sur moto VERTE (chercher illustration ou utiliser image)
- Bouton "Nouvelle Livraison" VERT avec icône de colis blanc
- Cartes d'historique:
  - Status "En court" avec badge orange clair
  - Status "Livré" avec badge vert clair
  - Icônes: point pour "De:", losange pour "À:"
  - Date alignée à droite

---

### **Bottom Navigation** (Toutes les pages)

**Changements clés:**
- 4 tabs au lieu de 3: **Accueil | Livraisons | Support | Profil**
- Tab active en BLEU (`#29B6F6`) pas vert
- Icônes:
  - Accueil: `Icons.home` / `Icons.home_outlined`
  - Livraisons: `Icons.inventory_2` / `Icons.inventory_2_outlined`
  - Support: `Icons.headset_mic` / `Icons.headset_mic_outlined`
  - Profil: `Icons.person` / `Icons.person_outlined`

---

### **LocationStep** (Page 2 du PDF)

**Changements clés:**
- Titre "Emplacement" avec compteur "1/3" à droite
- Labels "Point A (départ)" et "Point B (arrivée)" en gris
- Champs avec placeholder gris clair
- Bouton "Utiliser ma position" avec icône de cible, fond gris clair
- Carte Google Maps réelle en bas avec markers A (cyan) et B (vert)
- Bouton "Suivant" BLEU CYAN en bas

---

### **PackageDetailsStep** (Page 3 du PDF)

**Changements clés:**
- Titre "Détails du colis" avec "2/3"
- Zone upload photo avec bordure en pointillés
- Dropdown pour "Taille du colis" (pas des cards)
- Champs simples avec bordures grises
- Mode de livraison: Cards avec fond bleu clair pour sélectionné
- Toggle switch pour assurance (gris/vert)
- Prix estimé en GROS et en GRAS en bas
- Boutons "Précédent" (outline bleu) et "Suivant" (bleu plein)

---

### **SummaryStep** (Page 4 du PDF)

**Changements clés:**
- Image d'en-tête décorative (boussole/carte)
- Section "Détails de la livraison" avec fond blanc
- Photo du colis si ajoutée
- Infos en liste simple (De:, À:, Colis:, Mode:)
- Prix estimé en VERT (#00D97E) et gros
- Note "Paiement à la livraison par le destinataire" en gris
- Bouton "Confirmer la demande" VERT pleine largeur

---

### **TrackingScreen** (Pages 7-8 du PDF)

**Changements clés:**
- Carte avec itinéraire en pointillés bleus
- Marker rouge pour destination
- Icône moto bleue pour livreur
- Card info livreur avec photo ronde
- Barre de progression BLEUE (pas verte)
- "70% terminé" à droite de la barre
- Bouton "Contacter le livreur" BLEU CYAN
- QR Code dans card blanche avec bordure
- "Valable encore 04:59" en rouge/gris
- Bouton "Actualiser QR" en bleu clair

**Page 8 - Liste historique:**
- Cards simples avec icônes et badges de statut
- "En court" en orange
- "Livré" en vert

---

### **ProfileScreen** (Page 5 du PDF)

**Changements clés:**
- Photo de profil grande et centrée
- Nom en gros sous la photo
- Téléphone avec icône en gris
- Section "Informations personnelles" avec champs affichés (pas éditables inline)
- Section "Préférences" puis "Adresses favorites"
- Adresses avec icône location et bouton poubelle ROUGE
- Bouton "+ Ajouter une adresse" en BLEU
- Bouton "Se déconnecter" ROUGE en bas

---

### **NotificationsScreen** (Page 12 du PDF)

**Changements clés:**
- Icône app (colis bleu) en haut à gauche
- Badge rouge avec nombre
- "Tout marquer lu" en bleu à droite
- Barre de recherche avec fond gris clair
- Notifications avec:
  - Icône colorée à gauche (vert pour livraison, bleu pour code, etc.)
  - Titre en gras
  - Description en gris
  - Temps "Il y a X min" en bleu à droite

---

### **Support Screen** (Page 6 du PDF)

**À CRÉER:**
- Titre "Besoin d'aide ?"
- Illustration support (personne avec casque)
- Bouton vert "Discuter avec le support" avec icône chat
- Numéro de téléphone en gros: +225 01 23 45 67 89
- "Nous répondons en moins de 5 minutes" en gris

---

### **Delivery Success Screen** (Page 9 du PDF)

**À CRÉER:**
- Icône checkmark dans cercle noir
- "Livraison effectuée !" en gros titre
- Message avec adresse de livraison
- Image de personnes (illustration)
- Bouton bleu "Évaluer le livreur"
- Bouton outline "Retour au tableau de bord"

---

### **Confirmation Screen avec QR** (Page 13 du PDF)

**À CRÉER:**
- Icône checkmark vert dans cercle
- "Colis en attente de livraison"
- QR Code grand
- "Montrez ce QR au livreur pour valider la réception"
- "Valable encore 04:59"
- Bouton "Actualiser QR" bleu clair
- Section "Point de livraison (Adresse de destination)" avec image carte
- Bouton vert "Contacter livreur via WhatsApp"

---

## 🎯 Priorités

### Haute Priorité
1. ✅ Couleurs
2. LoginScreen
3. HomeScreen
4. Bottom Navigation (4 tabs)

### Moyenne Priorité
5. RegisterScreen
6. TrackingScreen
7. ProfileScreen

### Basse Priorité
8. Support Screen (à créer)
9. Success Screen (à créer)
10. Confirmation Screen (à créer)

---

## 💡 Notes Techniques

### Icônes à Utiliser
- Colis: `Icons.inventory_2_rounded`
- Location: `Icons.location_on` / `Icons.location_on_outlined`
- Cible: `Icons.my_location`
- Casque: `Icons.headset_mic`
- Chat: `Icons.chat_bubble_outline`
- Camion: `Icons.local_shipping`

### Polices
- Titres: Bold (FontWeight.w700)
- Sous-titres: SemiBold (FontWeight.w600)
- Corps: Regular (FontWeight.w400)
- Labels: Medium (FontWeight.w500)

### Espacements Standards
- Petit: 8px
- Moyen: 16px
- Grand: 24px
- Très grand: 32px

### Border Radius
- Petits éléments: 8px
- Cards: 12px
- Boutons: 12px
- Logo: 20px

---

**Date**: 20 Novembre 2025
**Status**: En cours d'implémentation
