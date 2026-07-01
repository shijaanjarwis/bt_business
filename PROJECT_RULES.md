# BT Business — Project Rules

**Permanent source of truth for product and UX decisions.**

Every future feature, screen, label, and workflow must follow these rules. When in doubt, choose the option that feels like **writing in a paper notebook** — not using accounting software.

These rules apply to the **entire project** and must always be followed unless explicitly approved otherwise.

---

# BT Business – Permanent UX & Branding Rules

## 1. Simplicity First

BT Business is made for shopkeepers, wholesalers and daily business users.

Every screen must stay simple.

If a feature makes the UI complicated, redesign the feature — not the user flow.

**Target:**

- Maximum 2–3 taps for common work
- Minimum typing
- No unnecessary dialogs
- No confusing workflows
- No hidden important actions

## 2. Hindi First

All user-visible text must use simple daily Hindi.

**Examples:**

Party chuniye · Maal chuniye · Kitna mila · Kitna baaki · Jama diya · Paisa mila · Kharcha · Bikri · Kharid · Poora hisaab · Save karein · Edit karein · Delete karein

**Never expose technical words** like: Invoice · Posting · Migration · Database · Repository · Engine · Service · Audit · Linked rows · Transaction · Recalculate · Sync

These are implementation details and must never be visible to users.

Use bilingual labels where helpful (English + Hindi), but Hindi must always be simple, spoken, and primary for prompts and actions.

## 3. Voice First Workflow

The app should always assume users may speak instead of type.

Voice input should work wherever practical.

Typing must remain optional.

Every new feature should consider voice usage first.

## 4. Auto-Creation Philosophy

During Sale and Purchase entry:

If the user types or speaks an item that does not exist:

- Automatically create the item
- Continue the entry
- Never interrupt with unnecessary warnings
- Never force the user to create the item manually

The user should never feel blocked while entering business data.

## 5. Everything Must Be Editable

Users should always be able to edit:

- Sale
- Purchase
- Payment received
- Payment given
- Expense
- Party
- Item

History is never read-only.

The app should always help users correct mistakes.

## 6. Dashboard Philosophy

Dashboard only displays calculated information.

Nothing should ever be manually edited from Dashboard.

After every change, Dashboard must refresh automatically.

## 7. Consistent Design

Every page should follow the same:

- spacing
- typography
- colors
- buttons
- cards
- icons

No screen should look visually different from the rest.

## 8. Branding Rules

Always use Bharat Traders branding.

**Requirements:**

- Splash Screen must display the Bharat Traders logo
- App title should show **BT Business** with the Bharat Traders logo beside it
- Do not stretch or distort the logo
- Maintain proper spacing around the logo
- Branding must remain clean and professional

**Implementation:**

- Logo asset: `assets/images/bharat_traders_logo.png`
- Header widget: `BtBusinessLogo` (40×40, `BoxFit.contain`)
- Splash: `SplashPage` (~2s, fade + slight zoom, then onboarding or dashboard)

## 9. Developer Credit

Every vertically scrollable page must end with a small footer:

```
Developed by
Mohd Anas Mansoori
```

**Footer rules:** small · elegant · low emphasis · professional · consistent on every screen

Use `DeveloperFooter` from `lib/shared/widgets/branding/developer_footer.dart`.

## 10. Performance First

Never sacrifice speed for animations.

Fast response is more important than fancy effects.

Avoid unnecessary rebuilds, delays or heavy animations.

## 11. Future Development Rule

Before implementing any new feature, always ask:

- Can this be simpler?
- Can this reduce taps?
- Can this reduce typing?
- Can this work with voice?

If the answer is yes, implement the simpler solution.

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
4. **Everything editable** — users can edit Sale, Purchase, Jama, Paisa diya, Kharch, Party, and Item entries. Help users fix mistakes; history is not read-only.
5. **History is complete** — never delete old years automatically. Keep unlimited years unless the user manually deletes an entry.
6. **Performance at scale** — stay fast with 100,000+ transactions. Use pagination, lazy loading, and indexed queries on `date`, `party_id`, `type`, and name search columns.
7. **Simple over powerful** — prefer the register answer over the accountant answer every time.
8. **Performance first** — never sacrifice speed for animations; avoid unnecessary rebuilds and heavy effects.

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

**Hindi first** — all user-visible text uses simple daily spoken Hindi (see Section 2 above).

Use bilingual labels where helpful: English heading with daily Hindi subtitle via `BilingualLabel`.

### Approved phrasing examples

