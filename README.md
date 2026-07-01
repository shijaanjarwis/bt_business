# BT Business

**A digital register for India's smallest shopkeepers** — Bharat Traders.

BT Business replaces the shopkeeper's **paper notebook** (bahi-khata). It is **not** Tally, **not** an ERP, and **not** an inventory management system.

## What it does

- **Bikri / Kharid** — record sales and purchases in register style
- **Hisaab** — party names and balances (Lena Hai / Dena Hai)
- **Jama / Paisa diya / Kharch** — payments and expenses
- **Maal** — item name + unit shortcuts so entry is faster (optional default rates only)
- **Dashboard & History** — today's summary and full register log

## What it is not

No stock quantity UI, low-stock alerts, warehouse, barcode/SKU, inventory reports, or inventory valuation. **Maal** exists only to speed up Sale and Purchase lines.

## Product rules

See [`PROJECT_RULES.md`](PROJECT_RULES.md) for permanent UX, Hindi-first copy, and scope decisions.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
