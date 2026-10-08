# Architecture & Design Decisions

This document explains *why* the extension is built the way it is,
including several real Business Central platform behaviors this
project uncovered during development, not just what the code does.

## Data Model: History vs. Current State

`PCX Purchase Risk Assessment` is an append-only audit trail: one row
per meaningful risk event (Released, Receipt Posted, Invoice Posted,
Manually Closed), never overwritten. Three cached fields on `Purchase
Header` (`PCX Current Risk Level`, `PCX Current Match Status`, `PCX
Currently Overdue`) hold the *current* state, for fast display and
dashboard filtering.

This is the same frozen-snapshot vs. live-cache principle used in the
companion project
([business-central-warehouse-control](https://github.com/issakamo/business-central-warehouse-control)),
applied here to history vs. current state. The assessment table records
what actually happened, in order. The header fields are a denormalized
convenience, so the Purchase Order page, Vendor Card, and dashboard
don't have to query the full history every time they render.

`PCX Vendor Scorecard` follows the same current-state-cache pattern:
one row per vendor, fully overwritten on recalculation, never a history
of past scores.

### Three separate enums, not one

`PCX Match Status` (a fact: do the documents agree?), `PCX Risk Level`
(a judgment: how bad is it?), and `PCX Risk Trigger` (provenance: why
does this row exist?) are kept as three distinct enums rather than
folded together. Conflating them would blur "what happened" with "what
we concluded." That produced a real bug during development (see the
three-way merge, below), precisely because match status and risk level
were being reasoned about as if they were the same thing.

## The Matching Engine

### Receipt matching

`EvaluateReceiptMatch` compares ordered quantity (`Purchase Line`,
`CalcSums(Quantity)`) against received quantity (`Purch. Rcpt. Line`,
`CalcSums(Quantity)`), both filtered to `Type = Item`. A zero-received
guard returns `Not Yet Received` before any percentage math runs. This
avoids division by zero, and correctly represents a normal in-progress
state rather than an error.

**Business Central deletes a Purchase Order line once it is fully
received and fully invoiced.** `SumOrderedQuantity` handles this
explicitly: if the order line no longer exists, its absence is treated
as confirmation that the order completed exactly as ordered
(`ordered = received`). Otherwise a missing line would be misread as
zero ordered quantity, and a completed, correctly matched order would
be misreported as a 100% quantity mismatch.

### Invoice matching

`EvaluateInvoiceMatch` compares each posted invoice line against the
receipt line it was invoiced from (paired via `Order Line No.`), using
the receipt line's net unit cost (`Direct Unit Cost` less
`Line Discount %`) multiplied by the quantity actually invoiced. The
summed expected amount is rounded to General Ledger Setup's
`Amount Rounding Precision` before being compared with the summed
invoiced `Amount`.

Two earlier designs were deliberately replaced:

- Reading the ordered baseline from the live `Purchase Line` failed,
  because Business Central deletes the order line once it is fully
  received and invoiced. Posted receipt lines persist.
- Comparing **document totals** (total received amount vs. total
  invoiced amount) misreported partial invoicing: 100 units received
  and 50 invoiced at the correct price appeared as a 50% price
  mismatch. Comparing per line, for the invoiced quantity only,
  separates genuine price variance from ordinary partial invoicing.
  Covered by `EvaluateInvoiceMatch_PartialInvoiceSamePrice_ReturnsMatched`.

`Line Discount Amount` does not exist on `Purch. Rcpt. Line` in this
version, so the discount is applied from `Line Discount %`. An invoice
line with no matching receipt line contributes nothing to the expected
amount, so it surfaces as a variance rather than passing silently. If
an order line was received across multiple receipts at different
prices, the first receipt line's price is used, an accepted
simplification.

### Three-way merge, and a bug found by manual testing

`EvaluateThreeWayMatch` combines the two two-way results into the full
six-state `PCX Match Status`. `Not Yet Received` short-circuits before
invoice status is evaluated, since invoice accuracy is meaningless on
an order nothing has arrived against.

