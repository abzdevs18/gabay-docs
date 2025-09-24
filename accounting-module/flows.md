# Accounting Module – End-to-End Flows

This document explains the comprehensive business and system flows across the accounting module, from data entry to posting and reporting. It highlights segregation of duties, validations, error resilience, and how backend services and frontend components work together.

References
- Backend services: `api/src/services/accounting.service.ts`, `api/src/services/payment.service.ts`
- Backend routes: `api/src/pages/api/v2/accounting/`
- Frontend: `frontend/src/pages/accounting/` and `frontend/src/pages/accounting/component/`
- Data model: `api/prisma/schema/accounting.prisma`

## Core Flow Concepts

- __Double-entry enforcement__: Debits must equal credits within 0.01.
- __Line exclusivity__: Each journal line has either a debit or a credit (never both or neither).
- __Status lifecycle__: Journal Entries are created as `DRAFT` and become `POSTED` on approval or `CANCELLED` on rejection. Only `POSTED` impacts GL and financials.
- __Segregation of duties__: Approver must not be the creator. Pending lists exclude the current user’s own `DRAFT` entries.
- __Decimal handling__: Convert Prisma `Decimal` to JS `number` at API/service boundaries for UI and calculations.
- __Resilience__: Payment processing continues even if accounting integration fails; errors are logged for investigation.
- __Multi-tenancy__: Many routes resolve tenant schema via `getPrismaClient(req)` and `x-tenant-tag` headers.

---

## 1) Payment Collection ➜ Journal Entry ➜ Approval ➜ GL Posting

Actors
- __Frontend__: `payment-integration.tsx`, `treasurer-dashboard.tsx`, `journal-entry-approval.tsx`
- __Backend__: `PaymentService`, `AccountingService`
- __Routes__: `/api/v2/accounting/integrations/payment`, `/api/v2/accounting/journal-entries/pending`, `/api/v2/accounting/journal-entries/[id]/approve`

Steps
1. __Payment initiated__
   - `PaymentService.processPayment(...)` records payment, updates fee balances, creates receipt/invoice.
   - Then calls `AccountingService.processPaymentIntegration(...)` inside try/catch (errors do not block payment success).
2. __Draft Journal Entry created__ (by `AccountingService.processPaymentIntegration`)
   - Looks up Cash and AR accounts via patterns (e.g., `1010/1110` and `1020/1120`).
   - Creates a `DRAFT` JE with two lines: Cash/Bank DR, Accounts Receivable CR.
   - Metadata holds `paymentId`, `studentId`, `paymentMethod`, `feeIds`, and references OR number.
3. __Review queue__
   - Approvers open `GET /api/v2/accounting/journal-entries/pending` which returns only `DRAFT` JEs not created by them.
   - The frontend shows calculated totals and a `isBalanced` flag per JE.
4. __Approval__
   - `POST /api/v2/accounting/journal-entries/{id}/approve` with `{ action: 'APPROVE' | 'REJECT', ... }`.
   - Server validates: `DRAFT` status, segregation of duties, debits == credits, line exclusivity.
   - On `APPROVE`: creates `generalLedgerEntry` per line and updates `chartOfAccount.balance` by `(debit - credit)` respecting normal balances. Status set to `POSTED`.
   - On `REJECT`: status set to `CANCELLED` with audit metadata.

Error Handling
- Payment ➜ Accounting integration errors are logged (`PaymentService`) without failing the payment.
- Approval endpoint returns structured errors with clear messages for unbalanced entries or SoD violations.

---

## 2) Fee Assignment ➜ Journal Entry ➜ Approval

Actors
- __Frontend__: Fee assignment screens.
- __Backend__: `AccountingService.processFeeAssignmentIntegration`
- __Route__: `POST /api/v2/accounting/integrations/fee-assignment`

Steps
1. Fee assignment triggers a `DRAFT` JE: AR DR, Revenue CR.
2. Entry appears in pending approvals list for authorized approvers (excludes creator).
3. Approval enforces the same validation and posting rules as payment JEs.

