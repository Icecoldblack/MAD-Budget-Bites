# Restart Test

**Date:** October 25, 2026
**Tester:** Uyiosa Nehikhuere
**Goal:** The same data and totals show after a restart, on two emulators, with airplane mode on.

## Setup

| | Emulator 1 | Emulator 2 |
|---|---|---|
| Device | Pixel 9 Pro XL | Pixel 5 |
| Android | 17 | 17 |
| Airplane mode | On (checked: `airplane_mode_on = 1`) | On (checked: `airplane_mode_on = 1`) |
| Data | Existing data (sample data loaded twice) | Fresh install, empty |

"Restart" means the app was force-stopped (`adb shell am force-stop`), its
process was checked to be gone, and then the app was opened again.

## Emulator 1: Pixel 9 Pro XL

1. Turned on airplane mode.
2. Wrote down the Meals and History screens.
3. Force-stopped the app and opened it again.
4. Compared every line on both screens.

| Check | Before restart | After restart |
|---|---|---|
| History total | 169.00 | 169.00 |
| Budget left today | 8.50 of 8.50 | 8.50 of 8.50 |
| Meals and purchases on screen | Written down | Same, line for line |

**Result: Pass**

Screenshots: `pixel9proxl_1_before_restart.png`, `pixel9proxl_2_after_restart.png`

## Emulator 2: Pixel 5 (the test from the proposal)

On a fresh install with airplane mode on:

| Step | Expected total | Shown |
|---|---|---|
| Add meal "Rice Bowl", log 4.50 and 6.00 | 10.50 | 10.50 |
| Change 6.00 to 5.50 | 10.00 | 10.00 |
| Delete the first purchase (4.50) | 5.50 | 5.50 |
| Force-stop and reopen the app | 5.50 | 5.50 |
| Reboot the whole emulator and reopen the app | 5.50 | 5.50 |

Budget left today was 4.50 of 10.00 before and after both restarts.

**Result: Pass**

Screenshots: `pixel5_1_total_1050.png` to `pixel5_5_after_full_reboot.png`

## Conclusion

On both emulators, with no network, every meal, purchase, and total was the
same after the app restarted. On the Pixel 5 the data also survived a full
reboot. The data is stored on the device in SQLite (meals and purchases) and
SharedPreferences (budget and plan).
