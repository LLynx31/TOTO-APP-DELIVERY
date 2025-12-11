/// Chaînes de caractères de l'application TOTO Deliverer
/// Toutes les chaînes sont en français
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'TOTO Livreur';
  static const String appTagline = 'Votre partenaire de livraison';

  // Auth
  static const String login = 'Se connecter';
  static const String signup = 'S\'inscrire';
  static const String logout = 'Se déconnecter';
  static const String phone = 'Téléphone';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer mot de passe';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas de compte ?';
  static const String alreadyHaveAccount = 'Déjà un compte ?';
  static const String createAccount = 'Créer votre compte';
  static const String firstName = 'Prénom';
  static const String lastName = 'Nom';
  static const String email = 'Email';

  // KYC / Verification
  static const String verification = 'Vérification';
  static const String drivingLicense = 'Permis de conduire';
  static const String identityPhoto = 'Photo d\'identité';
  static const String vehiclePhoto = 'Photo du véhicule';
  static const String uploadDocument = 'Télécharger le document';
  static const String termsAndConditions = 'J\'accepte les conditions d\'utilisation';
  static const String verified = 'Vérifié';
  static const String pending = 'En attente';

  // Dashboard
  static const String dashboard = 'Tableau de bord';
  static const String availableCourses = 'Courses Disponibles';
  static const String myStatusAndQuota = 'Mon Statut et Quota';
  static const String quotaRemaining = 'Quota restant';
  static const String deliveries = 'livraisons';
  static const String online = 'Je suis en ligne';
  static const String offline = 'Hors ligne';
  static const String goOnline = 'Passer en ligne';
  static const String goOffline = 'Passer hors ligne';
  static const String seeDetails = 'Voir détails';
  static const String noCourses = 'Aucune course disponible';
  static const String rechargeQuota = 'Rechargez votre quota pour accepter des courses';

  // Course Details
  static const String courseDetails = 'Détails de la Course';
  static const String deliveryItinerary = 'Votre Itinéraire de Livraison';
  static const String packagePhoto = 'Photo du colis';
  static const String from = 'De:';
  static const String to = 'À:';
  static const String size = 'Taille:';
  static const String weight = 'Poids:';
  static const String mode = 'Mode:';
  static const String proposedPrice = 'Prix proposé:';
  static const String acceptCourse = 'Accepter la course';
  static const String insufficientQuota = 'Rechargez d\'abord votre quota pour accepter cette course.';
  static const String standard = 'Standard';
  static const String express = 'Express';
  static const String paymentAtDelivery = 'Paiement à la livraison';

  // Course Status
  static const String enRouteToPickup = 'En route vers A';
  static const String arrivedAtPickup = 'Arrivé au point A';
  static const String packagePickedUp = 'Colis récupéré';
  static const String enRouteToDestination = 'En route vers B';
  static const String packageDelivered = 'Livré';
  static const String inProgress = 'En cours';
  static const String completed = 'Terminé';
  static const String cancelled = 'Annulé';

  // Tracking
  static const String newStatus = 'Nouveau statut :';
  static const String reportProblem = 'Signaler un problème';
  static const String deliveryCompleted = 'Course terminée avec succès !';
  static const String deliveredTo = 'Colis livré à';
  static const String earned = 'Prix gagné :';
  static const String quotaUpdated = 'Quota mis à jour';
  static const String rateCustomer = 'Évaluer le client';
  static const String backToDashboard = 'Revenir au dashboard';

  // Timeline
  static const String deliveryTimeline = 'Progression de la livraison';
  static const String orderCreated = 'Course acceptée';
  static const String routeToPickup = 'En route vers le point A';
  static const String packageCollected = 'Colis récupéré';
  static const String routeToDelivery = 'En route vers le point B';
  static const String deliveryComplete = 'Livraison effectuée';

  // Package Info
  static const String packageDetails = 'Détails du colis';
  static const String packageDescription = 'Description';
  static const String noDescription = 'Aucune description';

  // ETA & Distance
  static const String estimatedArrival = 'Arrivée estimée';
  static const String distance = 'Distance';
  static const String minutes = 'min';
  static const String kilometers = 'km';

  // Contact
  static const String callCustomer = 'Appeler le client';
  static const String calling = 'Appel en cours...';

  // Navigation
  static const String openNavigation = 'Ouvrir la navigation';
  static const String navigateWith = 'Naviguer avec';
  static const String googleMaps = 'Google Maps';
  static const String waze = 'Waze';

  // Problem Reporting
  static const String describeProb = 'Décrivez le problème';
  static const String addPhoto = 'Ajouter une photo';
  static const String photoAdded = 'Photo ajoutée';
  static const String submitReport = 'Envoyer le signalement';
  static const String customerAbsent = 'Client absent';
  static const String addressNotFound = 'Adresse introuvable';
  static const String packageIssue = 'Problème avec le colis';
  static const String otherProblem = 'Autre problème';
  static const String problemReported = 'Problème signalé avec succès';

  // Delivery Mode
  static const String expressDelivery = 'Livraison Express';
  static const String standardDelivery = 'Livraison Standard';

  // Quota
  static const String rechargeYourQuota = 'Rechargez votre quota';
  static const String currentQuota = 'Quota restant :';
  static const String chooseAPack = 'Choisissez un pack';
  static const String recommended = 'Recommandé';
  static const String bestValue = 'Meilleure valeur';
  static const String pack = 'Pack';
  static const String payViaMobileMoney = 'Payer via Mobile Money';
  static const String quotaWillBeConverted = 'Votre quota sera immédiatement converti et disponible après confirmation de votre paiement.';
  static const String discount = '-5%';

  // Wallet
  static const String wallet = 'Portefeuille';
  static const String availableBalance = 'Solde disponible';
  static const String monthlyBalance = 'Solde mensuel';
  static const String transactionHistory = 'Historique des transactions';
  static const String recharge = 'Recharge :';
  static const String withdrawal = 'Retrait :';
  static const String via = 'via';
  static const String cash = 'en espèces';

  // History
  static const String history = 'Historique';
  static const String myPastCourses = 'Mes courses passées';
  static const String searchInHistory = 'Rechercher dans l\'historique...';
  static const String totalEarnings = 'Gains totaux :';
  static const String exportPDF = 'Exporter PDF';
  static const String status = 'Statut :';
  static const String date = 'Date :';

  // Profile
  static const String profile = 'Profil';
  static const String myProfile = 'Mon Profil';
  static const String personalInfo = 'Infos personnelles';
  static const String vehicle = 'Véhicule';
  static const String type = 'Type';
  static const String plate = 'Plaque';
  static const String documents = 'Documents';
  static const String idCard = 'Carte d\'identité';
  static const String edit = 'Modifier';
  static const String save = 'Enregistrer';

  // Scanner
  static const String scanQR = 'Scanner QR';
  static const String scanCustomerQR = 'Scanner le QR du client';
  static const String scanRecipientQR = 'Scannez le QR du destinataire';
  static const String manualCode = 'Code manuel';
  static const String enterCode = 'Saisissez le code à 4 chiffres fourni par le destinataire';
  static const String validate = 'Valider';
  static const String cameraLive = 'Flux Caméra Live';

  // Rating
  static const String rateYourExperience = 'Évaluez votre expérience';
  static const String howWasDelivery = 'Comment s\'est passée votre livraison ?';
  static const String feedback = 'Nous aimerions avoir votre avis sur la livraison que vous venez de terminer.';
  static const String optionalComment = 'Commentaire optionnel';
  static const String shareYourFeedback = 'Partagez vos impressions sur le service...';
  static const String sendRating = 'Envoyer l\'évaluation';
  static const String ratingHelps = 'Votre avis aide à améliorer le service.';

  // Navigation
  static const String courses = 'Courses';
  static const String myWallet = 'Portefeuille';

  // Common
  static const String back = 'Retour';
  static const String next = 'Suivant';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String delete = 'Supprimer';
  static const String yes = 'Oui';
  static const String no = 'Non';
  static const String ok = 'OK';
  static const String error = 'Erreur';
  static const String success = 'Succès';
  static const String loading = 'Chargement...';
  static const String retry = 'Réessayer';

  // Messages
  static const String courseAccepted = 'Course acceptée avec succès !';
  static const String courseAcceptedDesc = 'Dirigez-vous vers le point de collecte';
  static const String packageScanned = 'Colis scanné avec succès';
  static const String deliveryConfirmed = 'Livraison confirmée';
  static const String quotaRecharged = 'Quota rechargé avec succès';
  static const String errorOccurred = 'Une erreur s\'est produite';
  static const String tryAgain = 'Veuillez réessayer';

  // Validation
  static const String requiredField = 'Ce champ est requis';
  static const String invalidPhone = 'Numéro de téléphone invalide';
  static const String invalidEmail = 'Email invalide';
  static const String passwordTooShort = 'Mot de passe trop court (min. 6 caractères)';
  static const String passwordsDoNotMatch = 'Les mots de passe ne correspondent pas';
}
