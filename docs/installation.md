# Installation & Local Development Setup

## Prerequisites

- **Docker Desktop**
- **Visual Studio Code** with the **AL Language** extension
- A Business Central Docker sandbox container, **with the Test
  Toolkit installed** (required — this project's automated tests
  depend on Microsoft's `Library - Purchase`/`Library - Inventory`
  test helper codeunits, which are not part of a default container)

## 1. Confirm or add the Test Toolkit to your container

If your container was created without the Test Toolkit, symbol
downloads for this project will fail with an error resembling:

The request for path /BC/dev/packages?publisher=Microsoft&appName=Tests-TestLibraries...
failed with code NotFound. Reason: No published package matches the provided arguments.

From a **host-machine PowerShell session** (not the container's own
Exec/console — `bccontainerhelper` cmdlets run on the host, against
the container, not inside it):

```powershell
Import-TestToolkitToBcContainer -containerName <yourContainerName>
```

**If this fails with "The tenant 'default' is not accessible"** — this
is a known, occasionally flaky timing issue where the tenant reports
`Operational` but isn't fully mounted yet. Try, in order:

```powershell
Restart-BcContainer -containerName <yourContainerName>
# wait a minute, then retry Import-TestToolkitToBcContainer
```

Check `Get-BcContainerTenants -containerName <yourContainerName>` —
if `TenantDataVersion` still shows `Uninitialized` after a restart, a
full container restart (not just the NAV service) resolved it during
this project's own setup.

## 2. Clone the repository

```bash
git clone https://github.com/issakamo/business-central-purchase-control.git
cd business-central-purchase-control
```

## 3. Configure local launch settings

`launch.json` is not committed (it holds container connection
details). Copy the example and fill in your own values:

```bash
cp launch.json.example .vscode/launch.json
```

## 4. Download symbols

With the container running (Test Toolkit installed) and `launch.json`
configured: `Ctrl+Shift+P` → **AL: Download Symbols**. This pulls Base
Application, System Application, `Library Assert`, and
`Tests-TestLibraries` — all four are declared as dependencies in
`app.json`.

## 5. Publish the extension

`Ctrl+Shift+P` → **AL: Publish** (or F5).

## 6. Generate test data manually (no dev sample-data generator)

Unlike the companion warehouse project, this project has no in-app
"generate sample data" action. Realistic test data is created two
ways:

- **For automated tests** — via `PCX Purchase Test Library`, which
  wraps Microsoft's `Library - Purchase`/`Library - Inventory` test
  codeunits to construct valid vendors, items, and purchase documents
  in code.
- **For manual verification in the Web Client** — create a real
  Purchase Order by hand: order a quantity, release it, receive a
  partial or full quantity, invoice at the same or a different price,
  and observe the `Risk Level`/`3-Way Match Status` fields on the
  Purchase Order page update. See `docs/architecture.md` for why some
  behaviors (specifically, header-cache updates immediately following
  a posted document within the same automated test) can only be
  reliably verified this way rather than through an automated test.

## 7. Run automated tests

Open any file under `test/Codeunits/` and use the **Run Test**
CodeLens above the codeunit or an individual test procedure, or use
the **Test Tool** page inside the Business Central Web Client.

## Troubleshooting

- **Missing `Tests-TestLibraries` / `Library Assert` after symbol
  download** — the Test Toolkit isn't installed in this container;
  see Step 1.
- **A test assertion involving mid-posting data (a subscriber reading
  a just-posted document within the same test) fails unexpectedly** —
  this may be the documented test-transaction commit-suppression
  behavior described in `docs/architecture.md`, not a real defect.
  Verify manually in the Web Client before assuming a regression.
- **Event subscriber appears to have no effect** — event signatures
  are version-sensitive. Verify the subscriber's parameter list
  matches the publisher's actual signature in your container's
  symbols (Go to Definition on the base app codeunit/table) before
  assuming application logic is at fault.
