# PaisaSplit — Product Requirements (PRD) (v1.1 — Consolidated Final)
**Generated:** 2025-10-04 18:42:56 IST  
**Supersedes:** v1.0  
**Status:** Canonical — this file is self-contained. Where the original v1.0 text conflicted with later decisions, the **v1.1 canonical rules below apply**.

---
## Changelog from v1.0 → v1.1 (Summary)
This version locks previously ambiguous choices and clarifies formatting/aggregation rules to prevent implementation drift. No scope changes to MVP.

- Locale & formatting: enforce `en_IN` for currency/number and charts; INR with lakh/crore grouping, `₹` prefix, red negatives via existing tokens.
- Analytics: **week starts Monday (ISO-8601)**; “Last 30 Days” trend uses **Mon–Sun** weekly buckets; donut sum equals KPI Total.
- Charts: library locked to **fl_chart**; donut top 6 + Other; trend = daily (month) or weekly (Last 30 Days).
- Database: Drift uses **sqlite3_flutter_libs** (native); do not include `drift_sqflite`.
- Security: App Lock PIN stored as **salted SHA-256** using `crypto`; biometric via `local_auth`; lock on cold start and after **30s** background.
- Dependencies: add `sqlite3_flutter_libs` and `crypto` to the pinned set.
- Tests/CI: add formatter, analytics aggregation, and app-lock behavior tests; `dart analyze` warnings are errors.

---
## Canonical Specification (v1.1)
The content below is the v1.0 specification, preserved verbatim for completeness. **If any paragraph conflicts with the rules above, the v1.1 rules prevail.**

# PaisaSplit — Full Application Details & PRD (Final v1.1)

> Definitive reference for engineering, design, and QA. Flutter-first, with pinned versions, seed data, tests, and conventions. This supersedes prior drafts.

---

## 0) Executive Summary
**PaisaSplit** lets users capture personal & split expenses, compute transparent balances in groups, and settle debts manually (MVP), with insights in Analytics and a simple Accounts ledger. Dark mode, teal brand, gold accents. MVP **excludes** UPI deeplink and optimized settlements (both P1). **App Lock is included in MVP.**

---

## 1) Goals / Non‑Goals
### 1.1 MVP Goals
- P0 accurate expense capture (Individual + Split: Equal, Exact)
- P0 balances per member + basic Settle Up (manual record + history)
- P0 Accounts ledger with single default account
- P0 Analytics (Consumption & Out‑of‑Pocket modes; donut + trend)
- P0 App Lock (biometric/PIN)

### 1.2 Non‑Goals (MVP)
- UPI deeplink handoff (now **P1**)
- Optimized settlements / settle-all suggestions (P1)
- Multi-accounts & transfers (P1), cloud sync (later), exports (P1)

---

## 2) Personas & IA (unchanged)
- Organizer, Participant. Bottom tabs: Dashboard | Groups | Analytics | Accounts | Settings. Global FAB → New Expense.

---

## 3) Tech Stack (Locked)
- **Flutter 3.24.x**, **Dart 3.x**
- **Architecture**: Feature-first folders; Riverpod for state; Repository pattern; Drift (SQLite) for data
- **Packages (pinned)**
  - `flutter_riverpod: ^2.5.1`
  - `go_router: ^14.2.1`
  - `drift: ^2.20.2`
  - `drift_sqflite: ^2.0.1` *(or `sqlite3_flutter_libs: ^0.5.24` on native)*
  - `intl: ^0.19.0`
  - `uuid: ^4.5.1`
  - `collection: ^1.18.0`
  - `equatable: ^2.0.5`
  - `local_auth: ^2.3.0` *(App Lock)*
  - `shared_preferences: ^2.3.2`
  - Charts: `fl_chart: ^0.69.0` (or in-house widgets)

> Include `pubspec.yaml` with these pins in the repo root.

### 3.1 Lints & Analyzer
- `analysis_options.yaml`: enable `flutter_lints`, treat warnings as errors; ban `print`, prefer `logger` later

### 3.2 Project Layout (authoritative)
```
lib/
  app/            # app.dart, theme, routes
  core/           # utils, formatters, result types
  data/           # drift database, daos, repositories
  features/
    dashboard/
    groups/
    expenses/
    settle/
    analytics/
    accounts/
    settings/
  widgets/        # shared UI components (cards, chips, charts)
  gen/            # drift generated (build_runner)
assets/
  icons/
  images/
```

