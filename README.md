# Fisly

Fisly is an offline-first expense tracker that helps you capture receipts and
understand your spending.

## Getting started

1. Install the Flutter stable SDK and Android Studio.
2. Start an Android emulator or connect an Android device.
3. Fetch dependencies and run the app:

   ```sh
   flutter pub get
   flutter run
   ```

Run the checks used by CI with:

```sh
flutter analyze
flutter test
flutter build apk --release
```

For local build-time configuration, copy `.env.example` to `.env` and pass it
to Flutter:

```powershell
Copy-Item .env.example .env
flutter run --dart-define-from-file=.env
```

Keep real credentials in `.env`; it is excluded from Git.

## Project structure

- `lib/core/` contains app-wide routing and theme.
- `lib/features/` contains feature-specific screens and, as features grow, their
  data and domain layers.
- `test/` contains automated tests.

The UI will use Drift as its local source of truth. Supabase configuration
belongs in local, untracked build defines; never commit real credentials.
