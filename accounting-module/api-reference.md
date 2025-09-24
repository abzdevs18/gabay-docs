# Accounting Module – API Reference (v2)

Base path: `/api/v2/accounting`

Conventions
- Authentication: all routes invoke `authenticate(req)`. Provide a valid bearer token.
- Multi-tenancy: pass `x-tenant-tag` header when applicable.
- Pagination: common query params `page`, `limit`. Responses often include `{ pagination: { page|currentPage, limit, totalCount, totalPages, hasNext|hasNextPage, hasPrev|hasPrevPage } }`.
- Dates: ISO 8601 strings in requests; many endpoints coerce to `Date`.
- Numeric fields: Prisma `Decimal` values are converted to JS numbers at the API boundary where noted.
- Errors: Validation errors use Zod with `details` containing per-field issues.

---

## Journal Entries

- GET `/journal-entries`
  - Query: `status` (DRAFT|POSTED|CANCELLED), `source` (TransactionSource), `accountCode`, `dateFrom`, `dateTo`, `search`, `page`, `limit`
  - Response: `{ success, data }` where `data` contains entries and pagination as returned by `AccountingService.getJournalEntries`

- POST `/journal-entries`
  - Body: `{ date: string|Date, description: string, reference?: string, source?: TransactionSource, sourceId?: string, lineItems: Array<{ accountId: string, description: string, debitAmount?: number, creditAmount?: number, reference?: string }>, metadata?: Record<string, any> }`
  - Constraints: at least 2 line items; each line must have either debit or credit (exclusive); non-negative amounts.
  - Response: `{ success, data }` with created JE (status `DRAFT`)

- GET `/journal-entries/pending`
  - Query: `page`, `limit`, `sortBy` (default createdAt), `sortOrder` (asc|desc), `dateFrom`, `dateTo`, `createdBy`
  - Behavior: returns only `DRAFT` entries not created by the current user (SoD)
  - Response: `{ success, data: { journalEntries: Array<{ id, journalNumber, date, description, reference, totalDebit, totalCredit, calculatedTotalDebit, calculatedTotalCredit, isBalanced, status, source, sourceId, createdAt, createdBy: { id, name, email }, lineItems: [...], metadata, validation: { hasValidLineItems, isBalanced, hasValidAmounts } }>, pagination } }`

- POST `/journal-entries/[id]/approve`
  - Body: `{ action: 'APPROVE' | 'REJECT', approvalNotes?: string, rejectReason?: string }`
  - Behavior on APPROVE: validates debits==credits within 0.01; validates exclusive debit/credit per line; creates GL entries and updates account balances; sets status to `POSTED`.
  - Behavior on REJECT: sets status to `CANCELLED`.
  - Response: `{ success, message, data: { id, journalNumber, status, approvedBy, approvedAt, totalDebit, totalCredit } }`

- GET/PUT/DELETE `/journal-entries/[id]`
  - Note: placeholders in current code; not implemented yet.

Notes
- Journal entries are created as `DRAFT` and become `POSTED` on approval or `CANCELLED` on rejection. Only `POSTED` affects GL.

---

## General Ledger

- GET `/general-ledger`
  - Query: `accountCode`, `accountType` (ASSET|LIABILITY|EQUITY|REVENUE|EXPENSE), `dateFrom`, `dateTo`, `search`, `page`, `limit`
  - Response: `{ success, data }` from `AccountingService.getGeneralLedger`

---

## Trial Balance

- GET `/trial-balance`
  - Query: `asOfDate?`, `accountType?`, `includeZeroBalances?` (boolean), `format` ('summary'|'detailed')
  - Response: `{ success, data: { trialBalance: Array<{ accountCode, accountName, debitBalance?, creditBalance? }>, format, asOfDate, summary: { totalDebits, totalCredits, accountCount } } }`

---

## Financial Statements and Summary