### 3.3 Routing
- `go_router` named routes; deep links tbd later

---

## 4) Visual System (summary)
- Dark: background #0B1220, surface #0F172A, text #E6EDF6
- Brand teal #2BB39A; accent gold #C89B3C; warnings amber #F59E0B
- See UI Spec v1.1 for full tokens

---

## 5) Features & Acceptance Criteria (MVP)
### 5.1 Dashboard
- Snapshot cards (*You Owe*, *You Get*, *Net*); Settle Up list; Recent Activity feed
- **AC**: balances computed correctly; list navigations correct

### 5.2 Groups
- List, create (name*), view detail with tabs
- **AC**: counters reflect expenses; tabs consistent

### 5.3 Members
- Inline add from Group (Existing/New). “Me” is always a member in every group you’re in
- **AC**: members usable in splits; editing member name updates references

### 5.4 Expenses
- **Individual** and **Split** (Equal, Exact)
- Validations: amount>0; exact shares sum to total
- **AC**: saving posts to DB, updates balances and account txn if payer is you

### 5.5 Balances & Settle Up (Basic)
- Show per-counterparty amounts; **Record Manual Settlement** form; History list
- **AC**: marking paid mutates balances and ledger atomically; history accurate

### 5.6 Analytics (MVP)
- Period switcher; modes: **Consumption (My Share)** and **Out‑of‑Pocket**
- KPI row; **Category donut** (selected mode); **Trend** bar (daily/weekly)
- **AC**: totals match data; donut segments sum to total; mode/period filters recalc

### 5.7 Accounts (MVP)
- One default account (auto-created first run); running balance; recent txns
- **AC**: account balance reflects expense payments and settlements

### 5.8 Settings + App Lock (MVP)
- Currency (fixed INR), Theme (System/Dark), **App Lock** toggle
- **App Lock behavior**: lock on cold start and after **30s** in background; biometric first, fallback to device credential or PIN; lock screen per UI spec
- **AC**: background → foreground after 30s shows lock; failures handled; cancel returns to locked state

---

## 6) Data Model (authoritative, paise int)
```
User(id, name)
Member(id, name, upiId?, avatar?, isGlobal)
Group(id, name, description?, createdAt)
GroupMember(id, groupId, memberId, role)
Expense(id, groupId, title, amountPaise, paidByMemberId, date, category, notes?, isDeleted=false)
ExpenseSplit(id, expenseId, memberId, sharePaise)
Account(id, name, openingBalancePaise, type, notes?)
AccountTxn(id, accountId, type: expensePayment|settlementSent|settlementReceived|adjustment,
           amountPaise, relatedGroupId?, relatedMemberId?, relatedExpenseId?,
           relatedSettlementId?, createdAt, note?)
Settlement(id, groupId, fromMemberId, toMemberId, amountPaise, date, note?)
Settings(id, currency, theme, prefsJson, appLockEnabled: bool, appLockMethod: biometric|pin)
```
**Indexes**: Expense (groupId,date); AccountTxn (accountId,date); Splits (expenseId,memberId); Settlement (groupId,date)

---

## 7) Algorithms (MVP)
### 7.1 Balances
For expense A with payer P and splits sᵢ (Σ sᵢ = A): `net[i] -= sᵢ` for i≠P; `net[P] += (A - s_P)`

Settlement X→Y amount M: `net[X] -= M; net[Y] += M`

### 7.2 Rounding
Values stored in paise; when deriving from % (P1), distribute residue to first N participants deterministically

---

## 8) Ledger Rules & Edits (deterministic)
- **Never** mutate existing `AccountTxn` rows in place for posted items
- **Edit Expense**: compute delta vs previous posting; create **adjustment** txn rows to offset/reflect changes; update expense/splits
- **Delete Expense**: soft-delete `Expense.isDeleted=true`; create reversing adjustments to neutralize previous postings
- **Edit Payer**: reverse old payer posting, post to new payer account
- **Settlement edits**: disallow edits; delete + recreate (history records both)

---

## 9) Localization & Formatting (INR)
- ₹ prefix, lakh/crore grouping (e.g., ₹1,23,456.00)
- Negative numbers: a leading minus and red tint in UI
- Date format DD MMM YYYY; week starts Monday

