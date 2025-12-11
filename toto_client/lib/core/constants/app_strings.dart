/// Chaînes de caractères de l'application
class AppStrings {
  AppStrings._();

  // Nom de l'application
  static const String appName = 'TOTO';
  static const String appSlogan = 'Votre livraison, notre priorité';

  // Authentification
  static const String login = 'Se connecter';
  static const String register = 'S\'inscrire';
  static const String logout = 'Se déconnecter';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String createAccount = 'Créer votre compte';
  static const String alreadyHaveAccount = 'Déjà un compte ?';
  static const String noAccount = 'Pas de compte ?';
  static const String welcome = 'Bienvenue !';
  static const String welcomeBack = 'Bienvenue, {name} !';

  // Champs de formulaire
  static const String firstName = 'Prénom';
  static const String lastName = 'Nom';
  static const String phone = 'Téléphone';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer mot de passe';
  static const String email = 'Email';

  // Navigation
  static const String home = 'Accueil';
  static const String deliveries = 'Livraisons';
  static const String support = 'Support';
  static const String profile = 'Profil';
  static const String notifications = 'Notifications';

  // Livraison
  static const String newDelivery = 'Nouvelle Livraison';
  static const String deliveryHistory = 'Historique récent';
  static const String trackDelivery = 'Suivi de Livraison';
  static const String deliveryDetails = 'Détails de la livraison';
  static const String packageDetails = 'Détails du colis';
  static const String from = 'De';
  static const String to = 'À';
  static const String pickupAddress = 'Adresse de départ';
  static const String deliveryAddress = 'Adresse de destination';
  static const String enterPickupAddress = 'Entrez l\'adresse de départ';
  static const String enterDeliveryAddress = 'Entrez l\'adresse d\'arrivée';
  static const String useMyLocation = 'Utiliser ma position';
  static const String next = 'Suivant';
  static const String previous = 'Précédent';
  static const String confirm = 'Confirmer';
  static const String confirmDelivery = 'Confirmer la demande';

  // Détails du colis
  static const String packagePhoto = 'Photo du colis';
  static const String addPhoto = 'Ajouter une photo';
  static const String packageSize = 'Taille du colis';
  static const String packageWeight = 'Poids du colis (kg)';
  static const String packageDescription = 'Description du contenu';
  static const String deliveryMode = 'Mode de livraison';
  static const String standard = 'Standard';
  static const String express = 'Express';
  static const String addInsurance = 'Ajouter une assurance';
  static const String estimatedPrice = 'Prix estimé :';

  // Tailles
  static const String small = 'Petit';
  static const String medium = 'Moyen';
  static const String large = 'Grand';

  // Statuts
  static const String pending = 'En attente';
  static const String inProgress = 'En cours';
  static const String delivered = 'Livré';
  static const String cancelled = 'Annulé';

  // Profil
  static const String personalInfo = 'Informations personnelles';
  static const String favoriteAddresses = 'Adresses favorites';
  static const String addAddress = 'Ajouter une adresse';
  static const String transactionHistory = 'Historique des transactions';
  static const String wallet = 'Mon portefeuille';
  static const String rechargeQuota = 'Recharger quota';

  // Support
  static const String needHelp = 'Besoin d\'aide ?';
  static const String contactSupport = 'Discuter avec le support';
  static const String contactDeliverer = 'Contacter le livreur';
  static const String weRespondIn5Min = 'Nous répondons en moins de 5 minutes';

  // Messages
  static const String loading = 'Chargement...';
  static const String error = 'Erreur';
  static const String success = 'Succès';
  static const String noData = 'Aucune donnée disponible';
  static const String retry = 'Réessayer';
  static const String cancel = 'Annuler';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';

  // Récapitulatif
  static const String summary = 'Récapitulatif';
  static const String deliverySummary = 'Détails de la livraison';
  static const String paymentAtDelivery = 'Paiement à la livraison par le destinataire';

  // Suivi
  static const String delivererOnWay = 'Livreur en route vers A';
  static const String packagePickedUp = 'Colis récupéré';
  static const String delivererOnWayToB = 'Livreur en route vers B';
  static const String showQRCode = 'Montrez ce QR au livreur pour valider la réception';
  static const String validUntil = 'Valable encore';
  static const String refreshQR = 'Actualiser QR';
  static const String deliveryCompleted = 'Livraison effectuée !';
  static const String rateDeliverer = 'Évaluer le livreur';
  static const String rateCustomer = 'Évaluer le client';
  static const String backToDashboard = 'Retour au tableau de bord';

  // Notifications
  static const String markAllAsRead = 'Tout marquer lu';
  static const String searchNotifications = 'Rechercher des notifications...';

  // Erreurs de validation
  static const String fieldRequired = 'Ce champ est requis';
  static const String invalidPhone = 'Numéro de téléphone invalide';
  static const String invalidEmail = 'Email invalide';
  static const String passwordTooShort = 'Mot de passe trop court (min. 6 caractères)';
  static const String passwordsDontMatch = 'Les mots de passe ne correspondent pas';

  // Devise
  static const String currency = 'FCFA';

  // Temps
  static const String hours2 = '2 heures';
  static const String minutes45 = '45 minutes';
  static const String minRemaining = 'min restantes';

  // Termes et conditions
  static const String acceptTerms = 'J\'accepte';
  static const String termsAndConditions = 'les conditions d\'utilisation';

  // Paiement
  static const String payVia = 'Payer via';
  static const String mobileMoney = 'Mobile Money';
  static const String quotaWillBeConverted = 'Votre quota sera immédiatement converti et disponible après confirmation de votre paiement.';
  static const String availableBalance = 'Solde disponible';
  static const String remainingQuota = 'Quota restant :';
}
