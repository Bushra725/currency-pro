# CurrencyPro — All-in-One Currency Converter & Calculator

A Flutter app that rebuilds the feature set of *ALL Currency Converter*
(SmartWho) in a new amber/orange theme, and adds a full suite of unit
converters and everyday calculators on top.

**171 assets** (165 fiat currencies + gold, silver, platinum, palladium +
Bitcoin, Ethereum and friends) · **21 measurement categories / 199 units** ·
**12 calculators** · works offline from a cached or bundled rate table.

---

## 1. Quick start

```bash
# Requires Flutter 3.24 or newer (Dart 3.4+)
flutter --version

cd currency_pro
flutter pub get
flutter run            # device or emulator
```

Build a release APK:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

> The project ships with the `android/` folder fully configured. For iOS,
> web or desktop run `flutter create --platforms=ios,web .` once inside the
> project folder — it adds those runners without touching `lib/`.

Opening it in **Cursor**: just open the `currency_pro` folder. Install the
Dart + Flutter extensions, and everything in `lib/` is ready to edit.

---

## 2. Live rates — how they work

There is no public Google currency API (Google Finance's was retired years
ago), so the app uses free, key-less providers instead. Everything works out
of the box, with no signup.

| Data | Provider | Key needed |
|---|---|---|
| Fiat rates (primary) | `open.er-api.com` — 160+ currencies | no |
| Fiat rates (fallback) | European Central Bank via `frankfurter.dev` | no |
| Historical charts | `frankfurter.dev` (fiat), CoinGecko (crypto/metals) | no |
| Bitcoin, Ethereum, gold, silver | CoinGecko public API | no |

Gold and silver come from **PAXG** and **KAG** — tokens each redeemable for
one troy ounce of the physical metal, so their USD price tracks spot closely.

Everything lives in **`lib/core/app_config.dart`**. To move to a paid plan,
fill in one constant and the repository switches automatically:

```dart
static const String exchangeRateApiKey = 'your-key';  // v6.exchangerate-api.com
static const String metalsApiKey       = 'your-key';  // metals-api.com (adds XPT/XPD)
```

How it is wired:

```
RatesApi ──┐
           ├─► RatesRepository ──► RatesProvider ──► every screen
MetalsApi ─┘        │
                    └─► SharedPreferences cache (offline mode)
```

Rates are always stored against **USD** internally and every pair is derived
as a cross rate, so one network call refreshes the whole app. The table is
cached on disk, refreshed automatically every 15 minutes while the app is
open, and on resume.

---

## 3. What is in the app

### Currency (replicated from the reference app)

| Screen | What it does |
|---|---|
| **Real-Time Currency** | Two currencies, live rate, full calculator keypad (`COPY` / `SEND` / `CLR` / `DEL`, `000`, `±`, `=`), quick actions for update / chart / favorites / switch |
| **Multi Currency Converter** | One amount into 2, 4 or 8 currencies at once |
| **Trend Charts** | 10D · 1M · 3M · 6M · 1Y · 2Y history, touch-to-inspect chart, day-by-day table with increase/decrease ratio |
| **Dollar, Bitcoin, Gold, Silver** | Price tab (per oz t / g / kg / tola), cross-rate matrix, and *My Assets* portfolio |
| **Exchange Rate List** | Base currency + base amount → every currency, searchable, favorites filter |
| **Currency Simulation** | "What if the rate moved ±25 %" with a scenario table |
| **Exchange Rate Adjustment** | Bank spread + fixed fee → what the recipient actually gets, with a provider comparison |
| **Currency Profile** | ISO 4217 code, symbol, subunit, country, decimals, live rate |
| **Rate Alert** | Target rates with progress bars, marked achieved when hit |
| **Travel Budget** | Trips with budgets, expenses by category (food/transport/hotel/shopping/…), spend vs budget |
| **World Clock** | 73 cities, live seconds, reorderable |
| **Tip Calculator** | Tip, total, split, round-up, and the total in your home currency |

### Calculators (new)

Scientific · Age · Date difference · Discount · Percentage · BMI ·
Loan/EMI (with amortisation table) · Tip · Height (ft-in ↔ cm) ·
Number base (bin/oct/hex/2–36).

### Unit converters (new)

