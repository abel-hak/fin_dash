# SMS Transaction App

A mobile application that captures bank/mobile-money SMS alerts, parses them on-device, and allows users to approve and sync structured transactions to a backend server.

## Features

- **SMS Capture**: Automatically captures SMS alerts from banks and mobile money providers
- **On-device Parsing**: Extracts transaction details using regex templates
- **Manual Approval**: Users can review and approve transactions before syncing
- **Offline Support**: Queues transactions when offline and syncs when online
- **Privacy-focused**: All SMS processing happens on-device
- **Manual Entry**: Fallback option to paste SMS messages manually

## Tech Stack

- **Frontend**: Flutter (UI/logic)
- **SMS Plugin**: Kotlin (BroadcastReceiver + EventChannel)
- **Local Storage**: SQLite (via sqflite)
- **Authentication**: Supabase Auth
- **Backend**: Supabase Edge Functions

## Project Structure

```
/app
  /lib
    data/ (db, models)
    domain/ (parser, templates, fingerprint)
    features/
      auth/
      inbox/
      review/
      settings/
    services/ (sync_service, template_service, permissions)
    main.dart
  /android
    /src/main/kotlin/.../SmsReceiver.kt
    AndroidManifest.xml
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter plugins
- Android device or emulator (Android 8.0+)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sms_transaction_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure credentials** (REQUIRED)
   
   **Option A: Direct Configuration (Recommended for development)**
   - Open `lib/core/env_config.dart`
   - Replace placeholder values with your actual credentials:
     - `supabaseUrl`: Your Supabase project URL
     - `supabaseAnonKey`: Your Supabase anon/public key
     - `geminiApiKey`: Your Google Gemini API key (free tier)
   
   **Option B: Environment Variables**
   - Copy `.env.example` to `.env`
   - Update with your credentials
   - Use `--dart-define` flags when running (see below)
   
   **Getting Credentials:**
   - Supabase: https://supabase.com/dashboard/project/_/settings/api
   - Gemini API: https://makersuite.google.com/app/apikey (free tier available)

4. **Run the app**
   ```bash
   flutter run
   ```

   Or with custom environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
   ```

### Development Setup

- **Database Reset**: If you need to reset the database during development, uncomment line 22 in `lib/main.dart`
- **Debug Logs**: Enable/disable via `EnvConfig.enableDebugLogs`
- **Templates**: Edit `assets/templates.json` to add/modify SMS parsing templates

## SMS Templates

The app uses regex templates to parse transaction details from SMS messages. Templates are stored in a registry and can be updated remotely.

Example template:

```json
{
  "id": "telebirr_sms_en_v1",
  "sender": "Telebirr",
  "locale": "en",
  "patterns": {
    "amount": "ETB\\s*([\\d,]+(?:\\.\\d{2})?)",
    "merchant": "(?:to|at)\\s+([^,\\n]+)",
    "balance": "Balance:?\\s*ETB\\s*([\\d,]+(?:\\.\\d{2})?)",
    "account_alias": "(?:Acct|A/C|Wallet)\\s*([\\*\\d]+)"
  },
  "post": { "currency": "ETB", "channel": "telebirr" }
}
```

## License

This project is proprietary and confidential.