- GET `/financial-statements`
  - Query: `type` ('BALANCE_SHEET'|'INCOME_STATEMENT'|'CASH_FLOW'), `startDate?`, `endDate?`, `format?` ('summary'|'detailed'), `includeComparativePeriod?` (boolean)
  - Response: `{ success, data }` (service-computed statement)

- GET `/financial-summary`
  - Query: `period` ('current_month'|'current_quarter'|'current_year'|'ytd'), `includeRatios?` (boolean), `includeComparison?` (boolean)
  - Response: `{ success, data }`

---

## Chart of Accounts

- GET `/chart-of-accounts`
  - Query: `accountType?`, `isActive?` (boolean), `parentAccountId?`, `search?`, `page?`, `limit?`
  - Response: `{ success, data: accounts[] }` (filtered active/inactive)

- POST `/chart-of-accounts`
  - Body: `{ accountCode: 'dddd', accountName: string, accountType: AccountType, parentAccountId?: string, description?: string, isActive?: boolean }`
  - Normal balance is inferred from accountType (Assets/Expenses = DEBIT; others = CREDIT)
  - Response: `{ success, data }`

- GET `/chart-of-accounts/[id]`
  - Response: `{ success, data }` or 404

- PUT `/chart-of-accounts/[id]`
  - Body: `{ accountName?, description?, isActive?, parentAccountId? }`
  - Response: `{ success, data }`

- DELETE `/chart-of-accounts/[id]`
  - Behavior: soft delete (deactivate)
  - Response: `{ success, message, data }`

Note: Some ID validators use `uuid()`; elsewhere the system accepts `cuid`. Align callers accordingly.

---

## Budgets

- GET `/budgets`
  - Query: `fiscalYear?`, `status?` ('DRAFT'|'PENDING_APPROVAL'|'APPROVED'|'ACTIVE'|'CLOSED'), `search?`, `page?`, `limit?`
  - Response: `{ success, data }`

- POST `/budgets`
  - Body: `{ name, description?, fiscalYear, startDate, endDate, totalBudget, budgetItems: Array<{ accountId: string, budgetedAmount: number, category?, notes? }> }`
  - Response: `{ success, data }`

- GET `/budgets/pending`
  - Query: `fiscalYear?`, `page?`, `limit?`
  - Behavior: returns pending approvals excluding creator (SoD)
  - Response: `{ success, data }`

- GET `/budgets/[id]`
  - Response: `{ success, data }` or 404

- PUT `/budgets/[id]`
  - Body: any of `{ name?, description?, totalBudget?, status?, budgetItems? }`
  - Response: `{ success, data }`

- DELETE `/budgets/[id]`
  - Response: `{ success, message }`

- POST `/budgets/[id]?action=approve|reject`
  - Body: `{ action: 'APPROVE'|'REJECT', notes?: string }`
  - Response: `{ success, data, message }`

- POST `/budgets/[id]?action=forecast`
  - Body: `{ method: 'linear'|'moving-avg'|'seasonal'|'custom', period: '3-months'|'6-months'|'1-year'|'2-years', customFactors?: Record<string, number> }`
  - Response: `{ success, data }`

- GET `/budgets/[id]/actuals`
  - Query: `startDate?`, `endDate?`
  - Response: `{ success, data: { items: Array<{ accountId, accountName, budgetedAmount, actualAmount, variance, percentageUsed }>, totals... } }`

- GET `/budgets/alerts`
  - Response: `{ success, data }` (service-driven alerts)

- POST `/budgets/alerts`
  - Body: alert thresholds
  - Response: `{ success, message, data }`

---

## Receivables (Invoices)

- GET `/receivables`
  - Query: `search?`, `status?` ('UNPAID'|'PARTIALLY_PAID'|'PAID'|'PAYMENT_RECEIVED'), `studentId?`, `page?`, `limit?`, `dateFrom?`, `dateTo?`
  - Response: `{ success, data: { receivables: [...], summary, pagination } }`