---

## 10) Database Schema & Migrations
- Drift table definitions mirroring §6; foreign keys with `ON UPDATE CASCADE`, `ON DELETE RESTRICT` (except soft-deletes)
- **Migration 1→2 template** included (bump Settings fields etc.)

---

## 11) Seed Data (sample)
`assets/seed/seed.json`
```json
{
  "members": [
    {"id":"me","name":"Me"},
    {"id":"m_anu","name":"Anu"},
    {"id":"m_rahul","name":"Rahul"}
  ],
  "groups": [
    {"id":"g_trip","name":"Goa Trip","createdAt":"2025-08-10"}
  ],
  "groupMembers": [
    {"id":"gm1","groupId":"g_trip","memberId":"me"},
    {"id":"gm2","groupId":"g_trip","memberId":"m_anu"},
    {"id":"gm3","groupId":"g_trip","memberId":"m_rahul"}
  ],
  "accounts": [
    {"id":"acc_default","name":"Default Account","openingBalancePaise":0}
  ],
  "expenses": [
    {"id":"e1","groupId":"g_trip","title":"Hotel","amountPaise":450000,"paidByMemberId":"me","date":"2025-08-11","category":"Lodging"},
    {"id":"e2","groupId":"g_trip","title":"Dinner","amountPaise":120000,"paidByMemberId":"m_anu","date":"2025-08-11","category":"Food"}
  ],
  "splits": [
    {"id":"s1","expenseId":"e1","memberId":"me","sharePaise":150000},
    {"id":"s2","expenseId":"e1","memberId":"m_anu","sharePaise":150000},
    {"id":"s3","expenseId":"e1","memberId":"m_rahul","sharePaise":150000},
    {"id":"s4","expenseId":"e2","memberId":"me","sharePaise":40000},
    {"id":"s5","expenseId":"e2","memberId":"m_anu","sharePaise":40000},
    {"id":"s6","expenseId":"e2","memberId":"m_rahul","sharePaise":40000}
  ]
}
```

---

## 12) Worked Example (balances & settlement)
- Group members: Me, Anu, Rahul
- e1: Hotel ₹4,500 (me paid), split equally → each ₹1,500
  - net: Me +₹3,000 (paid 4,500 – own 1,500); Anu −₹1,500; Rahul −₹1,500
- e2: Dinner ₹1,200 (Anu paid), split equally → each ₹400
  - net: Me +₹2,600; Anu −₹1,100 (paid 1,200 – own 400 = +800; but owes 1,500 overall → −1,100 net); Rahul −₹1,500 − 400 = −₹1,900
- Manual settlement: Rahul pays Me ₹1,500 → net: Me +₹1,100; Rahul −₹400; Anu −₹1,100

> Golden tests assert these nets and ledger postings.

---

## 13) Tests (executable plan)
**Golden/Unit**
1. Equal split math with 3 members (worked example) → nets as above
2. Exact split validation must match total → error state
3. Editing payer posts reversing adjustments and new postings
4. Deleting expense soft-deletes + reversing adjustments
5. Analytics donut sum equals KPI total (±0 paise)
6. Trend bar totals equal per-day aggregation
7. Mark manual settlement updates nets and ledger atomically
8. App Lock: background>30s triggers lock; biometric success unlocks; failure loops back

**Instrumentation**
- Add Split Expense flow; Settle flow; App Lock flows

---

## 14) Observability (dev-only, local)
- Simple in-app debug log (to file) for actions: expense_add/edit/delete, settlement_marked_paid

---

## 15) Roadmap & Priorities
**P0 order**
1) App shell & theme, DB layer, Navigation & FAB
2) Accounts (default), Groups & Members (inline)
3) Expenses (Individual, Split Equal/Exact)
4) Balance computation
5) Settle Up (manual) + History
6) Dashboard
7) Analytics (KPIs, donut, trend)
8) Settings + **App Lock**
9) Validations, empty/error states, tests

**P1** (next release)
- Split: Percentage & Shares
- Optimized Settlements + Settle All (feature flag on)
- UPI Deeplink handoff (prefill, post-return confirm)
- Multi-accounts; Reminders; Export; Search; Category mgmt; Backup/Restore; Analytics richer

---