Implementation Notes
- Related finance endpoints that now trigger the same behavior automatically (outside accounting base path):
  - `POST /api/v2/finance/assign-fees` (batch assign from setup flows)
  - `POST /api/v2/finance/student/[studentId]/assign-individual-fee` (assign existing fee)
  - `POST /api/v2/finance/add-custom-fee/[id]` (assign custom fee)
- Each endpoint writes the `studentFee` record and then calls `AccountingService.processFeeAssignmentIntegration(...)` in a try/catch. Integration failures are logged and do not block the frontend operation.

---

## 3) Manual Journal Entry

Actors
- __Frontend__: Journal entry creation UI.
- __Route__: `POST /api/v2/accounting/journal-entries`

Steps
1. User submits `date`, `description`, and `lineItems` (min 2) with exclusive debit/credit amounts.
2. Server validates with Zod and additional account checks. JE stored as `DRAFT`.
3. Entry then follows the approval flow described above.

---

## 4) Accounts Receivable (Invoices)

Actors
- __Routes__: `GET/POST /api/v2/accounting/receivables`, `GET/PUT/DELETE /api/v2/accounting/receivables/{id}`
- __Backend__: Uses Prisma models for invoices and creates related JEs for AR and Revenue.

Steps
1. Creating a receivable generates an invoice (and a `DRAFT` JE for AR DR / Revenue CR).
2. Updating a receivable may create an adjustment JE if amount changes.
3. Deleting (when allowed) creates a reversal JE.

---

## 5) Budgets: Creation ➜ Pending ➜ Approval ➜ Actuals

Actors
- __Routes__: `GET/POST /api/v2/accounting/budgets`, `GET /api/v2/accounting/budgets/pending`, `GET/PUT/DELETE/POST?action=approve|reject /api/v2/accounting/budgets/{id}`, `GET /api/v2/accounting/budgets/{id}/actuals`

Steps
1. Create budget with `budgetItems` mapped to accounts. Server validates dates, IDs, and amounts.
2. Pending budgets endpoint returns items excluding creator for SoD.
3. Approval sets status and writes audit. Forecasting endpoint is available via `?action=forecast`.
4. Actuals endpoint returns budget vs. actual and variances per account.

---

## 6) Bank Reconciliation: Import ➜ Matching ➜ Status Changes

Actors
- __Routes__: `GET/POST /api/v2/accounting/bank-reconciliation`, `POST/PUT /api/v2/accounting/bank-reconciliation/import`, `GET /api/v2/accounting/bank-reconciliation/analytics`

Steps
1. Import bank statement (CSV/OFX/QIF) with mapping; parses and creates reconciliation and bank transactions.
2. System automatically matches bank transactions with GL entries (exact / partial / manual paths).
3. Matching summary determines status transitions (e.g., `DRAFT` ➜ `READY_FOR_APPROVAL` or `REQUIRES_ADJUSTMENT`).
4. Analytics endpoints provide reconciliation volume, variance, matching accuracy, and performance trends.

---

## 7) Accounts Payable (Vendors & Invoices)

Actors
- __Routes__: `GET/POST /api/v2/accounting/vendors`, `GET/PUT/DELETE /api/v2/accounting/vendors/{id}`
- __Routes__: `GET/POST/PUT /api/v2/accounting/vendors/invoices[?invoiceId=...]`

Steps
1. Create vendor invoices with details and attachments. JE for AP is created by the service layer (DR expense or asset; CR AP).
2. Approvals enforce SoD (creator cannot approve their own invoices).
3. Audit logs record creation/updates/approvals.

---

## 8) Reporting and Dashboards

Actors
- __Routes__: `GET /api/v2/accounting/financial-statements`, `GET /api/v2/accounting/financial-summary`, `GET /api/v2/accounting/dashboard/metrics`
- __Frontend__: `financial-reports.tsx`, `accounting-dashboard.tsx`, `treasurer-dashboard.tsx`

