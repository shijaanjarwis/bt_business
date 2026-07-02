# BT Business

**A digital register for India's smallest shopkeepers** — Bharat Traders.

BT Business replaces the shopkeeper's **paper notebook** (bahi-khata). It is **not** Tally, **not** an ERP, and **not** an inventory management system.

> **Documentation is frozen.** Product rules, philosophy, and roadmap live in [`PROJECT_RULES.md`](PROJECT_RULES.md). Do not add new docs unless explicitly requested. **Current focus: implementation, testing, polish, and stability.**

## Product philosophy (permanent)

BT Business must **always** remain a **Digital Business Register** — never a full accounting ERP.

1. Every new feature must **save the shopkeeper's time**
2. Every screen understandable by someone who has **never used accounting software**
3. Reject features where **complexity exceeds value**
4. **One-screen completion** over multi-step workflows
5. **Minimum taps** for every action
6. **Hindi-first** by default
7. **No technical words** in user-facing UI unless absolutely necessary
8. **Improve existing workflows** — don't duplicate features
9. **Speed, simplicity, reliability** over feature count
10. Feel like a **digital notebook** — not Tally, ERP, or inventory software

## What it does

- **Bikri / Kharid** — record sales and purchases in register style
- **Hisaab** — party names and balances (Lena Hai / Dena Hai)
- **Jama / Paisa diya / Kharch** — payments and expenses
- **Maal** — item name + unit shortcuts so entry is faster (optional default rates only)
- **Dashboard & History** — today's summary and full register log

## What it is not

No stock quantity UI, low-stock alerts, warehouse, barcode/SKU, inventory reports, or inventory valuation. **Maal** exists only to speed up Sale and Purchase lines.

## Current development focus

| Step | Action |
|------|--------|
| **Now** | Complete remaining approved Phase B work |
| | Clean, reviewable commits |
| | Release APK builds |
| | Real-world shop testing with actual business data |
| | Bug fixes → performance → UX polish (no workflow changes without approval) |
| | Production-ready stable release → user feedback |
| 🔒 | Phase C (optional GST helper) — frozen until stability + owner approval |

**Rules:** no feature creep · no unnecessary refactoring · stability over new features · real user feedback overrides assumptions · wait for owner review before next major phase.

Full workflow and frozen specs: [`PROJECT_RULES.md`](PROJECT_RULES.md).

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```
