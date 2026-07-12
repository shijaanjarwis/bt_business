# BT Business — Master Rules

**Permanent constitution of BT Business.**

Before making **ANY** future code change, read this file first.  
**Never violate these rules.**

---

## SECTION 1 — DESIGN RULES

- Light Theme only.
- No dark cards.
- No black filter chips.
- High contrast text.
- Real data is always dark.
- Placeholders may be light.

---

## SECTION 2 — GREETING

Dashboard greeting is permanently:

**Assalamu Alaikum**  
**(Namaste)**

Never replace it with:

- Welcome
- Good Morning
- Good Afternoon
- Good Evening

---

## SECTION 3 — LANGUAGE

**English**  
↓  
**Daily Spoken Hindi**

Never use formal Hindi.

**Forbidden words:** Vikray, Kray, Shesh, Vyay, etc.

---

## SECTION 4 — BUTTONS

- No overlapping buttons.
- No hidden Save buttons.
- All bottom sheets must use the reusable layout.

---

## SECTION 5 — PAYMENT

App never decides payment mode.

**Cash · UPI · Bank · Credit** must always be entered by the user.

---

## SECTION 6 — SALE

- Never block Sale because of stock.
- Negative stock is allowed.

---

## SECTION 7 — DASHBOARD

- Every card is tappable.
- Every card opens detailed information.
- No decorative cards.

---

## SECTION 8 — VOICE AI

- Always Preview before Save.
- Never auto-save.
- Never guess.
- Always ask if information is missing.

---

## SECTION 9 — REMINDERS

- Morning
- Afternoon
- Evening
- Auto cancel after payment.
- Grouped notifications.

---

## SECTION 10 — BACKUP

**iPhone** → iCloud  
**Android** → Google Drive

No BT Business servers.

---

## SECTION 11 — ACCESSIBILITY

Every visible card, button, tile, Party Name, and Item must be tappable if it represents data.

---

## SECTION 12 — TYPOGRAPHY

- **Real data** → Dark
- **Secondary** → Medium Grey

Never fade important text.

---

## SECTION 13 — SAFE AREA

Nothing should hide behind:

- Keyboard
- Bottom Navigation
- Floating Buttons
- Home Indicator

---

## SECTION 14 — TESTING

Before every commit, run:

1. `flutter analyze`
2. `flutter test`
3. Build Release
4. Install on iPhone 12

---

## SECTION 15 — REGRESSION

Before implementing any feature, check that previous approved behaviour has not changed.

**Never reintroduce:**

- Welcome greeting
- Dark filter chips
- Hidden Save buttons
- Button overlap
- Light unreadable text
- Stock restriction
- Automatic Cash assignment

If any approved feature changes, **restore it before continuing**.

---

*This document is the permanent development constitution for BT Business. Every future implementation must follow it.*
