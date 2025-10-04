# PaisaSplit — UI Specification (v1.1 — Consolidated Final)
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

# PaisaSplit — Single Source of Truth UI Spec (Final v1.1)

This document is the **master specification** for the PaisaSplit **mobile** application UI. It resolves all prior ambiguities and is designed so that any engineer or AI model can recreate the **exact mobile UI** without invention. Dark mode is the primary experience.

---

## 1. Global Design System

### 1.1 Color Tokens (resolved)

> Final palette chosen for a **classy, sleek, elegant** dark UI. Teal as brand primary, Gold as accent; Amber reserved for warnings only. All colors are WCAG-accessible against dark surfaces.

**Surfaces**

- `bg/root` **#0B1220** (app background)
- `bg/surface` **#0F172A** (cards/panels)
- `border/divider` **#1F2A3A**

**Typography**

- `text/primary` **#E6EDF6**
- `text/secondary` **#A8B3C7**
- `text/disabled` **#6B7280**

**Brand & Accent**

- `brand/primary` **#2BB39A** (Teal) — primary actions, active controls
- `brand/onPrimary` **#06231E**
- `accent/gold` **#C89B3C** — highlights, selected nav/tab, KPI accents
- `accent/onGold` **#251A05**

**States**

- `state/success` **#22C55E**
- `state/error` **#EF4444**
- `state/warn` **#F59E0B** *(Amber, warnings only)*
- `state/info` **#38BDF8**

**Navigation**

- Bottom nav background: **#0F172A**
- Bottom nav **active**: **#C89B3C** (icon + label)
- Bottom nav **inactive**: **#94A3B8**

> Deprecated/removed: prior uses of `#FFD600` and ambiguous amber highlights for active tabs.

### 1.2 Material 3 Role Mapping (Dark)

- `primary` #2BB39A; `onPrimary` #06231E; `primaryContainer` #0E3B33; `onPrimaryContainer` #BDEFE6
- `secondary` #334155; `onSecondary` #E6EDF6
- `tertiary` #C89B3C; `onTertiary` #251A05; `tertiaryContainer` #3C2D12; `onTertiaryContainer` #F2E3BF
- `error` #EF4444; `onError` #1F0A0A
- `background` #0B1220; `onBackground` #E6EDF6; `surface` #0F172A; `onSurface` #E6EDF6
- `outline` #1F2A3A; `shadow` rgba(0,0,0,0.5)

### 1.3 Typography

- Family: Inter or Roboto (sans)
- Sizes: Titles/AppBar 20–24sp; Section 16–18sp; Body 14–16sp; Secondary 12–13sp; Totals 28–32sp
- Tabular numerals for currency; bold/semibold for key numbers

### 1.4 Components

- **Cards**: radius 16–20dp; surface; 1px border `#223049`; subtle shadow
- **Buttons**: Primary filled (teal → white text); Secondary (outline teal); Danger (red)
- **Toggles/Switch**: Active teal; inactive grey
- **Inputs**: Filled dark; 8–12dp radius; focus ring teal
- **Chips**: ChoiceChip for split-method; Filter chips in Analytics
- **FAB**: Circular 56dp, teal; bottom-right
- **Bottom Navigation**: 5 tabs; active gold; labels always visible
- **Avatars**: Circular; emoji or initial; 32–40dp

### 1.5 Localization & Formatting (Global)

- Currency: **INR**, symbol **₹** prefix, **lakh/crore grouping** (e.g., 1,23,456)
- Negative amounts: minus sign **and** red tint
- Date format: **DD MMM YYYY** (e.g., 07 Sep 2025); Week starts **Monday**
- Number decimals: show 2 decimals; compact numerals for large totals (e.g., ₹1.2L)

### 1.6 Global UX Policies

- **Loading**: skeletons for lists/cards; avoid full-screen spinners
- **Errors**: inline message near action + non-blocking toast; persistent banner for global failures
- **Empty states**: icon/illustration + 1-line explanation + primary CTA
- **Confirmations**: destructive actions require confirm dialog; success → toast/snackbar

---

## 2. Navigation Graph (authoritative)

