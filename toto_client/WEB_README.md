# Configuration Flutter Web - TOTO Client

## Problème résolu

L'application rencontrait des erreurs lors de l'exécution en mode web car Flutter tentait de charger des ressources externes depuis des CDN:
- Police Roboto depuis Google Fonts
- Module CanvasKit depuis gstatic.com

## Solution

### 1. Configuration du rendu HTML (au lieu de CanvasKit)

Pour lancer l'application web sans dépendances CDN externes, utilisez le **rendeur HTML** au lieu de CanvasKit.

**Flutter 3.38+** utilise des variables d'environnement au lieu d'options CLI:

```bash
# Mode debug avec rendeur HTML
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=false

# Build de production avec rendeur HTML
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=false --release
```

### 2. Polices système configurées

Le fichier `web/index.html` a été modifié pour utiliser les polices système au lieu de charger Roboto depuis Google Fonts.

## Commandes utiles

### Développement

```bash
# Lancer en mode debug (Chrome) avec rendeur HTML
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=false

# Lancer en mode debug (serveur web) avec rendeur HTML
flutter run -d web-server --dart-define=FLUTTER_WEB_USE_SKIA=false

# Alternativement, laisser Flutter choisir automatiquement (auto)
flutter run -d chrome
```

### Production

```bash
# Build optimisé pour la production avec rendeur HTML
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=false --release

# Build avec auto-détection (recommandé pour Flutter 3.38+)
flutter build web --release

# Servir le build localement pour tester
cd build/web
python3 -m http.server 8000
# Puis ouvrir http://localhost:8000
```

## Différences entre les rendeurs

### HTML Renderer (recommandé pour cette app)
✅ Aucune dépendance CDN externe
✅ Fonctionne hors ligne
✅ Taille de bundle plus petite
✅ Meilleur pour le texte et les layouts simples
❌ Performance légèrement inférieure pour les animations complexes

### CanvasKit Renderer
✅ Meilleures performances pour les graphiques complexes
✅ Rendu pixel-perfect identique aux apps mobiles
❌ Nécessite de télécharger CanvasKit (~2MB) depuis CDN
❌ Plus grande taille de bundle
❌ Nécessite connexion internet au premier lancement

## Notes importantes

1. **Pour cette application**, le rendeur HTML est **suffisant** car:
   - Pas d'animations complexes
   - Interface principalement textuelle et formulaires
   - Utilise des composants Material Design standard

2. **Les images réseau** dans l'app (photos de profil, photos de colis) nécessitent toujours une connexion internet. Pour un fonctionnement 100% hors ligne, il faudrait:
   - Remplacer `Image.network()` par `Image.asset()`
   - Ajouter les images dans le dossier `assets/`
   - Configurer les assets dans `pubspec.yaml`

3. **Google Maps** et **Geolocator** ne fonctionneront pas en mode web sans configuration supplémentaire et connexion internet.