**A real bug existed here for a period during development.** The
original merge logic checked invoice status *before* checking whether
a known quantity mismatch existed. So an already-detected
`Quantity Mismatch` was silently discarded and reported as
`Not Yet Invoiced` whenever invoicing hadn't happened yet, understating
risk as `Low` on an order with a real, large variance. This was found
through manual Web Client testing, not an automated test: no existing
test scenario happened to combine "quantity mismatch" with "not yet
invoiced". It is now fixed, and covered by a regression test
(`EvaluateThreeWayMatch_QtyMismatchNotYetInvoiced_ReportsQuantityMismatchNotMasked`).
A known receipt-side quantity problem is always reported, escalating
to `Quantity and Price Mismatch` if a price problem is found once
invoicing happens.

### Scope boundary: document-level quantity matching

Quantity matching operates on **document totals**, not line-to-line
reconciliation. This was evaluated deliberately, not overlooked. An
earlier concern was that it could hide item substitution (for example,
100 units of Item A ordered but Item B received at the same total).
That does not hold under closer inspection. A posted receipt or invoice
line is generated directly from a specific order line and inherits that
line's item, and Business Central validates `Qty. to Receive` and
`Qty. to Invoice` per line against that line's own outstanding
quantity, not a shared document-level pool. So normal posting paths
cannot silently substitute an item, or redistribute quantity across
lines, to hide a discrepancy in the total.

A narrower residual case, a line added manually during posting with no
order-line origin, was identified but deliberately not given its own
`Match Status` value, given its low real-world likelihood relative to
the added complexity.

## Risk-Level Weighting

`DetermineRiskLevel` treats `Match Status` as the dominant signal, not
one input among several weighted percentages:

- `Matched`, `Not Yet Received`, and `Not Yet Invoiced` give a
  baseline of `Low`.
- `Quantity Mismatch` or `Price Mismatch` (alone) are tiered by that
  variance percentage, using the same 5% / 20% / 50% thresholds
  (Medium / High / Critical) as the companion project's
  `DeterminePriority`, for consistency across the portfolio.
- `Quantity and Price Mismatch` baselines on the **more severe of the
  two variances**, not their sum, because summing two small variances
  could cross a threshold neither crosses individually. It then
  escalates exactly **one tier** for the dual failure, rather than
  jumping straight to `Critical` regardless of magnitude. This is a
  documented simplification: a 4%-and-45% combination is
  indistinguishable from a 45%-and-45% one (both baseline on 45%, and
  both escalate one tier). A production version might blend both
  magnitudes rather than taking the maximum.
- `Overdue` is a **modifier only**. It nudges a clean (`Low`) result up
  to `Medium`, but never independently produces `High` or `Critical`,
  and never overrides a worse tier driven by match status. An order is
  overdue when any item line's Expected Receipt Date is earlier than
  the work date and that line still has quantity outstanding. The
  line-level date is used because it is the one users see and edit;
  an earlier version read the header's Expected Receipt Date, which
  this version doesn't show on the Purchase Order page. The work date
  is used rather than the system clock, following Business Central
  convention.

This is a different shape from the companion project's risk
calculation, and the difference is deliberate. Project 1 needed one
variance-percentage formula, because there was only one kind of
discrepancy to score. This project needed a staged decision table,
because multiple independent failure dimensions (quantity, price,
timing) can combine. A single formula can't express "the same finding
shouldn't count twice" the way an explicit escalation step can.

## De-duplicating Redundant Assessments

Business Central internally reopens and re-releases a purchase order
as part of posting a partial quantity, to recalculate outstanding
amounts. That caused `OnAfterReleasePurchaseDoc` to fire several times
per document with no change in state between firings, producing
misleading duplicate audit rows.

`AssessPurchaseOrder` skips inserting a new assessment when the most
recent one for the same document already has an identical
`Match Status`, `Risk Level`, **and** `Overdue` flag. All three are
compared deliberately. An earlier version of this guard compared only
`Match Status` and `Risk Level`, so an overdue-only change (the same
match and risk, but the order newly past its expected receipt date)
was wrongly treated as redundant and skipped. That silently left the
header's cached overdue flag, and therefore the dashboard's Overdue
count, stale. It was caught by a dedicated test
(`AssessPurchaseOrder_OverdueChangeOnly_StillRecordsNewAssessment`).

As a side effect, `PCX Vendor Scorecard`'s `Assessment Count` reflects
genuinely distinct state changes, not posting-mechanics repetition.

## Header Deletion

Business Central deletes the Purchase Order **header** entirely once
all lines are fully received and invoiced. `AssessPurchaseOrder` checks
`PurchaseHeader.Find()` before writing the cached fields. The audit
record is always written; only the live-cache update is skipped when
there is no longer a header to cache onto.

