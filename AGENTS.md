# AGENTS.md — PaisaSplit Repo Rules

## Sources of Truth
- UI Spec v1.1: `paisa_split_ui_spec_final_v_1_1.md`
- PRD v1.1: `paisa_split_full_app_details_prd_final_v_1_1.md`

If anything conflicts, **PRD v1.1** prevails for behavior/data; **UI v1.1** prevails for look/feel. No assumptions. Do not add features or change copy.

---

## Absolutes
- Currency: INR with lakh/crore grouping via `Locale('en','IN')`, `₹` prefix, negatives use existing red token. Store money in **paise (int)**.
- Weeks start **Monday (ISO)**. Analytics “Last 30 Days” aggregates by **Mon–Sun**. Donut segments (top 6 + Other) **sum to KPI Total**.
- Charts: **`fl_chart` only** (donut + trend). No library substitutions.
- Database: Drift with **`sqlite3_flutter_libs`** (no `drift_sqflite`).
- App Lock: `local_auth` first; PIN = **salted SHA-256** using `crypto`; lock on cold start and after **30s** background. Store only salt+hash (Base64) in SharedPreferences.

---

## Coding Conventions
- Flutter 3.24.x, Dart 3.x. Riverpod for state, go_router for routes, Drift for DB.
- analysis_options: warnings are errors; `print` banned.
- Ledger rule: edits/deletes are **adjustments**; never mutate posted AccountTxn.

---

## Tools & Environment (non-negotiable)
- Flutter & Dart must exist at runtime. If missing, install to `$HOME/flutter` and expose via `/usr/local/bin`:
  - `git clone -b stable https://github.com/flutter/flutter.git "$HOME/flutter"`
  - `sudo ln -sf "$HOME/flutter/bin/flutter" /usr/local/bin/flutter`
  - `sudo ln -sf "$HOME/flutter/bin/dart" /usr/local/bin/dart`
- APK builds require Android SDK + JDK. If missing, install to `/opt/android-sdk` and export `ANDROID_SDK_ROOT`.
- Use these exact validation commands (and fail the task if any fails).

---

## Validation Loop (run in this order for **every** task)
1. `dart run build_runner build -d`
2. `dart analyze`
3. `flutter test`

### Local Build Checkpoints (run these too)
- After **Tasks 02, 03, 07, 10, 11**: `flutter build apk --debug`
- Final (Task 12): `flutter build apk --release --split-per-abi`

---

## CI
- `.github/workflows/ci.yml` must build **debug universal** and **per-ABI unsigned release** APKs and upload as artifacts on push/PR and manual dispatch.
- Treat analyzer warnings as errors. Codegen must be up to date (`build_runner`).

---

## Routing & Screens (reference)
- Named routes: `dashboard, groups, groupDetail, analytics, accounts, settings, addMember, newExpense, settleUp, activityDetail, groupSettings`.
- Bottom nav (5 tabs). Active = gold; inactive = gray. FAB opens **New Expense** selector.

---

## Feature Flags (wired, hidden in MVP)
- Optimized settlements, UPI deeplink, percentage/shares splits → keep code paths guarded but **no UI exposure**.

---

## Seed & Tests
- Seed data (Me, Anu, Rahul; Goa Trip; e1/e2) must load on first run (idempotent).
- Tests must cover: INR formatting, analytics aggregation (Mon–Sun), donut sum, balances/settlements worked example, App Lock (cold + 30s background).

---
