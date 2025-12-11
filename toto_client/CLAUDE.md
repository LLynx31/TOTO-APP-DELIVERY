# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TOTO Client is a Flutter mobile application for parcel delivery services targeting West Africa (primarily Côte d'Ivoire). The app enables users to request deliveries, track parcels in real-time, and manage their delivery history.

**Current Status**: Frontend UI is ~80% complete; backend integration and state management implementation are pending.

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app (select device when prompted)
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Clean build artifacts and reinstall dependencies
flutter clean && flutter pub get
```

### Development Workflow
1. After pulling changes: `flutter pub get`
2. Before committing: `flutter analyze` to check for issues
3. If build issues occur: `flutter clean && flutter pub get`

## Architecture

### Project Structure

The codebase follows a **feature-first architecture** with three main directories:

```
lib/
├── core/          # Design system and app-wide constants
├── features/      # Feature modules (one directory per feature)
└── shared/        # Cross-cutting concerns (models, widgets, services, providers)
```

### Core Design System

All design tokens live in [lib/core/](lib/core/):
- **Colors**: [app_colors.dart](lib/core/app_colors.dart) - Brand colors, semantic colors (success/error/warning)
- **Sizes**: [app_sizes.dart](lib/core/app_sizes.dart) - Spacing, border radius, icon sizes
- **Theme**: [app_theme.dart](lib/core/app_theme.dart) - Material Design 3 theme configuration
- **Strings**: [app_strings.dart](lib/core/app_strings.dart) - French localized strings (all UI text)

**Important**: Always use constants from these files rather than hardcoding values.

### Feature Modules

Each feature follows the same internal structure:
```
features/<feature_name>/
├── models/        # Feature-specific data models
├── providers/     # Riverpod providers (currently empty - not implemented)
├── services/      # Business logic and API calls (currently empty - not implemented)
├── widgets/       # Feature-specific UI components
└── <screen_name>_screen.dart  # Screen entry points
```

**Key Features**:
- **auth**: Login/registration screens (email + phone number)
- **home**: Dashboard with new delivery button
- **delivery**: Three-step delivery wizard (sender → recipient → summary) + tracking screen
- **profile**: User profile and history
- **support**: Help/FAQ screens
- **notifications**: Notification list screen

### Application Flow

1. **Entry Point**: [main.dart](lib/main.dart) → [MainScreen](lib/features/home/main_screen.dart)
2. **Main Navigation**: Bottom navigation bar with 4 tabs (Home, Deliveries, Support, Profile)
3. **Delivery Creation**: Three-step wizard:
   - Step 1: [SenderInfoScreen](lib/features/delivery/sender_info_screen.dart)
   - Step 2: [RecipientInfoScreen](lib/features/delivery/recipient_info_screen.dart)
   - Step 3: [DeliverySummaryScreen](lib/features/delivery/delivery_summary_screen.dart)
4. **Tracking**: [TrackingScreen](lib/features/delivery/tracking_screen.dart) with real-time map

### State Management (Planned, Not Implemented)

- **Framework**: Riverpod 2.0+ (dependency configured)
- **Current State**: All `providers/` directories are empty placeholders
- **Implementation Status**: App currently uses StatefulWidget for local state
- **Next Steps**: Implement providers for:
  - Authentication state
  - Delivery data
  - User profile
  - Real-time tracking updates

### Navigation (Planned, Not Implemented)

- **Framework**: GoRouter (dependency configured)
- **Current State**: Basic `MaterialApp` with `Navigator.push`
- **Planned Routes**: See [NAVIGATION.md](NAVIGATION.md) for detailed route structure
- **Implementation Status**: Manual navigation currently used throughout

### Backend Integration (Not Implemented)

All `services/` directories are empty. Backend integration is pending:
- API client setup needed (Dio configured in dependencies)
- Authentication flow
- Delivery CRUD operations
- Real-time tracking updates
- Payment integration

## Shared Components

### Reusable Widgets

Located in [lib/shared/widgets/](lib/shared/widgets/):
- **custom_button.dart**: Primary/secondary button variants
- **custom_text_field.dart**: Form input with validation
- **location_picker.dart**: Map-based location selection (Google Maps)

### Models

Located in [lib/shared/models/](lib/shared/models/):
- **user_model.dart**: User data structure
- **delivery_model.dart**: Delivery/parcel data structure

**Note**: Models currently lack serialization methods (fromJson/toJson) - these will be needed for API integration.

## Key Dependencies

- **riverpod**: 2.5.1 (state management - not yet used)
- **dio**: 5.4.0 (HTTP client - not yet configured)
- **google_maps_flutter**: 2.5.0 (map display)
- **geolocator**: 10.1.0 (location services)
- **qr_flutter** & **qr_code_scanner**: QR code generation/scanning
- **image_picker**: 1.0.5 (photo uploads)

## Testing

- **Current Status**: Minimal test coverage (one basic widget test)
- **Test Location**: [test/](test/)
- **Run Tests**: `flutter test`

## Additional Documentation

- [FEATURES.md](FEATURES.md): Detailed feature descriptions and user stories
- [NAVIGATION.md](NAVIGATION.md): Complete navigation structure and route definitions
- [ROADMAP.md](ROADMAP.md): Development phases and timeline

## Important Notes

1. **All UI text is in French** - strings defined in [app_strings.dart](lib/core/app_strings.dart)
2. **Design system must be used** - avoid hardcoding colors/sizes
3. **Backend is not connected** - all data is currently static/mock data
4. **No authentication** - login screen is UI-only
5. **Maps require API key** - Google Maps API key needed in platform-specific config
6. **Location permissions** - Handle runtime permissions for Android/iOS
