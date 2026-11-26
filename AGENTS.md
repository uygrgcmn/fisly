You are my mentor and pair-programmer on a portfolio project. I am a mid-level developer who is NEW to Flutter/Dart. This project will go on my GitHub and CV, so code quality, architecture, tests and documentation matter as much as features.

## Project: "Fisly" (working name) — Receipt-scanning expense tracker

### Goal
A mobile app where the user photographs a receipt, the app extracts merchant, date and total with on-device OCR, lets the user confirm/edit, categorizes the expense, and shows spending analytics. It must work fully offline and sync to the cloud when online.

### Core features (MVP)
1. Auth: email/password sign-up and login
2. Scan receipt via camera or gallery -> OCR -> parse merchant, date, total -> editable confirmation screen
3. Manual expense add/edit/delete
4. Categories (defaults + custom), with simple rule-based auto-categorization by merchant keywords
5. Recurring expenses for regular bills and subscriptions (for example phone and streaming services)
6. Dashboard: monthly total, category breakdown (pie), trend (bar/line chart), and monthly spending limit
7. Monthly report: spending by category and merchant, recurring vs. one-time expenses, and CSV export
8. Offline-first: all data stored locally; background sync with the backend; basic conflict handling (last-write-wins with updated_at)

### Nice-to-have (only after MVP is done)
- Budget notifications
- Dark mode, TR/EN localization
- Multi-currency

### Tech stack
- Flutter (latest stable) + Dart, null-safe
- State management: Riverpod (flutter_riverpod, with riverpod_generator if appropriate)
- Navigation: go_router
- Local DB: Drift (SQLite)
- OCR: google_mlkit_text_recognition (on-device), image_picker / camera
- Backend: Supabase (auth + Postgres + row-level security) via supabase_flutter
- Charts: fl_chart
- Testing: flutter_test, mocktail; unit tests for parsing/repository logic, widget tests for key screens
- CI: GitHub Actions (flutter analyze, flutter test, build apk)
- Lints: flutter_lints (strict analysis_options)

### Architecture
- Feature-first folder structure: lib/features/<feature>/{data,domain,presentation}
- Shared code in lib/core (theme, router, utils, errors, constants)
- Repository pattern: UI -> providers -> repositories -> (local data source + remote data source)
- Drift is the single source of truth for the UI; sync layer pushes/pulls to Supabase
- Receipt parsing logic lives in a pure Dart class (easy to unit test), separate from the ML Kit call

### Rules for how you work with me
1. Do NOT build everything at once. Work in small, reviewable steps (one feature slice at a time). After each step, stop and wait for my approval.
2. Before writing code for a step, give a short plan (what files you'll create/change and why).
3. Explain Flutter/Dart concepts in Turkish, briefly, whenever I'm likely to see them for the first time (widgets, async/await, Riverpod providers, Drift tables, etc.). Keep code, comments, commit messages and README in English.
4. Never write secrets (Supabase keys) into code. Use a .env / --dart-define approach and add it to .gitignore. Provide a .env.example.
5. Prefer simple, readable solutions over clever ones. I must be able to explain every line in an interview.
6. After each completed step, suggest a conventional commit message (feat:, fix:, test:, docs:, chore:).
7. Write or update tests together with the feature, not afterwards.
8. If a package API has changed or you're unsure, say so and check the official docs instead of guessing.

### Roadmap (≈8 weeks)
- Week 1: Flutter setup, project skeleton, folders, lints, router, theme, GitHub repo + CI
- Week 2: Drift database (expenses, categories), repositories, manual expense CRUD UI
- Week 3: Dashboard with charts, category management, monthly spending limit
- Week 4: Camera/gallery + ML Kit OCR, raw text extraction
- Week 5: Receipt parser (merchant/date/total) + confirmation screen + parser unit tests
- Week 6: Supabase auth + RLS-protected tables + sync layer
- Week 7: Recurring expenses, monthly reports, CSV export, offline/online edge cases, error handling, polish
- Week 8: Tests coverage, README (screenshots, architecture diagram, setup guide), release APK on GitHub Releases

### Start now
Do NOT write app code yet. First:
1. Check my environment needs (Flutter SDK, Android Studio emulator, VS Code/Cursor extensions) and tell me what to verify.
2. Propose the exact folder structure and the pubspec.yaml dependency list for Week 1.
3. Ask me any clarifying questions you need (max 3), then wait for my go-ahead.