- POST `/receivables`
  - Body: `{ studentId: string, invoiceNumber?: string, amount: number, dueDate: string|Date, description: string, metadata?: Record<string, any> }`
  - Behavior: creates invoice; attempts to create AR/Revenue journal entry (continues even if JE fails)
  - Response: `{ success, data: invoice }`

- GET `/receivables/[id]`
  - Response: `{ success, data: { ...invoice, balance, totalPaid, daysPastDue, isOverdue } }`

- PUT `/receivables/[id]`
  - Body: `{ amount?, dueDate?, status?, metadata? }` (cannot reduce amount below total paid; may create adjustment JE)
  - Response: `{ success, data }`

- DELETE `/receivables/[id]`
  - Behavior: only when no completed payments; creates reversal JE
  - Response: `{ success, message }`

---

## Vendors & Accounts Payable

- GET `/vendors`
  - Query: `search?`, `vendorType?`, `isActive?` (boolean), `page?`, `limit?`
  - Response: `{ success, data: { vendors: [...with invoiceCount], pagination } }`

- POST `/vendors`
  - Body: vendor info (name, contact, email, terms, type, etc.)
  - Response: `{ success, data }`

- GET `/vendors/[id]`
  - Response: `{ success, data: { vendor, statistics } }`

- PUT `/vendors/[id]`
  - Body: updates with validation (duplicate name check)
  - Response: `{ success, data }`

- DELETE `/vendors/[id]`
  - Behavior: soft delete (isActive=false); blocked if pending/approved invoices exist
  - Response: `{ success, message, data }`

Vendor Invoices
- GET `/vendors/invoices`
  - Query: `status?` ('PENDING'|'APPROVED'|'REJECTED'|'PAID'|'OVERDUE'), `vendorId?`, `departmentId?`, `budgetCategory?`, `dueDateFrom?`, `dueDateTo?`, `amountMin?`, `amountMax?`, `search?`, `page?`, `limit?`
  - Response: `{ success, data: { invoices, pagination } }`

- POST `/vendors/invoices`
  - Body: `{ vendorId, invoiceNumber, description, amount, dueDate, departmentId?, budgetCategory, poNumber?, attachments?, lineItems?, notes? }`
  - Behavior: creates vendor invoice (status=PENDING) and attempts AP journal entry; logs audit trail.
  - Response: `{ success, data: invoice }`

- PUT `/vendors/invoices?invoiceId=...`
  - Body: `{ action: 'APPROVE'|'REJECT', notes?, budgetCategory? }`
  - Behavior: SoD (cannot approve own); updates status and logs audit trail.
  - Response: `{ success, data }`

- POST `/vendors/invoices/[id]/approve`
  - Body: `{ action: 'APPROVE'|'REJECT', approvalLevel: 'DEPARTMENT'|'FINANCE'|'TREASURER', notes?, rejectionReason?, scheduledPaymentDate? }`
  - Response: `{ success, data: { invoice, approval }, message }`

- POST `/vendors/invoices/[id]/schedule-payment`
  - Body: `{ paymentMethod, scheduledDate, amount, notes?, poNumber?, receivingNumber?, authorizedBy, authorizationCode?, bankAccount?, checkDetails? }`
  - Preconditions: invoice must be `APPROVED`; SoD enforced; prevents over-scheduling vs remaining balance.
  - Response: `{ success, message, data: { scheduledPayment, invoice: { id, invoiceNumber, remainingBalance } } }`

---

## Bank Reconciliation

- GET `/bank-reconciliation`
  - Query: `bankAccountId?`, `status?`, `dateFrom?`, `dateTo?`, `page?`, `limit?`
  - Response: `{ success, data: { reconciliations: [...numbers coerced], pagination } }`

- POST `/bank-reconciliation`
  - Body: `{ bankAccountId, statementDate, statementBalance, statementReference, bankStatementFile? }`
  - Response: `{ success, data }`

- GET `/bank-reconciliation/[id]`
  - Response: `{ success, data: { reconciliation: {...}, unreconciledTransactions: [...] } }`