Steps
1. Financial statements support Balance Sheet, Income Statement, and Cash Flow (summary/detailed, optional comparative period).
2. Summary endpoint aggregates totals and ratios for dashboards.
3. Dashboard metrics combine pending approvals, budget utilization, liquidity ratios, and fund balances for Treasurer view.

---

## 9) Audit Trail and Governance

- __Routes__: `GET/POST /api/v2/accounting/audit-trail`
- Records key actions for compliance: JE create/approve/reject, COA updates, vendor ops, budgets.
- Entries include user, timestamp, and sanitized metadata.

---

## 10) POS Sales (Canteen/Shop): Cash and Credit

Actors
- __Frontend__: `frontend/src/pages/pos/index.tsx`
- __Backend__: `api/src/pages/api/v2/pos/transactions/cash-payment.ts`, `api/src/pages/api/v2/pos/transactions/credit-payment.ts`
- __Accounting__: `AccountingService.processPosSaleIntegration`

Validations
- Inventory availability per `POSProduct`
- For credit payments: sufficient student credit balance
- For cash payments: active cashier shift for terminal

Steps
1. __POS UI__ assembles payload with items, terminal, cashier, and for credit the student id.
2. __Backend (POS)__ validates input and domain rules, then
   - Creates `POSTransaction` and decrements inventory
   - Creates `Payment` and `PaymentReceipt`
3. __Accounting Integration__ (wrapped in try/catch; non-blocking on failure)
   - Calls `AccountingService.processPosSaleIntegration({ amount, posTransactionId, orNumber, paymentMethod, isCanteen, items, studentId? }, userId)`
   - Creates a `DRAFT` Journal Entry with lines:
     - CASH sale: DR Cash, CR General Revenue
     - CREDIT sale: DR Student Credits Liability, CR General Revenue
   - Adds metadata: `posTransactionId`, `orNumber`, `referenceNumber`, `paymentMethod`, `isCanteen`, `items`
4. __Approval__
   - Approver uses `/api/v2/accounting/journal-entries/pending` and `/api/v2/accounting/journal-entries/{id}/approve`
   - On APPROVE: GL entries are created; COA balances updated; status becomes `POSTED`

End-to-End Sequence (Cash)
```text
POS UI -> POST /api/v2/pos/transactions/cash-payment
      -> (validate shift, inventory) -> create POS transaction, payment, receipt
      -> processPosSaleIntegration (DR Cash, CR Revenue) [DRAFT]
Approver -> GET pending -> POST approve -> GL posting and balances update
```

End-to-End Sequence (Credit)
```text
POS UI -> POST /api/v2/pos/transactions/credit-payment
      -> (validate credit balance, inventory) -> create POS transaction, payment, receipt
      -> processPosSaleIntegration (DR Student Credits Liability, CR Revenue) [DRAFT]
Approver -> GET pending -> POST approve -> GL posting and balances update
```

Notes
- Integration errors are logged and do not block checkout.
- Decimal amounts are converted to JS numbers at API boundaries.
- COA setup must include Cash, General Revenue, and a Student Credits Liability account for correct mapping.

## End-to-End Sequence (Payment example)

```text
User/Cashier -> PaymentService.processPayment -> payment, receipt, invoice
                               | (try/catch)
                               v
                    AccountingService.processPaymentIntegration
                               |
                               v
                      createJournalEntry (DRAFT)
                               |
Approver -> GET /journal-entries/pending (excludes creator)
           -> POST /journal-entries/{id}/approve (APPROVE)
                               |
                               v
                   Create GL entries per line
                   Update account balances
                   Status: POSTED
```

---

## Operational Notes

- __Tenancy__: Include `x-tenant-tag` header where applicable.
- __Validation__: Prefer Zod on API routes with meaningful error payloads.
- __Transactions__: Use `$transaction(async (tx) => ...)` for multi-write consistency; prefer `Promise.all` for parallel reads.
- __Observability__: Log key steps and error contexts for integrations (payment, fee assignment, vendor).
