# Business Central Purchase Control

Purchase order risk detection and 3-way match validation for Dynamics 365 Business Central.

## Business Problem

Procurement teams using Business Central have no built-in, automatic
way to see when a purchase order's actual receipt or invoice diverges
from what was ordered: quantity shortfalls, price discrepancies, or
orders that are simply overdue. These issues are usually noticed
manually, after the fact, during month-end reconciliation or an audit.

## Solution

This extension assesses purchase order risk automatically as real
procurement events happen (release, receipt, and invoice posting). It
keeps both a live risk indicator on the purchase order itself and a
full historical audit trail of every assessment.

- **Automatic 3-way match validation** (PO vs. receipt vs. invoice),
  via event subscribers on standard posting codeunits. Invoice prices
  are compared line by line for the quantity actually invoiced, so
  partial invoicing is never mistaken for a price discrepancy
- **Variance-based risk scoring**, not fixed thresholds. Quantity and
  price mismatches are weighted by how severe they actually are, and a
  dual mismatch escalates beyond either one alone
- **Vendor Scorecard rollup**, rating vendor reliability across
  on-time delivery, quantity accuracy, and price accuracy, with a
  minimum-sample-size guard against rating a vendor on too little
  history
- **Administrative-closure handling**: risk clears correctly when a
  shortfall is deliberately accepted and the order is closed, instead
  of staying flagged indefinitely
- **Full audit trail** of every risk assessment, with de-duplication
  of the redundant re-releases Business Central triggers during posting
- **Reporting and dashboard**: a Word-based Purchase Risk Summary
  report, a Role Center cue, and live risk indicators on the Purchase
  Order and Vendor Card pages
- **Automated test coverage**, including regression tests for several
  non-obvious Business Central platform behaviors discovered during
  development

## Architecture

See [docs/architecture.md](docs/architecture.md) for the reasoning
behind the risk model, the matching engine, and the platform behaviors
this project uncovered.

## Technologies

- Microsoft Dynamics 365 Business Central (AL)
- Visual Studio Code + AL Language extension
- Docker (local development container)
- Microsoft's `Library - Purchase` / `Library - Inventory` test
  toolkit for realistic automated test data

## Project Structure

```
src/            Extension objects (tables, pages, codeunits, reports, permissions)
test/           Automated test codeunits
docs/           Architecture and design documentation
```

## Key Features

| Feature | Objects |
|---|---|
| Risk assessment | `PCX Purchase Risk Assessment`, `PCX Purchase Risk Mgt`, `PCX Event Subscribers` |
| Vendor reliability | `PCX Vendor Scorecard`, `PCX Vendor Scorecard Mgt` |
| Dashboard | `PCX Purchase Risk Cue`, Role Center extension |
| Standard page integration | Purchase Order / Vendor Card extensions |
| Reporting | `PCX Purchase Risk Summary`, `PCX Risk Report Mgt` |
| Security | `PCX Purchase Risk User`, `PCX Purchase Risk Manager` permission sets |

## Testing

Run the tests with the VS Code CodeLens or the AL Test Tool in your
Business Central container. They cover the matching engine (quantity,
price, partial invoicing, and the combined 3-way status), risk-level
weighting, the vendor scorecard rollup, and several real Business
Central platform behaviors discovered and documented during
development.

## Development Setup

Requires a local Business Central Docker container with the Test
Toolkit installed. See [docs/installation.md](docs/installation.md).

## Status

Complete. Project 2 of a 3-project Business Central portfolio, alongside
[business-central-warehouse-control](https://github.com/issakamo/business-central-warehouse-control)
and
[business-central-fx-integration](https://github.com/issakamo/business-central-fx-integration).