- PUT `/bank-reconciliation/[id]`
  - Body: `{ status?: 'PENDING'|'IN_PROGRESS'|'COMPLETED'|'CANCELLED', adjustmentAmount?, notes?, approvedBy? }`
  - SoD: creator cannot mark COMPLETED
  - Response: `{ success, data }`

- POST `/bank-reconciliation/[id]`
  - Body: `{ items: Array<{ transactionId: string, isMatched: boolean, bankTransactionReference?, adjustmentAmount?, notes? }> }`
  - Behavior: upserts reconciliation items; transitions status to IN_PROGRESS if PENDING; logs audit.
  - Response: `{ success, data: { processedItems, items } }`

- DELETE `/bank-reconciliation/[id]`
  - Behavior: not allowed if COMPLETED; SoD and role checks applied.
  - Response: `{ success, message }`

Import & Matching
- POST `/bank-reconciliation/import`
  - Body: `{ bankAccountId, statementDate, fileFormat: 'CSV'|'OFX'|'QIF', fileData: base64, mappingConfig? }`
  - Response: `{ success, message, data: { reconciliationId, summary, nextSteps } }`

- PUT `/bank-reconciliation/import`
  - Body: `{ reconciliationId, matches: Array<{ bankTransactionId, systemTransactionId?, matchType: 'EXACT'|'PARTIAL'|'MANUAL', confidence?, notes? }> }`
  - Behavior: updates reconciliation status to `READY_FOR_APPROVAL` or `REQUIRES_ADJUSTMENT` based on matches/variance.
  - Response: `{ success, message, data: { processedMatches, matchingSummary, newStatus } }`

- GET `/bank-reconciliation/analytics`
  - Query: `startDate?`, `endDate?`, `bankAccountIds?[]`, `analyticType` ('reconciliation'|'matching'|'performance'|'trends'), `period` ('daily'|'weekly'|'monthly'|'quarterly')
  - Response: `{ success, data }` with analytics series and summaries

---

## Analytics

- GET `/analytics/advanced`
  - Query: `{ startDate?, endDate?, accountTypes?[], departmentIds?[], analyticType, period, compareWithPrevious? }`
  - Response: `{ success, data: { summary, ratios, healthScore, trendAnalysis, budgetComparison, comparison?, recommendations } }` depending on analyticType

- GET `/analytics/enhanced`
  - Query: `{ timeframe, accountType?, includeForecasting?, departmentId?, compareWithPrevious? }`
  - Response: `{ success, data: { period, kpis, cashFlow, revenue, expenses, accountBalances, transactionVolume, budgetPerformance, paymentMetrics, growth, forecasting?, generatedAt } }`

---

## Dashboard

- GET `/dashboard/metrics`
  - Query: `asOfDate?`
  - Response: `{ success, data }` from `AccountingService.getDashboardMetrics`

---

## Audit Trail

- GET `/audit-trail`
  - Query: `search?`, `action?`, `module?`, `userId?`, `entityType?`, `entityId?`, `dateFrom?`, `dateTo?`, `page?`, `limit?`
  - Response: `{ success, data: { auditLogs: [...with user], summary: { topActions[], moduleActivity[], userActivity[] }, pagination } }`

- POST `/audit-trail`
  - Body: `{ action: string, module?, entityType?, entityId?, details: string, metadata? }`
  - Response: `{ success, data }`

---

## Integrations

- POST `/integrations/payment`
  - Body: `{ paymentId, amount, paymentMethod: 'CASH'|'CHECK'|'BANK_TRANSFER'|'CREDIT_CARD'|'ONLINE', studentId, feeTypeId?, description?, reference?, metadata? }`
  - Behavior: processes payment integration and creates a `DRAFT` JE (Cash/Bank DR, AR CR)
  - Response: `{ success, data, message }`

- POST `/integrations/fee-assignment`
  - Body: `{ feeId, feeTypeId, amount, studentId, dueDate?, description?, reference?, metadata? }`
  - Behavior: creates `DRAFT` JE (AR DR, Revenue CR)
  - Response: `{ success, data, message }`