```
Dashboard ─┬─ Recent Activity → Activity Detail
           ├─ Settle Up → (Basic) Manual Settlement, History
           └─ + FAB → New Expense (Split / Individual)

Groups ──── Group Detail (Tabs: Expenses / Members / Balances)
               ├─ Balances → Basic transfers (no optimization in MVP)
               ├─ Members → Add Member (New / Existing)
               └─ Menu → Group Settings → {Group Info, Actions, Danger Zone}

Analytics ─→ Analytics Dashboard (finalized below)
Accounts ─→ Accounts List, Account Detail (single default account in MVP)
Settings ─→ App Settings (includes App Lock in MVP)
```

> **Feature flags (MVP):** Optimized Settlements **hidden**; UPI Deeplink **hidden**.

---

## 3. Screen Specifications

### 3.1 Dashboard

- Header: “Dashboard”, profile circle (right)
- **Your Balance** cards: *You Owe*, *You Get*, *Net* (gold accents)
- **Settle Up** strip: top counterparties; CTA → Settle Up
- **Recent Activity**: expense/settlement feed
- Search (placeholder) retained; FAB → New Expense

### 3.2 Settle Up (Basic)

- Header: back, “Settle Up”
- Counterparty list with avatar, context text (“You pay X”/“X pays you”), trailing amount
- Row → **Record Manual Settlement** (enter amount, date, note) → confirm dialog
- **History** section with empty state copy
- **No** optimized-settlements toggle in MVP; **No** UPI handoff

### 3.3 Group Detail

**Tabs**

