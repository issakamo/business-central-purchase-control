# Architecture & Design Decisions

This document explains *why* the extension is built the way it is,
including several real Business Central platform behaviors this
project uncovered during development — not just what the code does.

## Data Model: History vs. Current State

`PCX Purchase Risk Assessment` is an append-only audit trail — one row
per meaningful risk event (Released, Receipt Posted, Invoice Posted,
Manually Closed), never overwritten. Three cached fields on `Purchase
Header` (`PCX Current Risk Level`, `PCX Current Match Status`, `PCX
Currently Overdue`) hold the *current* state for fast display and
dashboard filtering.

This is the same frozen-snapshot-vs-live-cache principle used
throughout the companion project
([business-central-warehouse-control](https://github.com/issakamo/business-central-warehouse-control)),
applied here to history vs. current state rather than detection-time
vs. right-now: the assessment table is what actually happened, in
order; the header fields are a denormalized convenience so the
Purchase Order page, Vendor Card, and dashboard don't have to query
the full history every time they render.

`PCX Vendor Scorecard` follows the same current-state-cache pattern —
one row per vendor, always fully overwritten on recalculation, never
a history of past scores.

### Three separate enums, not one

`PCX Match Status` (a fact — do the documents agree), `PCX Risk Level`
(a judgment — how bad is it), and `PCX Risk Trigger` (provenance — why
does this row exist) are kept as three distinct enums rather than
folded together. Conflating them would blur "what happened" with
"what we concluded," which produced a real bug during development
(see Match-Status Masking, below) precisely because match status and
risk level were being reasoned about as if they were the same thing.

## The Matching Engine

### Receipt matching

`EvaluateReceiptMatch` compares ordered quantity (`Purchase Line`,
`CalcSums(Quantity)`) against received quantity (`Purch. Rcpt. Line`,
`CalcSums(Quantity)`), both filtered to `Type = Item`. A zero-received
guard returns `Not Yet Received` before any percentage math runs
(avoiding division by zero and correctly representing a normal
in-progress state, not an error).

**Business Central deletes a Purchase Order line once it is fully
received and fully invoiced.** `SumOrderedQuantity` handles this
explicitly: if the order line no longer exists, its absence is treated
as confirmation the order completed exactly as ordered (`ordered =
received`), rather than misreading a missing line as zero ordered
quantity — which would otherwise misreport a completed, correctly
matched order as a 100% quantity mismatch.

### Invoice matching

`EvaluateInvoiceMatch` compares an ordered-amount baseline against
invoiced amount (`Purch. Inv. Line`, `CalcSums(Amount)`). The ordered
baseline is read from **`Purch. Rcpt. Line`, not `Purchase Line`** —
deliberately, and for a different reason than the quantity side: the
live order line can disappear (as above) *and*, even while it exists,
doesn't reliably carry line-level discount information the way a
posted receipt line does. The baseline is computed manually
(`Quantity × Direct Unit Cost`, net of `Line Discount %`) rather than
via `CalcSums`, since discount-adjusted amounts aren't expressible as
a single summable field. `Line Discount Amount` does not exist on
`Purch. Rcpt. Line` in this project's Business Central version, so the
discount is recomputed from `Line Discount %` rather than read as a
stored value — mathematically equivalent, with a theoretical
fraction-of-a-cent rounding difference against BC's own internal
rounding on unusual quantity/percentage combinations, which is an
accepted, documented simplification.

### Three-way merge, and a real bug found by manual testing

`EvaluateThreeWayMatch` combines the two two-way results into the full
six-state `PCX Match Status`. `Not Yet Received` short-circuits before
invoice status is even evaluated, since invoice accuracy is
meaningless on an order nothing has arrived against.

**A real bug existed here for a period during development:** the
original merge logic checked invoice status *before* checking whether
a known quantity mismatch existed, so a genuine, already-detected
`Quantity Mismatch` was silently discarded and reported as `Not Yet
Invoiced` whenever invoicing hadn't happened yet — understating risk
as `Low` on an order with a real, large variance. This was found
through manual Web Client testing, not by an automated test (no
existing test scenario happened to combine "quantity mismatch" with
"not yet invoiced"), and is now both fixed and covered by a regression
test (`EvaluateThreeWayMatch_QtyMismatchNotYetInvoiced_ReportsQuantityMismatchNotMasked`).
The fix: a known receipt-side quantity problem is always reported,
escalating to `Quantity and Price Mismatch` only if a price problem is
subsequently found once invoicing does happen.

### Scope boundary: document-level, not line-level, matching

Matching operates on **document totals**, not individual line-to-line
reconciliation. This was evaluated deliberately, not overlooked: an
earlier concern that this could hide item substitution (e.g., 100
units of Item A ordered but Item B received/invoiced at the same
total) does not actually hold under closer inspection — a posted
receipt or invoice line is generated directly from a specific order
line and inherits that line's item, and BC validates `"Qty. to
Receive"`/`"Qty. to Invoice"` per line against that line's own
outstanding quantity, not a shared document-level pool. Normal posting
paths cannot silently substitute an item or redistribute quantity
across lines to hide a discrepancy in the aggregate total. A narrower
residual case — a manually added line during posting with no order-line
origin — was identified but deliberately not built into a separate
`Match Status` value, given its thin real-world likelihood relative to
the added complexity. Document-level totals are considered adequate
matching for this project's scope.

## Risk-Level Weighting

`DetermineRiskLevel` treats `Match Status` as the dominant signal, not
one input among several weighted percentages:

- `Matched`, `Not Yet Received`, `Not Yet Invoiced` → baseline `Low`.
- `Quantity Mismatch` / `Price Mismatch` (alone) → severity tiered by
  that variance percentage, using the same 5% / 20% / 50% thresholds
  as the companion project's `DeterminePriority` (Medium / High /
  Critical), for consistency across the portfolio.
- `Quantity and Price Mismatch` → baselines on the **more severe of
  the two variances** (not their sum — summing two small variances
  could cross a severity threshold neither individually would), then
  escalates exactly **one tier** above that baseline for the
  dual-failure itself, rather than jumping straight to `Critical`
  regardless of magnitude. This is a deliberate, documented
  simplification: it means a 4%-and-45% combination is
  indistinguishable from a 45%-and-45% combination (both baseline on
  45%, both escalate one tier) — a production version might blend
  both magnitudes rather than taking the max.
- `Overdue` is a **modifier only**: it nudges a clean (`Low`) result up
  to `Medium`, but never independently produces `High`/`Critical`, and
  never overrides a worse match-status-driven tier.

This is a materially different shape from the companion project's risk
calculation, worth being able to explain: Project 1 needed one
variance-percentage formula because there was only one kind of
discrepancy to score. This project needed a staged decision table
because multiple independent failure dimensions (quantity, price,
timing) can combine, and a single formula can't represent "the same
finding reported twice shouldn't double the score" the way an explicit
escalation step can.

## De-duplicating Redundant Assessments

Business Central internally reopens and re-releases a purchase order
as part of posting a partial quantity (to recalculate outstanding
amounts), which caused `OnAfterReleasePurchaseDoc` to fire multiple
times per document with no actual change in state between firings —
producing misleading duplicate audit rows.

`AssessPurchaseOrder` skips inserting a new assessment when the most
recently inserted one for the same document already has an identical
`Match Status`, `Risk Level`, **and** `Overdue` flag. All three are
compared deliberately: an earlier version of this guard compared only
`Match Status`/`Risk Level`, which meant an overdue-only change (same
match/risk, but a PO newly crossing its expected receipt date) was
incorrectly treated as redundant and skipped — silently leaving the
header's cached overdue flag, and therefore the dashboard's Overdue
count, stale. This was caught by a dedicated test
(`AssessPurchaseOrder_OverdueChangeOnly_StillRecordsNewAssessment`)
before it could reach production behavior.

As a side effect, `PCX Vendor Scorecard`'s `Assessment Count` reflects
genuine distinct state changes, not posting-mechanics repetition.

## Header Deletion

Business Central deletes the Purchase Order **header** entirely once
all lines are fully received and invoiced (no lines remain to justify
keeping it). `AssessPurchaseOrder` checks `PurchaseHeader.Find()`
before writing the cached fields — the audit record is always written
regardless; only the live-cache update is conditionally skipped when
there is no longer a header to cache onto.

## Administrative Closure

A vendor shortfall that will never be fully delivered is closed, in
standard Business Central practice, by reducing the order line's
`Quantity` to match what was actually received — zeroing the
outstanding amount without receiving anything further.

This is hooked via `Purchase Line`'s auto-published
`OnAfterValidateEvent` for the `Quantity` field — a platform mechanism
that exists for any field on any table, not a custom event that had to
be discovered or guessed at. Guard conditions (something was already
received, and outstanding quantity just transitioned to zero as a
result of this specific edit) distinguish a genuine shortfall closure
from an ordinary quantity edit on a line nothing has been received
against yet.

No separate "closed" status was needed: because the matching engine
always reads `Quantity` live, re-running `AssessPurchaseOrder`
immediately after this edit naturally recalculates against the
corrected order total, and risk clears itself because the underlying
comparison is now against reality.

## Vendor Scorecard

A pure rollup over `PCX Purchase Risk Assessment` — it does not
independently re-derive matching or risk logic. If a bug is ever fixed
in the matching engine, the scorecard is automatically correct on the
next recalculation, with nothing duplicated to fix separately.

- **On-Time %** — proportion of assessments where `Overdue = false`.
- **Quantity / Price Accuracy %** — `100 − average(|variance %|)`
  across all assessments for the vendor. Absolute value is used
  deliberately: a −10% and a +10% variance are both treated as 10%
  inaccurate, rather than allowing over- and under-delivery/pricing to
  net toward zero and mask a genuinely inconsistent vendor.
- **Overall Score** — an equal, unweighted average of the three
  metrics above. Documented as a defensible default, not a claim that
  the three dimensions are inherently equally important — a
  reasonable starting point, intentionally left open to becoming a
  configurable weighting later.
- **Minimum sample size**: fewer than 5 assessments yields `Insufficient
  Data` rather than a scored rating. This is a floor against a single
  lucky-or-unlucky PO deciding a vendor's entire reputation, not a
  claim that 5 is statistically sufficient — a defensible, arbitrary
  floor, stated as such.
- **Rating bands**: Excellent ≥ 90, Good ≥ 75, Fair ≥ 60, else Poor.

An "Insufficient Data" vendor is rendered as visually muted/neutral in
the UI (List page, Vendor Card, printed report), not styled as
favorable or unfavorable — an unrated vendor is a genuinely different
kind of unknown than a known-poor one, and the two should not look
alike.

## Dashboard Cue

Tiles count `Purchase Header` directly, filtered on the cached current
fields — **not** the assessment history table. Counting the history
table would count *events* (a PO reassessed five times counted five
times), when the dashboard needs *current open problems* (that same PO
counted once). Each tile's drill-down opens a `Purchase Order List`
pre-filtered to that exact condition (`SetTableView`), rather than an
unfiltered list, since a manager clicking a risk count wants to act on
those specific orders.

The Overdue tile initially approximated overdue status via risk level
(`<> Low`) before `PCX Currently Overdue` existed as its own cached
boolean field — that approximation was corrected once the real field
was added, since risk level and overdue status are genuinely different
facts that happened to often coincide in early testing data.

## Reporting

`PCX Purchase Risk Summary` combines two independent dataitems (open
risk orders, vendor scorecards) into one document rather than two
separate reports, since they're naturally two sections of one
procurement review artifact. A separate detailed audit-trail report
was deliberately not built — the `PCX Purchase Risk List` page already
serves that browsing need, and duplicating it as a second report would
exist mainly for symmetry with the companion project rather than
genuine need.

The report's minimum-risk-level filter (`PCX Risk Report Mgt.
ApplyMinimumRiskFilter`) uses `Enum.AsInteger()` with a `>=` comparison
against `PCX Risk Level`'s ordinal value. This only works correctly
*because* the enum's `value()` declarations were written in ascending
severity order (`Low = 0` through `Critical = 3`) — a dependency worth
remembering if this enum is ever extended, since inserting a new value
out of severity order would silently break this filter without a
compile error.

The dynamic report heading (reflecting the selected minimum risk
level) is built in `OnPreReport` via `StrSubstNo` and exposed as an
ordinary report column, since Word layouts have no separate
"report title" binding mechanism outside the dataset itself.

## A Real Business Central Test-Isolation Discovery

During development of the administrative-closure feature, an
automated test appeared to show that a freshly posted receipt's data
was invisible to the risk engine — `SumReceivedQuantity` returning `0`
immediately after `PostPurchaseDocument` completed within the same
test method, even reading directly from `Purch. Rcpt. Line` with a
plain `FindSet`, not just an aggregate `CalcSums`.

Extensive isolation testing (documented step by step in this project's
commit history) confirmed the root cause: **Business Central's
`Purch.-Post` posting routine relies on internal `Commit()` calls that
are suppressed under the automated test framework's default transaction
isolation** (`TransactionModel`/`TestIsolation` — a test's changes are
rolled back at the end by design, and an explicit `Commit()` inside a
test either fails outright or is a no-op depending on the model in
use). Data that a live post genuinely commits mid-transaction is
therefore not reliably visible to a subscriber reading it back within
the same still-open test transaction — even though the identical code
path works correctly in real, live posting through the Web Client
(confirmed by manually creating and posting real purchase orders and
observing correct risk transitions throughout).

**This is a test-environment limitation, not a defect in the
extension.** The matching and scoring logic itself
(`EvaluateReceiptMatch`, `EvaluateInvoiceMatch`, `EvaluateThreeWayMatch`,
`DetermineRiskLevel`) is fully, independently unit-tested by calling
these procedures directly against data constructed via Microsoft's
`Library - Purchase`/`Library - Inventory` test toolkit — none of that
coverage depends on live, subscriber-triggered posting visibility.
What specifically cannot be automated under default test isolation is
asserting that the Purchase Header's *cached fields* update correctly
in the same test transaction, immediately following a posted
receipt/invoice fired through the live event subscriber. That specific
behavior was verified manually instead, directly against real posted
purchase orders in the Web Client.

Two things attempted and reverted during this investigation, kept here
because ruling them out was itself informative: switching `CalcSums`
calls to manual `FindSet`/`Next` accumulation, and switching from the
document-level `OnAfterPostPurchaseDoc` event to the line-level
`OnAfterPurchRcptLineInsert` event. Neither resolved the symptom, which
ruled out SIFT-index staleness and event-timing-within-posting as
explanations, and pointed conclusively at test-transaction commit
suppression as the actual cause.

## Housekeeping: Namespace Correction

Every namespace in this project was originally declared as
`WarehouseControl.Purchasing` (and `.Test`) — carried over from the
companion warehouse project's convention, where it made sense as a
shared root for sibling concerns within one app. Since this project is
its own standalone extension with an independent `app.json`/GUID, that
namespace root didn't semantically describe this app on its own
merits. Corrected to `PurchaseControl.Purchasing` (and
`PurchaseControl.Purchasing.Test`) across every `.al` file in a single
isolated commit, with no functional change — object names, IDs,
fields, and behavior are unaffected by a namespace rename.

## Permissions

Two permission sets, `PCX Purchase Risk User` (read-only on the audit
trail and scorecard) and `PCX Purchase Risk Manager` (adds
insert/modify on the assessment table's `Notes` field and full control
of the scorecard cache). Deliberately, **no permission set grants
delete** on `PCX Purchase Risk Assessment` — every row is written
exclusively by `AssessPurchaseOrder`, and unlike the companion
project's resolvable exceptions, there is no legitimate reason for any
user, including a manager, to delete a historical risk-assessment
record. The audit trail is permissions-enforced as append-only.