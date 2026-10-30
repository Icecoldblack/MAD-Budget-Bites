# Architecture

**App:** Budget Bites (Flutter, Android, offline)
**Team:** I-IN-TEAM (Uyiosa Nehikhuere)
**Flutter:** 3.47.2, Dart SDK ^3.13.2

Budget Bites has three layers. Screens and widgets draw the UI. Models and
utils hold the data shapes and rules. Repositories are the only code that
talks to storage.

```
 Screens / widgets          (lib/screens, lib/widgets)
        │  call
        ▼
 Repositories               (lib/data)
        │  read / write
        ▼
 SQLite  +  SharedPreferences   (files on the phone)

 Models and rules           (lib/models, lib/utils)
   used by every layer, no Flutter or database code
```

## Folders

| Folder | What is in it |
|---|---|
| `lib/main.dart` | Opens the database, makes the repositories, starts the app |
| `lib/screens/` | The five tab screens plus the bottom bar (`home_shell.dart`) |
| `lib/widgets/` | Reusable pieces: `MealCard`, `PurchaseTile`, `LunchLensCard`, `ReceiptCard`, `PlanProgress`, `EmptyState`, `PurchaseDialog`, `showConfirmDialog` |
| `lib/models/` | `Meal` and `Purchase`, with `toMap()` / `fromMap()` for SQLite |
| `lib/data/` | `DatabaseHelper`, `MealRepository`, `PurchaseRepository`, `SettingsRepository`, `PlanRepository`, sample data |
| `lib/utils/` | `money.dart` (parse and format prices), `dates.dart`, `lunch_lens.dart` (the smart helper) |
| `test/` | 108 unit and widget tests |

## Screens

| Tab | Screen | Purpose |
|---|---|---|
| Meals | `CatalogScreen` | Meal list, cuisine filter, budget left today |
| Add | `MealEditorScreen` | Add or edit a meal (also opened from the detail screen) |
| Plan | `MealDetailScreen` | Today's planned meal, receipt, Lunch Lens, purchases |
| History | `HistoryScreen` | All purchases, total for a date range |
| Settings | `SettingsScreen` | Daily budget slider, load sample data |

`HomeShell` holds the selected tab index. Tapping a meal card pushes
`MealDetailScreen` with `Navigator.push`, and the back button returns to
the list, which reloads.

## Data

### SQLite (meals and purchases)

Two tables, created in `DatabaseHelper`. Database version is 2: version 1
had only `Meal`, and `onUpgrade` adds `PurchaseLog` without touching
existing meals.

```
Meal                                 PurchaseLog
─────────────────────────            ─────────────────────────────────
id                  INTEGER PK       id                INTEGER PK
name                TEXT             mealId            INTEGER → Meal(id)
venueNote           TEXT             purchasedAt       INTEGER (ms)
cuisine             TEXT             actualPriceMinor  INTEGER >= 0
estimatedPriceMinor INTEGER >= 0     note              TEXT
```

- One meal has many purchases.
- `PRAGMA foreign_keys = ON` is set in `onConfigure`, so a purchase cannot
  point to a meal that does not exist.
- `CHECK (... >= 0)` stops negative prices at the database level.
- All queries use `?` placeholders, not string building.
- `deleteMeal` deletes the meal's purchases and then the meal inside one
  transaction, so the app never keeps half a delete.

### SharedPreferences (settings and plan)

| Key | Repository | Value |
|---|---|---|
| `dailyBudgetMinor` | `SettingsRepository` | Daily budget, default 1000 (10.00) |
| `planMealId`, `planStartedAt`, `planFinished` | `PlanRepository` | Today's lunch plan |

These are a few single values, so a key-value store is simpler than a third
table.

### Money

All prices are stored as whole minor units (cents): 6.50 is saved as 650.
This avoids rounding errors from decimals. `money.dart` converts between
the text the user types and the stored number.

## State

The app uses plain `setState` in `StatefulWidget` screens.

- Each screen loads its data in `initState` with an `async` method, then
  calls `setState` to show it. Screens show a loading spinner, the data,
  an empty state, or an error message with a Try again button.
- After every `await`, screens check `if (!mounted) return;` so they do not
  update after the user has left.
- `MealEditorScreen` creates four `TextEditingController`s and disposes them
  in `dispose()`.
- Save buttons use an `_isSaving` flag. The button turns off while saving,
  so a double tap cannot save twice.
- Screens reload when you return to them, so totals and lists always match
  the database.

**Why setState:** the app is small, one person built it, and each screen
reads straight from the repositories. Provider, Riverpod or BLoC would add
extra classes without fixing a real problem here. The trade-off is that a
change on one screen only shows on another screen after it reloads.

## Dependency injection and testing

`main()` opens the database once and passes `MealRepository` and
`PurchaseRepository` into `BudgetBitesApp`, which passes them down to each
screen through constructors. No screen opens the database itself.

Because of this, tests can pass in repositories built on an in-memory
database (`openTestDatabase()` in `test/test_helpers.dart`, using
`sqflite_common_ffi`). The tests run on the computer without a phone and
start with an empty database every time.

`SettingsRepository` and `PlanRepository` are created where they are used.
Tests give them a fake store with `SharedPreferences.setMockInitialValues`.

## Example: logging a purchase

1. User taps **Log purchase** on `MealDetailScreen`.
2. `PurchaseDialog` shows the form. `_validatePrice` rejects empty, bad or
   negative prices.
3. On save, `_isSaving` turns the button off, and the dialog builds a
   `Purchase` model.
4. `PurchaseRepository.insertPurchase` writes it to `PurchaseLog`.
5. The dialog closes, `MealDetailScreen` reloads purchases and calls
   `setState`. The list, receipt and Lunch Lens update.

## Smart helper (Lunch Lens)

`lunch_lens.dart` is pure Dart with no Flutter or database code.
`averageOfLastThree(purchases, before)` takes a list of purchases and
returns a guess, or `null` if there are fewer than three. The detail screen
gets the purchases from the repository and passes them in, so the rule can
be tested with plain lists. Full details are in `AI_FEATURE.md`.

## Packages

| Package | Why |
|---|---|
| `sqflite` | SQLite on Android |
| `sqflite_common_ffi_web` | SQLite when running in a browser (Edge) during development |
| `shared_preferences` | Budget and plan settings |
| `path` | Building the database file path |
| `sqflite_common_ffi` (dev) | In-memory SQLite for tests |

There is no network package. The app makes no network calls.