## Administrative Closure

A vendor shortfall that will never be delivered is closed, in standard
Business Central practice, by reopening the order and reducing the
line's `Quantity` to match what was actually received. This zeroes the
outstanding quantity without receiving anything further.

This is hooked via `Purchase Line`'s auto-published
`OnAfterValidateEvent` for the `Quantity` field, a platform mechanism
that exists for every field on every table, not a custom event that
had to be discovered.

Guard conditions identify a genuine closure from the line's own values
rather than `xRec`: something has already been received, and Quantity
now equals the quantity received. Because `OnAfterValidateEvent` fires
before the line is saved, and the risk engine reads lines from the
database, the subscriber saves the new quantity first (`Modify(false)`;
the caller's own save still runs the table triggers) so the
re-assessment sees the corrected order total.

No separate "closed" status was needed. Because the matching engine
reads `Quantity` from the line, re-running `AssessPurchaseOrder`
straight after this edit recalculates against the corrected order
total, and the quantity risk clears because the comparison now
reflects reality. A separate price problem, if there is one, is still
reported, so closing out a shortfall cannot hide overbilling. Because
nothing remains outstanding, the order also stops counting as overdue.

This subscriber was briefly lost during a revert of the event
subscribers (see the test-isolation section below). Its regression test,
`AdministrativeClosure_ReducingQuantityToReceived_ClearsRisk`, failed as
a result, which is how the loss was noticed and corrected. The test
reopens the order before editing the line, as Business Central requires
for released documents, matching what a user does in the Web Client.

## Vendor Scorecard

A pure rollup over `PCX Purchase Risk Assessment`. It does not
re-derive matching or risk logic itself, so if a bug is fixed in the
matching engine, the scorecard is automatically correct on its next
recalculation, with nothing duplicated to fix separately.

- **On-Time %**: the proportion of assessments where `Overdue = false`.
- **Quantity / Price Accuracy %**: the average, across all of a
  vendor's assessments, of each assessment's own accuracy,
  `100 − |variance %|`, floored at 0. Absolute value is used so that
  over- and under-delivery or pricing don't cancel out and mask an
  inconsistent vendor. The per-assessment floor means a variance of
  100% or more counts as 0% accurate. An earlier version averaged the
  raw variances first, which let a few extreme outliers (for example,
  an invoice at several times the agreed price) drive a vendor's
  accuracy, and overall score, below zero (observed: −788% price
  accuracy and a −200.6 overall score). Covered by
  `RecalculateScorecard_ExtremeVariance_AccuracyFlooredAtZero`.
- **Overall Score**: an equal, unweighted average of the three metrics
  above. This is a defensible default, not a claim that the three
  dimensions are equally important, and is left open to becoming a
  configurable weighting later.
- **Minimum sample size**: fewer than 5 assessments gives
  `Insufficient Data` rather than a scored rating. This is a floor
  against one lucky or unlucky purchase order deciding a vendor's
  entire reputation, not a claim that 5 is statistically sufficient.
- **Rating bands**: Excellent ≥ 90, Good ≥ 75, Fair ≥ 60, otherwise
  Poor.

A scorecard recalculates whenever its vendor receives a new assessment.
**Recalculate All**, on the Vendor Scorecards list, refreshes every
scorecard on demand, which is needed after any change to the scoring
rules, since existing scorecards would otherwise keep their old values
until each vendor's next assessment.

An Insufficient Data vendor is shown in a muted, neutral style (List
page and Vendor Card), and its scores are printed blank rather than as
0 in the report. An unrated vendor is a different kind of unknown from
a known-poor one, and the two should not look alike.

## Dashboard Cue

Tiles count `Purchase Header` directly, filtered on the cached current
fields, **not** the assessment history table. Counting the history
would count *events* (an order reassessed five times would count five
times), when the dashboard needs *current open problems* (that same
order counted once). Each tile's drill-down opens a Purchase Order List
pre-filtered to exactly that condition (`SetTableView`), since a
manager clicking a risk count wants to act on those specific orders.

The Overdue tile initially approximated overdue status via risk level
(`<> Low`), before `PCX Currently Overdue` existed as its own cached
field. That approximation was replaced once the real field was added,
since risk level and overdue status are different facts that merely
coincided in early test data.

## Reporting

`PCX Purchase Risk Summary` combines two independent dataitems (open
risk orders, and vendor scorecards) in one document rather than two
separate reports, since they are naturally two sections of one
procurement review. A separate detailed audit-trail report was
deliberately not built: the `PCX Purchase Risk List` page already
serves that need, and a second report would exist mainly for symmetry
with the companion project.

The report's minimum-risk-level filter
(`PCX Risk Report Mgt.ApplyMinimumRiskFilter`) uses `Enum.AsInteger()`
with a `>=` comparison against `PCX Risk Level`'s ordinal value. This
only works because the enum's `value()` declarations are in ascending
severity order (`Low = 0` through `Critical = 3`). That dependency
matters if the enum is ever extended: inserting a new value out of
severity order would silently break the filter, with no compile error.

The dynamic report heading, which reflects the selected minimum risk
level, is built in `OnPreReport` via `StrSubstNo` and exposed as an
ordinary report column, since Word layouts have no separate "report
title" binding outside the dataset.

The open-orders section has no Expected Receipt column. That column
read the header-level date this version doesn't expose, so it was
always blank. The Overdue column already reflects the line-level
overdue logic.

## A Business Central Test-Isolation Discovery

While developing the administrative-closure feature, an automated test
appeared to show that a freshly posted receipt's data was invisible to
the risk engine: `SumReceivedQuantity` returned `0` when read by the
receipt-posting subscriber within the same test method, even with a
plain `FindSet` rather than an aggregate `CalcSums`.

Step-by-step isolation testing, documented in this project's commit
history, identified the cause. **Business Central's `Purch.-Post`
posting routine relies on internal `Commit()` calls, which are
suppressed under the automated test framework's default transaction
isolation** (`TransactionModel` / `TestIsolation`: a test's changes are
rolled back at the end by design). Data that a live post commits
partway through is therefore not reliably visible to a subscriber
reading it back within the same still-open test transaction, even
though the identical code path works correctly in real posting through
the Web Client. That was confirmed by creating and posting real
purchase orders by hand and observing correct risk transitions
throughout.

**This is a test-environment limitation, not a defect in the
extension.** The matching and scoring logic (`EvaluateReceiptMatch`,
`EvaluateInvoiceMatch`, `EvaluateThreeWayMatch`, `DetermineRiskLevel`)
is unit-tested by calling these procedures directly against data built
with Microsoft's `Library - Purchase` and `Library - Inventory` test
toolkits, and none of that coverage depends on subscriber-triggered
posting visibility. Tests that need a risk state after posting set it
up with a direct `AssessPurchaseOrder` call instead. What cannot be
automated under default isolation is asserting that the receipt and
invoice posting subscribers update the header's cached fields within
the same test transaction; that behavior was verified manually against
real posted purchase orders.

Two approaches were tried and reverted during this investigation, and
are kept here because ruling them out was informative: switching
`CalcSums` calls to manual `FindSet`/`Next` accumulation, and switching
from the document-level `OnAfterPostPurchaseDoc` event to the
line-level `OnAfterPurchRcptLineInsert` event. Neither resolved the
symptom. That ruled out stale summary indexes and event timing within
posting, and pointed to test-transaction commit suppression as the
actual cause.

## Housekeeping: Namespace Correction

Every namespace in this project was originally declared as
`WarehouseControl.Purchasing` (and `.Test`), carried over from the
companion warehouse project's convention, where it made sense as a
shared root within one app. Since this project is its own standalone
extension with an independent `app.json` and GUID, that root didn't
describe this app on its own merits. It was corrected to
`PurchaseControl.Purchasing` (and `PurchaseControl.Purchasing.Test`)
across every `.al` file in a single isolated commit, with no functional
change: a namespace rename doesn't affect object names, IDs, fields,
or behavior.

## Permissions

There are two permission sets. `PCX Purchase Risk User` is read-only on
the audit trail and the scorecard. `PCX Purchase Risk Manager` adds
insert and modify on the assessment table (needed to edit Notes on the
Card) and full control of the scorecard cache. Deliberately, **no
permission set grants delete** on `PCX Purchase Risk Assessment`. Every
row is written by `AssessPurchaseOrder` alone, and unlike the companion
project's resolvable exceptions, there is no legitimate reason for any
user, including a manager, to delete a historical risk assessment. The
audit trail is append-only by permission.