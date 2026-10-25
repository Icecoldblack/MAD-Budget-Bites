# AI Feature: Lunch Lens

**Owner:** Uyiosa Nehikhuere
**App:** Budget Bites (Flutter, offline)

Lunch Lens is the smart helper in Budget Bites. It is one card on a meal's
detail screen that guesses what the **next** purchase of that meal will cost.

It is a **simple rule, not a trained model**. There is no machine learning,
no online service, and no data ever leaves the phone. The card says this to
the user.

---

## 1. What it does for the user

Before choosing lunch, the student can see a likely cost for a meal and
compare it with the price they planned. This helps them notice when a meal
really costs more than they think.

## 2. Inputs

| Input | Where it comes from | Units |
|---|---|---|
| The three most recent **earlier** purchases of the chosen meal | `PurchaseLog` table (`actualPriceMinor`, `purchasedAt`, `id`) | Whole minor units (650 means 6.50) |

Rules for picking the three purchases:

- Only purchases made **before** the moment of the guess are used. A later
  purchase is never used.
- Newest first. If two purchases have the **same time**, the one with the
  higher log `id` counts as newer.
- Negative prices are invalid. The database refuses to save them, and
  Lunch Lens skips them if one ever appears.

## 3. The rule

```
estimate = (price1 + price2 + price3) / 3, rounded to the nearest whole unit
```

Halves round up. Note: the average of three whole numbers always ends in
.00, .33 or .67, so an exact half never happens in practice. The tests check
that .67 rounds up and .33 rounds down.

If there are **fewer than three** earlier purchases, there is no estimate and
the card says **"Not enough history"**.

## 4. What the card shows (explanation)

- The estimate, labelled "Likely cost of your next purchase".
- "Average of your last 3 purchases:" followed by the **three
  amounts and their dates**, so the user can see exactly where the number
  came from.
- A note that it is a simple rule (an average), not a trained model, and that
  one unusual price can pull it up or down.

## 5. User control

- The estimate **never fills in or changes** the price the user types.
- The user can ignore the card completely.
- Only the **Log purchase** button saves an amount.

A test checks that the price field is still empty when the Log purchase form
opens, even when an estimate is showing.

## 6. Baseline

To know if the average is any good, it is compared with a simpler baseline:

```
baseline = the price of the most recent purchase
```

## 7. Alternative: the median

The proposal also considered the **median** (middle value) of the last three
purchases. One very high price does not pull the median up. The average was
chosen because it is easier to explain on the card ("add them up and divide
by three"). The median is built too, so the two can be compared.

## 8. Test results

All amounts are in minor units. "Error" is how far the guess was from the
real next price.

| # | Type | Input | Expected | Result |
|---|---|---|---|---|
| 1 | Normal | Earlier: 450, 600, 750. Next: 650. | Estimate 600, error 50. Baseline 750, error 100. Changing 750 to 900 gives 650. | Pass |
| 2 | No data | Only two earlier purchases. | No estimate. Card says "Not enough history". | Pass |
| 3 | Invalid | A price of -100. | Rejected by the database, not saved, and not used by Lunch Lens. | Pass |
| 4 | Boundary | Two purchases at the same time, one later purchase. | Same time is ordered by log ID. The later purchase is left out. 516.67 rounds to 517. | Pass |
| 5 | Counterexample | Earlier: 500, 500, 2000. Next: 520. | Estimate 1000, error 480. Baseline error 1480. Median error 20. | Pass |

Extra checks also pass: no purchases at all, exactly three purchases is
enough, a purchase at the exact same moment is not "earlier", only the newest
three are used, and the order of the input list does not matter.

**About test 4:** with only three earlier purchases, ordering by ID cannot
change which three are picked. So the test uses four earlier purchases (two at
the same time) plus one later purchase. A separate test checks that exactly
three purchases is enough for an estimate.

### Comparing the three methods

| Case | Real next price | Average (Lunch Lens) | Baseline (last price) | Median |
|---|---|---|---|---|
| 1. Normal (450, 600, 750) | 650 | 600 (error 50) | 750 (error 100) | 600 (error 50) |
| 5. Outlier (500, 500, 2000) | 520 | 1000 (error 480) | 2000 (error 1480) | 500 (error 20) |

The average beats the baseline in both cases. The median ties the average in
the normal case and is much better when there is one unusual price.

## 9. A case that breaks it

If the last three purchases are 500, 500 and 2000 (for example, one big
group order), the average is 1000. If the next purchase is a normal 520, the
average is off by 480. One outlier hurts the average a lot.

The card shows all three amounts, so the user can see the 2000 and
understand why the estimate is high.

## 10. Where the code is

| What | File |
|---|---|
| The rule (average, baseline, median) | `Budget-bites/lib/utils/lunch_lens.dart` |
| The card on the detail screen | `Budget-bites/lib/widgets/lunch_lens_card.dart` |
| The five test cases and extra checks | `Budget-bites/test/lunch_lens_test.dart` |
| Tests for the card | `Budget-bites/test/lunch_lens_card_test.dart` |

The main function is `averageOfLastThree(purchases, before)`. It is one plain
Dart function with no packages and no network.

To run the tests, from the `Budget-bites` folder:

```
flutter test test/lunch_lens_test.dart test/lunch_lens_card_test.dart
```

## 11. Limits

- It needs at least three purchases of a meal before it can guess.
- One unusual price can pull the guess far off (see section 9).
- It does not know about price changes, discounts or the day of the week.
- It only looks at one meal at a time.