---

## Related POS & Cashier Endpoints (outside accounting base path)

These endpoints live under `/api/v2/pos/transactions` but trigger Accounting integration via `AccountingService.processPosSaleIntegration`.

### POS Cash Payment

POST `/api/v2/pos/transactions/cash-payment`

Request Body:
```json
{
  "amount": 250.00,
  "items": [
    { "productId": "prod_123", "quantity": 2, "priceAtPurchase": 50.00 },
    { "productId": "prod_456", "quantity": 1, "priceAtPurchase": 150.00 }
  ],
  "terminalId": "term_abc",
  "cashierId": "user_xyz",
  "isCanteenTransaction": true,
  "customerName": "Cash Sale"
}
```

Response (excerpt):
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "pay_...",
      "createdAt": "...",
      "paidAt": "...",
      "amount": 250,
      "metadata": {
        "orNumber": "OR-...",
        "referenceNumber": "OR-...",
        "journalNumber": "JE-...",
        "paymentMethod": "CASH",
        "isCanteenTransaction": true
      },
      "status": "COMPLETED"
    },
    "receipt": { "receiptNumber": "OR-..." },
    "invoice": {
      "metadata": {
        "items": [ { "description": "Item x Qty", "amount": 100 } ]
      }
    }
  }
}
```

Accounting Side-Effect:
- Creates a `DRAFT` Journal Entry: DR Cash, CR General Revenue. Metadata includes `posTransactionId`, `orNumber`, `paymentMethod: 'CASH'`, and item summaries. Approval is required to POST to GL.

Notes:
- Requires an active cashier shift for the terminal.
- Integration failures are logged and do not block payment.

### POS Credit Payment

POST `/api/v2/pos/transactions/credit-payment`

Request Body:
```json
{
  "studentId": "stud_123",
  "amount": 250.00,
  "items": [
    { "productId": "prod_123", "quantity": 2, "priceAtPurchase": 50.00 },
    { "productId": "prod_456", "quantity": 1, "priceAtPurchase": 150.00 }
  ],
  "terminalId": "term_abc",
  "cashierId": "user_xyz",
  "isCanteenTransaction": true
}
```

Response (excerpt):
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "pay_...",
      "createdAt": "...",
      "paidAt": "...",
      "amount": 250,
      "metadata": {
        "orNumber": "OR-...",
        "referenceNumber": "OR-...",
        "journalNumber": "JE-...",
        "paymentMethod": "CREDIT",
        "isCanteenTransaction": true
      },
      "status": "COMPLETED"
    },
    "receipt": { "receiptNumber": "OR-..." },
    "invoice": {
      "metadata": {
        "items": [ { "description": "Item x Qty", "amount": 100 } ]
      }
    },
    "student": {
      "id": "stud_123",
      "previousBalance": 500,
      "newBalance": 250
    }
  }
}
```

Accounting Side-Effect:
- Creates a `DRAFT` Journal Entry: DR Student Credits Liability, CR General Revenue. This recognizes revenue at the point of sale while reducing the prepayment liability. Approval is required to POST to GL.

Notes:
- Student credit balance is tracked via transactions; sale will fail if insufficient balance.
- Integration failures are logged and do not block payment completion.

---

## Related Finance Student Fee Endpoints (outside accounting base path)

These endpoints live under `/api/v2/finance` but trigger Accounting integration via `AccountingService.processFeeAssignmentIntegration` or `AccountingService.processFeeAdjustmentIntegration`.

### Assign Existing Fee to Student

POST `/api/v2/finance/student/[studentId]/assign-individual-fee`

Request Body:
```json
{ "feeId": "fee_123" }
```

Response (excerpt):
```json
{
  "success": true,
  "data": {
    "id": "studentFeeId",
    "status": "UNPAID",
    "amount": 1500,
    "balanceAmount": 1500,
    "dueDate": "2025-09-30T00:00:00.000Z"
  }
}
```

