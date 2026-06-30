# BT Business — Project Rules

**Permanent source of truth for product and UX decisions.**

Every future feature, screen, label, and workflow must follow these rules. When in doubt, choose the option that feels like **writing in a paper notebook** — not using accounting software.

---

## What this app is

**BT Business is a Digital Register** for India's smallest shopkeepers — not a Tally clone, not an accounting package, not an ERP.

It replaces the shopkeeper's **paper notebook** (register / bahi-khata). The user has **zero accounting knowledge**. The app must be **easier than Tally**.

### Target user

Shopkeepers who write everything in a notebook today:

- Pan shop, tea stall, kirana, hardware, mobile shop, dairy, bakery, small wholesaler, and similar micro-businesses.

---

## Golden rule

> If a feature feels like **Tally or accounting software**, remove it or hide it from the user.

The app must always feel like **writing in a paper register** — quick, obvious, and forgiving.

---

## Design principles (permanent)

1. **2–3 taps** — every common daily task should finish in 2–3 taps when possible.
2. **5–6 fields max** — every form has at most 5–6 fields. Never ask for unnecessary information.
3. **Instant search** — search everywhere by typing a few letters of a name. No IDs, no item codes, no account numbers.
4. **Reports are read-only** — users never edit data from reports or history screens.
5. **History is complete** — never delete old years automatically. Keep unlimited years unless the user manually deletes an entry.
6. **Performance at scale** — stay fast with 100,000+ transactions. Use pagination, lazy loading, and indexed queries on `date`, `party_id`, `type`, and name search columns.
7. **Simple over powerful** — prefer the register answer over the accountant answer every time.

---

## UI vocabulary

Use register language in all user-facing text. Internal code may use accounting terms (`ledger`, `journal`, `debit`, `credit`, etc.) — **never expose them in the UI**.

| Never say in UI | Say instead |
|-----------------|-------------|
| Ledger | **Hisaab** |
| Customer / Supplier / Grahak | **Party** (one party can be both buyer and seller) |
| Inventory (tab label) | **Items** / **Maal** |
| Sale Invoice / Voucher | **Sale** / **Bikri** |
| Purchase Invoice | **Purchase** / **Kharid** |
| Credit | **Udhaar** |
| Payment received | **Jama** / **Paisa mila** |
| Payment paid | **Paisa diya** |
| Expense | **Kharch** |
| Receivable / Payable | **Lena Hai** / **Dena Hai** |
| Journal, Voucher, Debit, Credit, HSN, GSTIN, Stock Group, Item Code | **Never show in UI** |

---

## Hindi language rules

All screens use **bilingual labels**: English heading first, daily spoken Hindi below (in parentheses or subtitle).

### Use daily spoken Hindi only

Examples of approved phrasing:

- Today's Profit → *Aaj Ka Profit*
- Today's Sales → *Aaj Ki Sale*
- Cash in Hand → *Haath Me Cash*
- Payment Received → *Payment Mili*
- Goods Sold → *Maal Becha*

### Never use official / bookish Hindi

Do **not** use words such as:

`Prapt` · `Bakaya` · `Vikray` · `Shesh Rashi` · `Bhugtan` · `Grahak` · `Vivaran` · `Dey Rashi`

When validating or prompting, use plain spoken phrases (e.g. **Party chuniye**, not *Pehle grahak chuniye*).

---

## Visual and platform rules

- **iPhone-first** design; Android and macOS supported.
- **Material 3** with **Apple-quality** polish — rounded cards, generous spacing, calm typography.
- **Purple** is the primary brand color.
- App name: **BT Business**. Subtitle: *Bharat Traders — Your Smart Business Partner*.
- BT Business logo at top of the home dashboard.
- Use `BilingualLabel` (English + Hindi) for headings across the app.

---

## Navigation (permanent structure)

Five bottom tabs — the shopkeeper's daily workflow:

| Tab | Label | Purpose |
|-----|-------|---------|
| 1 | Dashboard | Today's summary, quick write, history link |
| 2 | Hisaab | All parties and balances in one list |
| 3 | Items | Flat item master (Maal) |
| 4 | Sale | Record sales (Bikri) |
| 5 | Purchase | Record purchases (Kharid) |

**Do not** add a separate Customer or Supplier tab. Parties live inside **Hisaab**.

### Dashboard layout

Six summary cards (register-style, not P&L):

