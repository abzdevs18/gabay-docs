# Accounting Module – Backend Architecture and Implementation

This document describes the backend accounting module: architecture, data models, key services, API contracts, validations, posting rules, and operational guidelines. All paths below are relative to the backend workspace under `api/`.

## Architecture Overview

- Service layer
  - `src/services/accounting.service.ts`
    - Core orchestration for Chart of Accounts (COA), Journal Entries (JE), General Ledger (GL), Trial Balance, Financial Statements, Dashboard metrics, and integrations.
  - `src/services/payment.service.ts`
    - Creates payments and integrates with accounting via `AccountingService.processPaymentIntegration()` with resilience (payment succeeds even if accounting integration fails; errors are logged).
- API routes (Next.js API)
  - Base path: `src/pages/api/v2/accounting/`
  - Folders: `journal-entries/`, `chart-of-accounts/`, `general-ledger/`, `trial-balance/`, `financial-statements/`, `financial-summary/`, `dashboard/`, `integrations/`, `receivables/`, `budgets/`, `bank-reconciliation/`, `vendors/`, `analytics/`, `audit-trail/`.
- Utilities
  - `src/utils/accounting.utils.ts`
    - Standard COA patterns, validation helpers, formatting, error types, mapping utilities.
- Prisma schema
  - `prisma/schema/accounting.prisma`
    - Source of truth for accounting models and enums.

## Data Model Summary (Prisma)

See `docs/accounting-module/data-model.md` for a visual and tabular description. Key models used by accounting flows:
- `ChartOfAccount`, `JournalEntry`, `JournalLineItem`, `GeneralLedgerEntry`
- `FinancialStatement`, `AuditTrail`
- Budgets: `Budget`, `BudgetItem`
- Reconciliation: `BankReconciliation`, `ReconciliationItem`

Core enum of interest: `JournalEntryStatus = DRAFT | POSTED | REVERSED | CANCELLED`.

## Key Services and Methods

File: `src/services/accounting.service.ts`

- Chart of Accounts
  - `createChartOfAccount(input, userId)`
  - `updateChartOfAccount(accountId, input, userId)`
  - `getChartOfAccounts(accountType?, includeInactive?)`
  - Validations via Zod schema (CUID-friendly with `.min(1)` for `parentAccountId`).

- Journal Entries
  - `createJournalEntry(input, userId)`
    - Validates with `validateJournalEntry()`:
      - Debits equal credits within 0.01 tolerance.
      - Each line is exclusive: either `debitAmount` or `creditAmount`, not both/neither.
      - Account existence and active status are verified.
    - Persists entry with `status: DRAFT` and line items.
    - Creates audit trail.
  - `getJournalEntries(filters)`
    - Filtering by status, source, dates, simple search, and pagination. Transforms line amounts to JS numbers.

- Ledgers and Reports
  - `getGeneralLedger(query)`
  - `getTrialBalance(query)`
  - `getFinancialStatements(options)` and `generateFinancialStatement(input)`
  - `getFinancialSummary(asOfDate)` and `getDashboardMetrics(asOfDate)`

- Integrations
  - `processPaymentIntegration(data: PaymentIntegrationData, userId)`
    - Looks up Cash and AR accounts by code/name patterns.
    - Creates a DRAFT journal entry (Cash/Bank DR, AR CR) with payment metadata.
  - `processFeeAssignmentIntegration(data: FeeAssignmentIntegrationData, userId)`
    - Creates a DRAFT journal entry (AR DR, Revenue CR) tied to fee information.

### POS & Cashier Integration (Canteen/Shop)

Files and Services
- POS endpoints (outside accounting base path):
  - `api/src/pages/api/v2/pos/transactions/cash-payment.ts`
  - `api/src/pages/api/v2/pos/transactions/credit-payment.ts`
- Accounting service method:
  - `AccountingService.processPosSaleIntegration(data, userId)`

Flow Overview
1. POS endpoint validates input, checks inventory and active shift (for cash), creates POS transaction, payment, and receipt.
2. The endpoint then calls `processPosSaleIntegration(...)` in a try/catch. Integration failures are logged and DO NOT block the sale completion.
3. `processPosSaleIntegration` creates a `DRAFT` Journal Entry with references and metadata. Approval is required to post to GL.

Journal Entry Mappings
- CASH sale (customer pays with cash):
  - Debit: Cash Account
  - Credit: General Revenue Account
- CREDIT sale (student spends pre-loaded credits):
  - Debit: Student Credits Liability Account (reduces the liability)
  - Credit: General Revenue Account

Metadata and References
- Journal description: `POS sale (Canteen)` when flagged, includes OR number
- Metadata includes: `posTransactionId`, `paymentMethod` ('CASH'|'CREDIT'), `orNumber`, `referenceNumber`, `studentId?`, `isCanteen`, `items: [{ description, amount }]`

COA Requirements and Account Resolution
- Cash Account: code patterns like `1010/1110` or name contains "Cash"
- General Revenue Account: code patterns like `4000/4100` or name contains "Revenue|Sales|Income"
- Student Credits Liability Account: a Liability account with name containing "Student|Credit|Unearned|Deferred|Deposit" or codes `2200/2300`
- Helper lookups in `AccountingService`:
  - `getCashAccountId()`, `getGeneralRevenueAccountId()`
  - `getStudentCreditsLiabilityAccountId()` – throws a helpful error if not found

Approval and Posting
- POS Journal Entries are created as `DRAFT` and require approval (segregation of duties enforced by the approval route).
- On approval, GL entries are created per line and COA balances are updated. Only `POSTED` entries affect financial reports.