Accounting Side-Effect:
- Creates a `DRAFT` Journal Entry via `processFeeAssignmentIntegration`: DR Accounts Receivable, CR Revenue (by fee type). Non-blocking on integration failure.

### Assign Custom Fee to Student

POST `/api/v2/finance/add-custom-fee/[id]`

Request Body:
```json
{
  "name": "Custom Lab Fee",
  "amount": 500,
  "isRequired": true,
  "frequency": "ONE_TIME",
  "feeTypeId": "feeType_custom"
}
```

Response (excerpt):
```json
{
  "success": true,
  "data": {
    "id": "studentFeeId",
    "name": "Custom Lab Fee",
    "amount": 500,
    "balanceAmount": 500,
    "status": "UNPAID",
    "frequency": "ONE_TIME",
    "feeTypeId": "feeType_custom"
  }
}
```

Accounting Side-Effect:
- Creates a `DRAFT` Journal Entry via `processFeeAssignmentIntegration`: DR Accounts Receivable, CR Revenue. Non-blocking on integration failure.

### Update Student Fee (Amount/Discount)

PUT `/api/v2/finance/update-fee/[id]`

Request Body (example):
```json
{
  "amount": 1200,
  "discount": { "type": "percentage", "value": 10, "reason": "Sibling" }
}
```

Response (excerpt):
```json
{
  "success": true,
  "data": {
    "id": "studentFeeId",
    "amount": 1200,
    "balanceAmount": 1080,
    "discount": { "type": "percentage", "value": 10, "amount": 120, "reason": "Sibling" }
  }
}
```

Accounting Side-Effect:
- Computes delta between previous final amount and new final amount (final = amount − discount) and creates a `DRAFT` adjustment Journal Entry via `processFeeAdjustmentIntegration`:
  - Increase: DR Accounts Receivable, CR Revenue
  - Decrease: DR Revenue, CR Accounts Receivable
- Non-blocking on integration failure; errors are logged with context.

### Process Student Fee Payment

POST `/api/v2/finance/process-payment`

Notes:
- This endpoint uses `PaymentService.processPayment(...)` which internally calls `AccountingService.processPaymentIntegration(...)` after successful payment creation.
- Accounting Side-Effect: Creates a `DRAFT` Journal Entry: DR Cash/Bank, CR Accounts Receivable. Requires approval to POST to GL.

---

## Workflow Compliance

- GET `/workflow-compliance`
  - Dashboard data with pending counts and compliance metrics (cached)

- GET `/workflow-compliance?action=pending`
  - Pending approvals list (excludes creator)

- GET `/workflow-compliance?action=templates`
  - Workflow templates with steps

- POST `/workflow-compliance?action=templates`
  - Create workflow template

- PUT `/workflow-compliance?action=templates&id=:id`
  - Update workflow template (replaces steps)

- DELETE `/workflow-compliance?action=templates&id=:id`
  - Delete workflow template

- GET `/workflow-compliance?action=metrics`
  - Compliance metrics (cached)

- POST `/workflow-compliance?action=delegations`
  - Create approval delegation

- GET `/workflow-compliance?action=delegations`
  - List delegations for current user

- POST `/workflow-compliance?action=approve&type=:type&id=:id`
  - Process approval action for `vendor-invoice` or `journal-entry` (SoD enforced)

---

## Notes for Consumers

- Journal entry statuses are Prisma-backed: `DRAFT|POSTED|CANCELLED|(REVERSED)`. UI concepts like `PENDING_APPROVAL|APPROVED|REJECTED` should map to these; only `POSTED` impacts GL.
- Many responses include nested entities; numeric fields from Decimal should be cast via `Number()` on the client if not already.
- For bulk reads, some endpoints return computed fields (e.g., `isBalanced`, `calculatedTotalDebit`). Prefer those for UI indicators.
- Always include `x-tenant-tag` for multi-tenant contexts.