1. Cash in Hand
2. Lena Hai
3. Dena Hai
4. Aaj ki Bikri
5. Aaj ki Kharid
6. Aaj ka Kharch

**Quick Write** row on dashboard: **Jama** · **Paise Diye** · **Kharch** (2–3 taps to record).

**History** (*Poora Record*) is accessible from the dashboard — full register log, filter by date, read-only.

Tapping **Lena Hai** or **Dena Hai** on the dashboard opens Hisaab filtered to collect or pay. Hisaab also offers filter chips: **Sab** · **Lena Hai** · **Dena Hai**.

Voice button on home dashboard (future module) — not a substitute for simple tap flows.

---

## Item rules

### Creation — 2 fields only

When creating an item (including inline from Sale/Purchase):

| Field | Required |
|-------|----------|
| **Item Name** | Yes |
| **Unit** (Piece, Kg, Gram, Litre, Packet, Box, Meter, Dozen, etc.) | Yes |

**Nothing else** in the create flow:

- No category, item code, HSN, GST, opening stock, stock group, purchase price, or sale price on create.

Stock updates **automatically** after every Sale and Purchase entry.

### Items list

Show **name**, **stock**, and **unit** only. Do not show GST, buy rate, or sell rate on the master list.

---

## Party rules

### Creation — up to 3 fields

| Field | Required |
|-------|----------|
| **Name** | Yes |
| **Mobile** | Optional |
| **Previous Balance** (Lena Hai / Dena Hai direction) | Optional |

**Nothing else** in the create flow:

- No GSTIN, credit limit, address, customer/supplier type picker, or active/inactive toggle.

One **Party** can be both buyer and seller. Never split customers and suppliers in the UI.

---

## Entry form rules (max fields)

| Entry type | Fields |
|------------|--------|
| **Jama / Paisa diya** | Party, Amount, Date, Note (optional) |
| **Kharch** | Expense name, Amount, Date, Note (optional) |
| **Sale / Purchase** | Party, Date, payment mode (cash / udhaar), line items (qty + rate), Note (optional) |

### Register style, not invoice style

- Pick or **instant-create** Party and Item inline from entry screens.
- No separate master-data detours before recording an entry.
- Show a simple **total** — not tax breakups, not invoice numbers, not print preview.
- Payment mode: cash vs udhaar (spoken labels, not "credit").

---

## Automatic (hidden from user)

These update automatically when entries are saved — the shopkeeper never "posts" or "balances" manually:

- Stock quantities
- Hisaab (party balances)
- Dashboard totals
- Transaction history

---

## Explicitly out of scope (never add to user-facing product)

Unless product rules are deliberately revised in this file:

- Invoice printing, PDF bills, e-way bills
- GST breakup screens, HSN/SAC fields, tax invoices
- Journal entries, vouchers, debit/credit UI
- Chart of accounts, stock groups, item codes
- Tally-style masters, ledgers, or report builders
- Editing data from history or report screens
- Forced categorization, tags, or metadata the shopkeeper would not write in a notebook

Business profile may collect GSTIN optionally for future use — **never** surface GSTIN in daily register flows.

---

## History and reports

- **History** = the full paper register — all entry types, filterable by date period.
- Display and filter only — **no inline edit** on history rows.
- Keep complete records across years; paginate for performance.
- Use register words for entry types (Sale, Purchase, Jama, Paisa diya, Kharch, etc.).

---

## When building new features

Before shipping, verify:

1. Can a shopkeeper finish this in **2–3 taps**?
2. Does the form have **≤ 6 fields**?
3. Does every label use **register vocabulary** (not accounting terms)?
4. Is Hindi **daily spoken**, not official?
5. Does it feel like **writing a line in a notebook**?
6. Are lists **paginated** and searches **indexed**?
7. If it feels like Tally — **remove or simplify**.

---

## Internal implementation note

The codebase may retain double-entry posting, GST calculation, and SQLite accounting tables **internally** for correctness and future extensibility. That logic stays **invisible** to the shopkeeper. UI and copy must always follow this document.

---

## Document authority

- **`PROJECT_RULES.md`** (this file) is the permanent product source of truth.
- `.cursor/rules/digital-register.mdc` mirrors these rules for AI-assisted development in Cursor.
- If this file and the codebase disagree, **update the codebase to match this file** — not the other way around.

*Last updated: June 2026 — Digital Register product pivot.*
