# Fisly

Fisly is an offline-first expense tracker that helps you capture receipts and
understand your spending.

## Current functionality

- Offline expense CRUD with default and custom categories.
- Merchant-name category suggestions for common Turkish merchants.
- Monthly spending total, category breakdown, and six-month trend charts.
- On-device receipt text recognition with locally stored receipt images.
- Receipt OCR suggestions for merchant, date, and total can be reviewed before saving.
- A monthly spending limit with remaining-budget and overspending indicators.
- Monthly recurring bills and subscriptions can be confirmed as expenses when paid.
- Monthly reports summarize spending by category and merchant and can be shared as CSV.

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

To enable optional Supabase email/password accounts, create a Supabase project,
copy `.env.example` to `.env`, and set the project URL and publishable key from
the Supabase dashboard. Leave both values empty to keep using Fisly locally
without an account:

```powershell
Copy-Item .env.example .env
flutter run --dart-define-from-file=.env
```

Keep real configuration in `.env`; it is excluded from Git. Never put a
Supabase `service_role` key in the app.

The initial user-owned database schema and row-level security policies are in
`supabase/migrations/`. Applying the migration creates empty cloud tables; it
does not upload existing local data. RLS tests are in `supabase/tests/` and can
be run with the Supabase CLI and a local Docker database.

New local create, update, and delete operations are recorded in a Drift sync
queue with per-account acknowledgements. Existing rows are not queued
automatically. The signed-in account screen stores a per-user import decision
and can manually synchronize categories after consent. Same-name categories
share a cloud ID without changing local expense references. Only categories are
synchronized at this stage; expenses, budgets, and recurring expenses remain
local.

## Project structure

- `lib/core/` contains app-wide routing, theme, and database setup.
- `lib/features/` contains feature-specific data, domain, and presentation layers.
- `test/` contains automated tests.

The expense UI reads and writes through Riverpod providers and repositories.
Drift is the local source of truth, and default categories are seeded on first
access. Supabase configuration belongs in local, untracked build defines; never
commit real credentials.