Length · Weight & mass · Temperature · Area · Volume · Speed · Time ·
Digital storage · Data transfer rate · Fuel economy · Pressure · Energy ·
Power · Force · Torque · Angle · Frequency · Density · Illuminance ·
Cooking · Shoe size — **199 units**, including South-Asian units
(tola, marla, kanal, bigha).

### Theming

Ten amber/orange themes (seven dark, three light) named after cities, picked
from **Settings › Select Theme** with a live preview of the keypad.
Add one by appending an `AppPalette` to `lib/core/theme/theme_catalog.dart`
— nothing else needs to change.

---

## 4. Project layout

```
lib/
├── main.dart                  # bootstrap + provider wiring
├── app.dart                   # MaterialApp, theme, lifecycle refresh
├── routes.dart                # every named route
├── core/
│   ├── app_config.dart        # endpoints, API keys, tunables
│   ├── theme/                 # AppPalette, ThemeCatalog, AppTheme
│   ├── utils/                 # expression parser, formatting, haptics
│   └── widgets/               # drawer, keypad, chart, cards, flags
├── data/
│   ├── currency_catalog.dart  # 171 assets (generated table — editable)
│   ├── currency_lookup.dart   # fast lookup + search
│   ├── models/                # Currency, RateSnapshot, RateAlert, Trip, ClockEntry
│   ├── services/              # RatesApi, MetalsApi, HistoryApi, PrefsService
│   └── repositories/          # RatesRepository (network + cache)
├── state/                     # ChangeNotifier providers
└── features/
    ├── currency/  alerts/  travel/  tools/
    ├── calculators/           # scientific, age, BMI, loan, …
    ├── converters/            # unit catalog + generic converter
    └── settings/              # settings, theme picker, about
```

**Dependencies (5):** `provider`, `http`, `shared_preferences`, `intl`,
`share_plus`. The charts are hand-drawn with `CustomPainter`, so there is no
charting package to keep in sync.

---

## 5. Tests

```bash
flutter test
```

Covers cross-rate maths, JSON round-tripping of the cached table, the
expression parser (precedence, functions, percent, error handling), unit
conversions (including the temperature offsets and the inverse fuel-economy
scale), catalog integrity and number formatting.

---

## 6. Customising

| I want to… | Do this |
|---|---|
| Change the app name / package id | `android/app/build.gradle` → `applicationId`, `AndroidManifest.xml` → `android:label`, `AppConfig.appName` |
| Change the icon | Replace `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| Add a currency | Add one line to `lib/data/currency_catalog.dart` |
| Add a unit or category | Add to `lib/features/converters/unit_catalog.dart` |
| Add a theme | Add an `AppPalette` to `lib/core/theme/theme_catalog.dart` |
| Swap the rate provider | `lib/core/app_config.dart` + `lib/data/services/rates_api.dart` |
| Add a screen | Create it in `lib/features/…`, register it in `lib/routes.dart`, add a drawer entry in `lib/core/widgets/app_drawer.dart` |

### Before publishing (Play Store / App Store)

1. Set your own `applicationId` if you do not own `com.theoccess.currencypro`.
2. Create an upload keystore and copy `android/key.properties.example` to
   `android/key.properties` (that file is gitignored). Then:

   ```bash
   flutter build appbundle --release
   # output: build/app/outputs/bundle/release/app-release.aab
   ```

3. Rate alerts are evaluated in-app (including after a live refresh). They
   are not push notifications. Add `flutter_local_notifications` +
   `workmanager` if you want background delivery.
4. Check each data provider's terms for commercial use.
5. Target SDK is 36 (required for new Play uploads in 2026).

---

## 7. Known limits

- **History for exotic pairs.** Daily history comes from the ECB basket
  (~30 major currencies) plus crypto/metals. Charting e.g. PKR/NGN returns
  an explanatory message rather than fabricated data.
- **Platinum and palladium** need a keyed metals provider
  (`AppConfig.metalsApiKey`); they are listed but unpriced without it.
- **World clock offsets** are standard time and do not track daylight
  saving. Swap in the `timezone` package if you need DST-accurate values.
- Rates are mid-market reference values, not dealing rates.

---

*Not financial advice. Rates are provided by third parties and may be
delayed or inaccurate.*