- **Expenses**: list; summary chips (Total Spent, Members); row → detail view
- **Members**: list; **+ Add Member** (Existing/New)
- **Balances**: tiles for *To Receive*/*To Pay*; list of members with owe/owed amounts; CTA → Settle Up

**Overflow**: Group Settings; Export (P1)

### 3.4 Group Settings

- Group info (name, createdAt, edit)
- Members list with kebab
- Actions: Settle Up, Export Data (P1)
- Danger Zone: Delete Group (confirm)

### 3.5 Add Member

- Tabs: Existing / New
- New Member: Name\*, UPI ID (optional), Avatar picker, **Save**
- Existing: Search + list

### 3.6 New Expense

- Selector cards: **Split** / **Individual** (teal selection)
- Common fields: Group (for Split), Description, Amount (₹), Category, Payment Account\*, Paid By (chips), Date, Notes
- **Split methods** (MVP): **Equally** and **Exact**
  - **Equally**: shows per-person calc; includes you if you’re in group ("Me" is always a member)
  - **Exact**: per-member amounts; validation to match total
- Footer sticky bar: **Save Split** / **Save Individual**

### 3.7 Analytics (Finalized for MVP)

**Header**: “Analytics” with period switcher: **This Month | Last Month | Last 30 Days | Custom**

**Mode segmented**: **Consumption (My Share)** | **Out‑of‑Pocket**

**KPIs Row** (cards, gold highlights)

- Total (selected mode)
- Daily Avg
- \#Expenses
- \#Active Groups

**Charts**

- **Category Breakdown** donut (selected mode): legend with top 6 categories + Other; tap slice → filtered list
- **Trend** bar chart (Daily for current month / Weekly for 30-day): shows selected mode over time

**Lists**

- **Top Groups** (by selected mode)
- **Top Categories** (tap drills into transactions)

**Empty State**: “No data for this period yet. Add an expense to get insights.”

### 3.8 Accounts (MVP)

- Single default account card: name, current balance
- Recent account transactions list (read-only)

### 3.9 Settings (MVP)

- Currency (INR fixed)
- Theme (System/Dark)
- **App Lock**: toggle → setup flow (Biometric/PIN) → lock screen preview
- About/Privacy placeholders

### 3.10 App Lock UI

- **Lock screen**: logo, “Unlock PaisaSplit”, biometric prompt or PIN keypad
- **Policies**: lock on cold start and after **30s** background (configurable later)
- Failure: show inline error; fallback to device credential

---

## 4. States, Validation & Interactions

- **Validation**: amount>0; exact-split totals must equal amount; %/shares (P1) hidden
- **Animations**: subtle fade/slide for tab changes; chip selection ripple
- **Toasts**: success after save/settle; undo for deletion (where applicable)
- **Error copies**: concise, action-first (e.g., “Couldn’t save. Retry.”)

---

## 5. Accessibility

- Tap targets ≥ **44dp** (prefer 48dp)
- Contrast AA+; larger weights on small text; scalable fonts
- Screen reader labels on icons; focus order mirrors visual order

---

## 6. Component-to-Flutter Mapping

- `Scaffold`, `AppBar`, `BottomNavigationBar`, `FloatingActionButton`
- `Card`, `ListView`, `Switch`, `DropdownMenu` / modal sheets
- `TextFormField`, `ChoiceChip`, `FilterChip`, `AlertDialog`
- Custom: DonutChart, BarChart (Analytics)

---

## 7. Feature Flags (wired but **hidden** in MVP)

- `features.optimizedSettlements` (P1)
- `features.upiDeeplink` (P1)
- `features.percentageSplit` (P1)
- `features.sharesSplit` (P1)

---

## 8. Final Notes

- All screenshots and prior batches are subsumed by this spec.
- Theming is tokenized; avoid hard-coded colors in widgets. Use `Theme.of(context)` + tokens.
- This spec is the **authoritative UI** for the MVP build.



---
## v1.1 Canonical Rules (Normative, Implement First)
# PaisaSplit — UI Spec Addendum (v1.1)
**Effective:** 2025-10-04 18:41:29 IST  
**Supersedes/extends:** `paisa_split_ui_spec_final_v_1.md` (v1.0)

This addendum is a **strict delta** over v1.0. It introduces **no new features**; it only locks previously “either/or” choices and clarifies formatting/period rules to remove ambiguity during implementation.

---

## 0) Versioning
- Document version: **v1.1 (UI)**
- Scope: Clarifications only. Use this addendum together with v1.0; where conflicts exist, **v1.1 takes precedence**.

---

## 1) Theme & Number Formatting (INR)
- **Locale:** Force `en_IN` everywhere the app renders numbers, currency, or chart labels.
- **Currency:** Always display INR with lakh/crore grouping and `₹` prefix via a centralized **CurrencyFormatter**.
- **Negatives:** Show negative values with a leading minus and apply the UI token for **negative/red hint** (do not invent new colors).

**Rationale:** Eliminates inconsistent grouping (e.g., 100,000 vs 1,00,000) seen in some widgets during prototyping.

---

## 2) Analytics — Week and Period Bucketing
- **Week start:** **Monday** (ISO-8601). All weekly aggregations (e.g., “Last 30 Days” weekly buckets) are aligned **Mon–Sun**.
- **Last 30 Days:** Trend chart aggregates by **week (Mon–Sun)** and donut sums must equal the KPI **Total**.
- **Custom range:** Keep the UI as in v1.0; behavior is unchanged.

**Rationale:** Aligns with PRD math and prevents off-by-one week splits.

---

## 3) Charts Library (lock)
- Use **`fl_chart`** for donut and trend charts. Do **not** substitute or mix libraries.
- Donut: top 6 categories + **Other** segment. Trend: **daily** for month views, **weekly** for Last-30-days.

**Rationale:** Avoids library churn and styling drift.

---

## 4) Navigation & FAB (no functional change)
- Keep the 5-tab bottom nav and FAB behavior from v1.0.
- This addendum only reiterates: **FAB opens New Expense selector**; active tab accent = **gold**, inactive = **gray**.

---

## 5) App Lock UI (reference only)
- No visual change, but ensure lock screen texts **do not mention** storage specifics (PIN hashing/biometric) — see PRD v1.1 for implementation details.

---

## 6) Tokens (no new tokens)
- Reuse existing tokens. Any new “success/negative” accents must map to **existing** palette entries defined in v1.0.
- Do **not** add hard-coded hex values in widgets.

---

## Appendix — One-liners for reviewers
- Locale: `en_IN` everywhere.
- Week start: Monday.
- Charts: fl_chart only.
- Donut sums = KPI Total; trend aggregates align to period.