Party chuniye · Maal chuniye · Kitna mila · Kitna baaki · Paisa mila · Kharcha · Bikri · Kharid · Poora hisaab · Save karein · Edit karein · Delete karein

### Never use official / bookish Hindi

Do **not** use words such as:

`Prapt` · `Bakaya` · `Vikray` · `Shesh Rashi` · `Bhugtan` · `Grahak` · `Vivaran` · `Dey Rashi`

### Never expose technical terms in UI

Invoice · Posting · Migration · Database · Repository · Engine · Service · Audit · Linked rows · Transaction · Recalculate · Sync

---

## Visual and platform rules

- **iPhone-first** design; Android and macOS supported.
- **Material 3** with **Apple-quality** polish — rounded cards, generous spacing, calm typography.
- **Purple** is the primary brand color.
- **Consistent design** — same spacing, typography, colors, buttons, cards, and icons on every screen.
- App name: **BT Business**. Subtitle: *Bharat Traders — Your Smart Business Partner*.
- Official app logo: **Bharat Traders** (`assets/images/bharat_traders_logo.png`) — beside BT Business title on the home dashboard header. Small, clean, never stretched (40×40, `BoxFit.contain`).
- Developer footer on every vertically scrollable page — see Section 9 above. Use `DeveloperFooter`.
- **Splash screen** (`SplashPage`): Bharat Traders logo, fade + slight zoom, ~2s, then onboarding or dashboard.
- Use `BilingualLabel` for headings where bilingual copy is needed.

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

**History** (*Poora Record*) is accessible from the dashboard — full register log, filter by date. Users can open and edit entries from history.

Tapping **Lena Hai** or **Dena Hai** on the dashboard opens Hisaab filtered to collect or pay. Hisaab also offers filter chips: **Sab** · **Lena Hai** · **Dena Hai**.

Voice button on home dashboard — voice-first workflow; typing remains optional everywhere practical.

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

During Sale/Purchase, if an item name does not exist, **auto-create** it inline and continue — no blocking dialogs.

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
- Dashboard totals (calculated from transactions — never stored; auto-refresh after every change)
- Transaction history

---

## Explicitly out of scope (never add to user-facing product)

Unless product rules are deliberately revised in this file:

- Invoice printing, PDF bills, e-way bills
- GST breakup screens, HSN/SAC fields, tax invoices
- Journal entries, vouchers, debit/credit UI
- Chart of accounts, stock groups, item codes
- Tally-style masters, ledgers, or report builders
- Forced categorization, tags, or metadata the shopkeeper would not write in a notebook

Business profile may collect GSTIN optionally for future use — **never** surface GSTIN in daily register flows.

---

## History and reports

- **History** = the full paper register — all entry types, filterable by date period.
- Users can open entries from history and edit them — history is never read-only.
- Keep complete records across years; paginate for performance.
- Use register words for entry types (Sale, Purchase, Jama, Paisa diya, Kharch, etc.).

---

## Dashboard

- Dashboard displays **calculated** metrics only — never manually editable.
- Totals are computed from transactions on every read; never stored as dashboard totals.
- Dashboard must auto-refresh after every Sale, Purchase, payment, expense, edit, or delete.

---

## When building new features

Before shipping, verify (see also Section 11 above):

1. Can a shopkeeper finish this in **2–3 taps**?
2. Does the form have **≤ 6 fields**?
3. Does every label use **register vocabulary** and **simple Hindi** (not accounting or technical terms)?
4. Can this work with **voice**? Is typing optional?
5. Can missing items/parties be **auto-created** without blocking the user?
6. Can the user **edit** this entry later?
7. Does it feel like **writing a line in a notebook**?
8. Are lists **paginated** and searches **indexed**?
9. Is it **fast** — no unnecessary animations or rebuilds?
10. Does branding stay **consistent** (logo, footer, spacing)?
11. If it feels like Tally — **remove or simplify**.

---

## Internal implementation note

The codebase may retain double-entry posting, GST calculation, and SQLite accounting tables **internally** for correctness and future extensibility. That logic stays **invisible** to the shopkeeper. UI and copy must always follow this document.

---

## Document authority

- **`PROJECT_RULES.md`** (this file) is the permanent product source of truth.
- `.cursor/rules/digital-register.mdc` mirrors these rules for AI-assisted development in Cursor.
- If this file and the codebase disagree, **update the codebase to match this file** — not the other way around.

*Last updated: June 2026 — Permanent UX, branding and development guidelines.*