Resilience and Controls
- Integration is wrapped in try/catch; failures are logged with context (amount, posTransactionId, method).
- Cash payments validate an active cashier shift on the terminal before proceeding.
- Decimal values are converted to JS numbers on API boundaries.

- Helpers (private)
  - `validateJournalEntry()`
  - `postToGeneralLedger(tx, data)` and `updateAccountBalance(tx, accountId, debit, credit)`
  - Account mapping: `getCashAccountId()`, `getAccountsReceivableAccountId()`, `getRevenueAccountId()`, `getGeneralRevenueAccountId()`

### Student Fee Integration (Assignment & Adjustments)

Files and Services
- Finance endpoints (outside accounting base path):
  - `api/src/pages/api/v2/finance/assign-fees.ts` (batch assign via setup flow)
  - `api/src/pages/api/v2/finance/student/[studentId]/assign-individual-fee.ts` (assign existing fee)
  - `api/src/pages/api/v2/finance/add-custom-fee/[id].ts` (assign custom fee)
  - `api/src/pages/api/v2/finance/update-fee/[id].ts` (edit amount/discount; triggers adjustment JE)
- Accounting service methods:
  - `AccountingService.processFeeAssignmentIntegration(data, userId)`
  - `AccountingService.processFeeAdjustmentIntegration(data, userId)`

Flow Overview
1. Finance endpoints create or update `studentFee` records inside DB transactions.
2. After successful DB operations, the endpoint calls the appropriate accounting integration in a try/catch (non-blocking on failure):
   - Assignment: `processFeeAssignmentIntegration` → creates a `DRAFT` JE (AR DR, Revenue CR).
   - Adjustment: `processFeeAdjustmentIntegration` → creates a `DRAFT` JE:
     - Increase in final amount (amount − discount): DR AR, CR Revenue
     - Decrease in final amount: DR Revenue, CR AR
3. Approvals via journal approvals route enforce SoD and posting rules; only `POSTED` JEs affect GL and reports.

Controls
- Double-entry enforced with validation; each line has either debit or credit (exclusive) and non-negative amounts.
- Account resolution uses patterns for AR (e.g., codes `1020/1120` or name contains "Receivable") and Revenue (by fee type, or general revenue fallback when implemented).
- Decimal handling: Prisma `Decimal` values are converted to JS `number` before calculations and serialization.
- Integration errors are logged with context and never block the finance operation.

File: `src/services/payment.service.ts`
- `processPayment(...)`
  - Persists payment and student fee applications, invoice, receipt, audit log.
  - Calls `AccountingService.processPaymentIntegration(...)` in a try/catch; accounting failures are logged and do not block payment success.

## Posting Rules and Approval

- Posting occurs during approval, not on creation:
  - API route: `src/pages/api/v2/accounting/journal-entries/[id]/approve.ts`
  - Preconditions
    - Entry exists and `status === DRAFT`.
    - Approver is not the creator (segregation of duties).
    - Debits equal credits within 0.01 tolerance.
    - Each line has either a debit or credit, not both/neither.
  - On APPROVE
    - Creates a `GeneralLedgerEntry` per journal line.
    - Updates `ChartOfAccount.balance` by `(debit - credit)` respecting normal balance semantics.
    - Updates status to `POSTED` and writes an `AuditTrail` record.
  - On REJECT
    - Updates status to `CANCELLED`, records audit, and preserves rejection notes/metadata.

- Pending approvals list
  - API route: `src/pages/api/v2/accounting/journal-entries/pending.ts`
  - Returns DRAFT entries not created by the current user. Includes pagination, date filters, creator filter, sorting, computed totals, and simple validation flags.

## Validation and Error Handling

- Zod schemas in `accounting.service.ts`
  - `createAccountSchema` and `createJournalEntrySchema` use `.min(1)` for CUID compatibility.
- Decimal handling
  - Convert Prisma `Decimal` to JS `number` for calculations/UI using `Number(...)` across services and route formatters.
- Error types (in `accounting.utils.ts`)
  - `AccountingError`, `JournalEntryValidationError`, `AccountNotFoundError`, `InsufficientBalanceError`.
- Logging
  - Key operations log successes/failures (e.g., payment integration, account lookups, journal creation).

## API Surface (High-Level)

See `docs/accounting-module/api-reference.md` for detailed endpoints. Key areas include:
- `journal-entries/` – list, get, pending, approve
- `chart-of-accounts/` – list, get by id
- `general-ledger/` – list/query
- `trial-balance/` – as-of
- `financial-statements/`, `financial-summary/`, `dashboard/metrics`
- `integrations/payment`, `integrations/fee-assignment`
- `receivables/`, `budgets/`, `bank-reconciliation/`, `vendors/`, `audit-trail/`, `analytics/`

## Multi-Tenancy and Clients

- Many routes use `getPrismaClient(req)` and `getTenantId(req)` to resolve tenant schema.
- Respect `x-tenant-tag` headers where applicable.

## Concurrency and Transactions

- Use `$transaction(async (tx) => { ... })` for write consistency.
- For parallel reads, prefer `Promise.all([...])` over `$transaction([])`, especially when using any Prisma proxy wrappers.

## Security and Controls

- Segregation of duties enforced at pending list and approval endpoints.
- Audit trails created for JE lifecycle changes and COA updates.
- Input validation via Zod.

## Known Status Enum Note

- Prisma `JournalEntryStatus` = `DRAFT | POSTED | REVERSED | CANCELLED`.
- TypeScript `src/types/accounting.types.ts` defines additional statuses not present in Prisma.
- Align consumers to Prisma-backed statuses or introduce a mapping layer. Only `POSTED` impacts GL and official financial reports.