## 16) Glossary
- **Consumption (My Share)**: portion attributed to you
- **Out‑of‑Pocket**: you actually paid
- **Ledger**: chronological postings with running balance

---

## 17) Appendix — pubspec.yaml (excerpt)
```yaml
name: paisasplit
environment:
  sdk: ">=3.5.0 <4.0.0"
dependencies:
  flutter: { sdk: flutter }
  flutter_riverpod: 2.5.1
  go_router: 14.2.1
  drift: 2.20.2
  drift_sqflite: 2.0.1
  intl: 0.19.0
  uuid: 4.5.1
  collection: 1.18.0
  equatable: 2.0.5
  local_auth: 2.3.0
  shared_preferences: 2.3.2
  fl_chart: 0.69.0

dev_dependencies:
  flutter_test: { sdk: flutter }
  build_runner: ^2.4.10
  drift_dev: ^2.20.1
  flutter_lints: ^4.0.0
```

### analysis_options.yaml (excerpt)
```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    dead_code: warning
linter:
  rules:
    - prefer_const_constructors
    - prefer_final_locals
    - avoid_print
    - always_declare_return_types
```

---

**This PRD is the single source of truth for MVP+.**



---
## v1.1 Canonical Rules (Normative, Implement First)
# PaisaSplit — Product Requirements (PRD) Addendum (v1.1)
**Effective:** 2025-10-04 18:41:29 IST  
**Supersedes/extends:** `paisa_split_full_app_details_prd_final_v_1.md` (v1.0)

This addendum locks specific implementation choices and storage policies to eliminate ambiguity. **No scope change** to MVP.

---

## 0) Versioning
- Document version: **v1.1 (PRD)**
- Use together with v1.0; where conflicts exist, **v1.1 prevails**.

---

## 1) Data & DB — Drift binding (locked)
- **Binding:** Use **`sqlite3_flutter_libs`** (native). Do **not** include `drift_sqflite`.
- **Migrations:** Keep v1.0 plan; template for 1→2 remains, but ensure tests cover opening on existing installs.

**Why:** Native binding is stable on Android and avoids platform surprises.

---

## 2) Security — App Lock PIN storage
- **Biometric first** via `local_auth` (unchanged).
- **PIN fallback:** Store only **salted SHA-256 hash** using `crypto:^3.x`.
  - Generate 16-byte random salt (per device).
  - Stored fields (SharedPreferences):
    - `app_lock.pin.salt` (base64), `app_lock.pin.hash` (base64), `app_lock.enabled` (bool).
  - Verification: `hash = SHA256(salt || userInputPin)` equals stored hash.
- **Policy:** Lock on cold start and after **30s** in background.

**Why:** Prevents plaintext/semi-reversible storage; aligns with security expectations.

---

## 3) Locale & Formatting
- Initialize `Locale('en', 'IN')` at app start and inject into all formatters (currency, compact numerals, chart labels).
- Store monetary values internally in **paise** (int). Display via formatters only.

**Why:** Guarantees consistent grouping and avoids float drift.

---

## 4) Analytics Rules
- **Week start = Monday**; Last-30-days weekly aggregates must follow Mon–Sun buckets.
- **Sum check:** Donut segments (top 6 + Other) **must equal** KPI Total for the selected mode/period.

---

## 5) Dependencies (pinned deltas)
Add to v1.0 pins:
```yaml
dependencies:
  sqlite3_flutter_libs: ^0.5.24  # native sqlite for Drift
  crypto: ^3.0.0                 # salted SHA-256 for PIN

dev_dependencies:
  # unchanged from v1.0; ensure drift_dev and build_runner present
```
(Use exact versions from your lockfile if you already resolved them.)

---

## 6) Tests (additional)
- **Formatter tests:** `₹1,23,456.00` and compact `₹1.2L` for 1,23,456.
- **Analytics aggregation:** Verify Mon–Sun weekly buckets for “Last 30 Days” and donut sums = KPI total.
- **App Lock:** Biometric success path and PIN failure path; background >30s triggers lock.

---

## 7) CI Gates (unchanged with clarifications)
- `dart analyze` must be clean; **warnings fail**.
- Run unit + golden tests; add explicit tests for the above items.

---

## Appendix — Single-source flags (unchanged)
- Feature flags remain **wired but hidden** (optimized settlements, UPI deeplink, %/shares splits). No UI exposure in MVP.
