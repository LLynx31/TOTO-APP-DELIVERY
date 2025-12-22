/// Chaînes de caractères localisées (Français)
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'TOTO';
  static const String appTagline = 'Livraison rapide et fiable';

  // Auth
  static const String login = 'Se connecter';
  static const String loginSubtitle = 'Connectez-vous pour continuer';
  static const String register = 'S\'inscrire';
  static const String logout = 'Se déconnecter';
  static const String phoneNumber = 'Numéro de téléphone';
  static const String phoneHint = '+225 XX XX XX XX XX';
  static const String password = 'Mot de passe';
  static const String passwordHint = 'Entrez votre mot de passe';
  static const String enterPassword = 'Entrez votre mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  static const String fullName = 'Nom complet';
  static const String fullNameHint = 'Entrez votre nom complet';
  static const String email = 'Email (optionnel)';
  static const String emailHint = 'exemple@email.com';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas encore de compte ?';
  static const String hasAccount = 'Déjà un compte ?';
  static const String createAccount = 'Créer un compte';

  // Navigation
  static const String home = 'Accueil';
  static const String deliveries = 'Livraisons';
  static const String quota = 'Crédit';
  static const String profile = 'Profil';

  // Home
  static const String welcomeBack = 'Bon retour';
  static const String goodMorning = 'Bonjour';
  static const String goodAfternoon = 'Bon après-midi';
  static const String goodEvening = 'Bonsoir';
  static const String whereToDeliver = 'Où allons-nous ?';
  static const String newDelivery = 'Nouvelle livraison';
  static const String activeDeliveries = 'Livraisons actives';
  static const String recentDeliveries = 'Livraisons récentes';
  static const String viewAll = 'Voir tout';
  static const String noActiveDeliveries = 'Aucune livraison active';
  static const String noDeliveries = 'Aucune livraison';

  // Create Delivery
  static const String createDelivery = 'Créer une livraison';
  static const String step = 'Étape';
  static const String stepOf = 'sur';
  static const String pickupLocation = 'Point d\'enlèvement';
  static const String deliveryLocation = 'Point de livraison';
  static const String packageDetails = 'Détails du colis';
  static const String reviewAndConfirm = 'Récapitulatif';
  static const String pickupAddress = 'Adresse d\'enlèvement';
  static const String deliveryAddress = 'Adresse de livraison';
  static const String searchAddress = 'Rechercher une adresse';
  static const String useCurrentLocation = 'Utiliser ma position';
  static const String confirmLocation = 'Confirmer';
  static const String pointA = 'Point A';
  static const String pointB = 'Point B';
  static const String receiverName = 'Nom du destinataire';
  static const String receiverPhone = 'Téléphone du destinataire';
  static const String packageDescription = 'Description du colis';
  static const String packageWeight = 'Poids (kg)';
  static const String specialInstructions = 'Instructions spéciales';
  static const String estimatedPrice = 'Prix estimé';
  static const String distance = 'Distance';
  static const String payAndOrder = 'Payer et commander';
  static const String next = 'Suivant';
  static const String back = 'Retour';
  static const String cancel = 'Annuler';

  // Delivery Status
  static const String pending = 'En attente';
  static const String accepted = 'Acceptée';
  static const String pickupInProgress = 'En route vers enlèvement';
  static const String pickedUp = 'Colis récupéré';
  static const String deliveryInProgress = 'En cours de livraison';
  static const String delivered = 'Livrée';
  static const String cancelled = 'Annulée';

  // Tracking
  static const String trackDelivery = 'Suivre la livraison';
  static const String driverOnWay = 'Livreur en route';
  static const String estimatedArrival = 'Arrivée estimée';
  static const String minutes = 'min';
  static const String kilometers = 'km';
  static const String callDriver = 'Appeler';
  static const String messageDriver = 'Message';
  static const String showQRCode = 'Afficher le code QR';
  static const String cancelDelivery = 'Annuler la livraison';
  static const String deliveryCompleted = 'Livraison terminée';

  // Quota
  static const String myQuota = 'Mon crédit';
  static const String remainingDeliveries = 'Livraisons restantes';
  static const String buyQuota = 'Acheter un forfait';
  static const String quotaPackages = 'Forfaits disponibles';
  static const String deliveriesIncluded = 'livraisons incluses';
  static const String validFor = 'Valable';
  static const String days = 'jours';
  static const String purchase = 'Acheter';
  static const String quotaHistory = 'Historique';
  static const String noQuota = 'Aucun crédit';
  static const String buyQuotaToContinue = 'Achetez un forfait pour commander';

  // Payment
  static const String payment = 'Paiement';
  static const String selectPaymentMethod = 'Choisir un mode de paiement';
  static const String mobileMoney = 'Mobile Money';
  static const String orangeMoney = 'Orange Money';
  static const String mtnMoney = 'MTN Money';
  static const String wave = 'Wave';
  static const String card = 'Carte bancaire';
  static const String cash = 'Espèces';
  static const String cashOnDelivery = 'À la livraison';
  static const String amount = 'Montant';
  static const String pay = 'Payer';
  static const String processing = 'Traitement en cours...';
  static const String paymentSuccess = 'Paiement réussi !';
  static const String paymentFailed = 'Paiement échoué';
  static const String tryAgain = 'Réessayer';
  static const String transactionId = 'N° Transaction';

  // Profile
  static const String editProfile = 'Modifier le profil';
  static const String settings = 'Paramètres';
  static const String notifications = 'Notifications';
  static const String language = 'Langue';
  static const String help = 'Aide';
  static const String about = 'À propos';
  static const String termsOfService = 'Conditions d\'utilisation';
  static const String privacyPolicy = 'Politique de confidentialité';
  static const String version = 'Version';

  // Errors
  static const String error = 'Erreur';
  static const String errorOccurred = 'Une erreur est survenue';
  static const String networkError = 'Erreur de connexion';
  static const String checkConnection = 'Vérifiez votre connexion internet';
  static const String invalidPhone = 'Numéro de téléphone invalide';
  static const String invalidPassword = 'Mot de passe invalide (min. 6 caractères)';
  static const String passwordMismatch = 'Les mots de passe ne correspondent pas';
  static const String requiredField = 'Ce champ est requis';
  static const String invalidCredentials = 'Identifiants incorrects';
  static const String sessionExpired = 'Session expirée';
  static const String pleaseLoginAgain = 'Veuillez vous reconnecter';

  // Success
  static const String success = 'Succès';
  static const String deliveryCreated = 'Livraison créée avec succès';
  static const String quotaPurchased = 'Forfait acheté avec succès';
  static const String profileUpdated = 'Profil mis à jour';

  // Buttons
  static const String ok = 'OK';
  static const String confirm = 'Confirmer';
  static const String close = 'Fermer';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String retry = 'Réessayer';
  static const String skip = 'Passer';
  static const String done = 'Terminé';
  static const String continue_ = 'Continuer';
  static const String goHome = 'Retour à l\'accueil';

  // Empty states
  static const String noData = 'Aucune donnée';
  static const String nothingHere = 'Rien à afficher';

  // Loading
  static const String loading = 'Chargement...';
  static const String pleaseWait = 'Veuillez patienter';

  // Currency
  static const String currency = 'FCFA';
  static const String currencySymbol = 'F';
}
