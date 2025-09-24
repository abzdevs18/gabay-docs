# Accounting Module – Frontend (Next.js) Documentation

This document describes the frontend portion of the Accounting Module: pages, key components, data-fetching strategy, UX conventions, and integration points with backend APIs. All paths are relative to `frontend/`.

## Structure

- Pages directory
  - `src/pages/accounting/`
    - `dashboard.tsx` – entry to Treasurer view
    - `component/` – feature components (see below)
    - `fees/` – fee-related pages

- Feature components directory
  - `src/pages/accounting/component/`
    - `treasurer-dashboard.tsx` – orchestrates accounting views
    - `journal-entry-approval.tsx` – pending approvals workflow
    - `general-ledger.tsx` – GL viewer with filters
    - `financial-reports.tsx` – financial statements & summary
    - `chart-of-accounts.tsx` – COA viewer/editor
    - `payment-integration.tsx` – test/trigger integration flows
    - `accounts-receivable.tsx`, `accounts-payable.tsx`
    - `budgeting-forecasting.tsx`, `budget-approval.tsx`
    - `bank-reconciliation.tsx`
    - `audit-trail.tsx`, `workflow-compliance.tsx`
    - `advanced-analytics.tsx`, `accounting-dashboard.tsx`, `dashboard-overview.tsx`

## Treasurer Dashboard

File: `src/pages/accounting/component/treasurer-dashboard.tsx`

- Concern: top-level layout for Treasurer. Renders the selected view via an internal `renderContent()` switch.
- Consumes backend metrics (`/api/v2/accounting/dashboard/metrics`) and summary endpoints to provide KPIs such as total assets, income/expense changes, pending approvals, cash ratios, and fund targets.
- Error/Loading: Uses a `StatusRequestAndResponse` component to show loading and error states.

## Journal Entry Approval UI

File: `src/pages/accounting/component/journal-entry-approval.tsx`

- Data Sources
  - Pending list: `GET /api/v2/accounting/journal-entries/pending`
    - Excludes entries created by current user (segregation of duties).
    - Supports pagination, filtering (date range, creator), and sorting.
  - Approve/Reject: `POST /api/v2/accounting/journal-entries/{id}/approve`
    - Body: `{ action: 'APPROVE' | 'REJECT', approvalNotes?, rejectReason? }`

- UI/Validation Behavior
  - Displays per-entry totals and a balance flag (debits vs credits).
  - Enforces exclusivity on amounts visually: each line shows either `debitAmount` or `creditAmount` > 0.
  - Shows creator info, date, reference, source metadata.

- Z-Index and Modals
  - Use custom modal with explicit z-index control (see Z-Index Guidance below). Avoid `shadcn` Dialog if it conflicts with dropdowns or fixed headers.

## General Ledger Viewer

File: `src/pages/accounting/component/general-ledger.tsx`

- Backed by `GET /api/v2/accounting/general-ledger` with filters like `accountId`, `dateFrom`, `dateTo`, sorting, paging.
- Shows per-line debit/credit and running balances; supports drilldowns to the related journal entry.

## Chart of Accounts

File: `src/pages/accounting/component/chart-of-accounts.tsx`

- Backed by `GET /api/v2/accounting/chart-of-accounts` and `GET /api/v2/accounting/chart-of-accounts/{id}`.
- Displays type, normal balance, current balance, parent/child relations.
- Creation/Updates are handled via service methods (ensure validations mirror Zod schemas in backend).

## Financial Reports and Summary

Files: `financial-reports.tsx`, `accounting-dashboard.tsx`

- Dynamic data integration (no simulated data):
  - Hooks: `useFinancialStatements`, `useFinancialSummary`, `useRevenueAnalytics`, `useExpenseAnalytics`, `useCashFlowAnalytics`, `useBudgetPerformanceAnalytics`, `useJournalEntries` (see `frontend/src/hooks/useAccounting.ts`).
  - Backend endpoints: `GET /api/v2/accounting/financial-statements`, `GET /api/v2/accounting/financial-summary`, `GET /api/v2/accounting/analytics/advanced`, `GET /api/v2/accounting/journal-entries`.

- Balance Sheet
  - Renders statement with BIR-compliant headings from `useFinancialStatements({ type: 'BALANCE_SHEET', ... })`.
  - Comparison chart derives current vs previous from statement totals (fallback to `useFinancialSummary` when statements are unavailable).

- Income Statement
  - Summary totals from `useFinancialSummary`.
  - Trend chart combines `useRevenueAnalytics` + `useExpenseAnalytics` into `revenueExpenseData`.

- Cash Flow
  - Summary cards from `useCashFlowAnalytics` (`inflow`, `outflow`, `netFlow`) and cash position from `useFinancialSummary`.
  - Projection chart maps analytics series to `{ month, inflow, outflow, netFlow }`.
  - Cash Conversion Cycle and Free Cash Flow show "Pending analytics support" placeholders until APIs are available.

- Budget Variance
  - Uses `useBudgetPerformanceAnalytics` for summary cards, department bar chart, and detailed variance table.

- Compliance
  - Derived client-side from `useJournalEntries` (posting rate), `useBudgetPerformanceAnalytics` (budget utilization), and `useFinancialSummary` (ratios).
  - Compliance checklist is hidden with a placeholder until backend endpoints exist.

- Exports
  - PDF via `jsPDF` + `html2canvas`; Excel/CSV via `XLSX` + `file-saver`.
  - Balance Sheet export outputs BIR-style rows (with comparative columns when present). Budget Variance exports department performance with variance%.
  - Trend/Analytics export includes period, revenue, expenses, and net income.

- Audit logging
  - Logs actions: `GENERATE_REPORT`, `EXPORT_PDF`, `EXPORT_EXCEL`, `EXPORT_CSV`, `CHANGE_REPORT_TYPE`, `CHANGE_COMPARISON`, `NAVIGATE_TAB`.
  - Recommended to POST to `/api/v2/accounting/audit-trail`; current implementation logs to local state for demo.

- Error/Empty/Loading
  - Loading spinners for heavy sections; user-friendly "No data available" fallbacks; ratio guards for divide-by-zero (show `N/A`/`0.0%`).

- Known limitations
  - CCC/FCF metrics and compliance checklist require backend support; placeholders are shown.

## Payment and Fee Integrations (UI)

File: `src/pages/accounting/component/payment-integration.tsx`

- Triggers `POST /api/v2/accounting/integrations/payment` to create a DRAFT journal entry (Cash/Bank DR, AR CR) from a payment.
- Displays request/response with structured error details (Zod validation errors included).

## Budgeting and Approval

Files: `budgeting-forecasting.tsx`, `budget-approval.tsx`

- Lists/creates budgets and supports approval workflows via `GET /api/v2/accounting/budgets`, `GET /api/v2/accounting/budgets/pending`, `GET /api/v2/accounting/budgets/{id}`.
- UI should preserve backend error details and show field-level validations for dates, amounts, and required fields.

## Bank Reconciliation

File: `bank-reconciliation.tsx`

- Integrates with `bank-reconciliation/` endpoints for importing bank statements, viewing reconciliation entries, and analytics.

## Accounts Receivable and Payable

Files: `accounts-receivable.tsx`, `accounts-payable.tsx`

- AR endpoints: `receivables/` for listing, detail, and operations.
- AP and vendor endpoints: `vendors/` subtree (invoices, analytics, scheduling payments).

## Data Fetching and State Management

- Use React Query (TanStack Query) for caching, loading/error states, retries, and stale time per view.
- Prefer query keys scoped by filters (e.g., `['je-pending', page, dateFrom, dateTo, createdBy]`).
- Hydrate Decimal to number at the UI boundary. Assure numeric calculations are done on JS numbers.

## Error Handling and UX

- Show field-level validation errors for forms. Prefer structured error payloads from backend (Zod error arrays include `path` and `message`).
- Use a banner/toast for request-level errors with a retry option.
- Preserve backend `details` where present for faster debugging.

## Accessibility and Performance

- Ensure keyboard navigation for tables and modals.
- Avoid unnecessary re-renders by memoizing rows and using stable keys.
- Paginate server-side for large datasets; stream or virtualize large tables where needed.

## Z-Index Guidance (shadcn/UI + Radix)

- Modals
  - Overlay container: `fixed inset-0 z-50` or higher.
  - Modal content: enforce `z-[9999]` when overlapping dropdowns or app headers.
- Dropdowns/Select
  - Use `z-50` or `z-[10000]` for `SelectContent` to sit above modals and sticky nav.
- Rationale
  - Avoid layering conflicts from providers and portals. Custom modal wrappers offer explicit control.

## Status and Controls in UI

- Status lifecycle
  - Draft ➜ Posted on approval; Draft ➜ Cancelled on rejection.
  - Only POSTED entries appear in official financial reports.
- Segregation of duties
  - The pending list excludes the creator’s entries. The client must rely on `/pending` route.

## Security and Multi-Tenancy

- Include tenant headers when applicable (e.g., `x-tenant-tag`) to ensure the API resolves to the correct schema.
- Include auth tokens via shared header injection middleware/hooks.

## Testing Tips

- Create test data for: balanced and unbalanced JEs, invalid accounts, and mixed debit/credit lines.
- Exercise approval edge cases: approving own entry (expect error), approving unbalanced entries (expect error), rejecting with reason.

---

## POS Integration (Canteen/Shop)

File: `frontend/src/pages/pos/index.tsx`

Behavior
- Cash flow posts to `POST /api/v2/pos/transactions/cash-payment`.
- Credit flow posts to `POST /api/v2/pos/transactions/credit-payment`.
- Both endpoints create POS transactions, payment, and receipt, then trigger `AccountingService.processPosSaleIntegration` to create `DRAFT` JEs for approval.

Payload Example (Cash)
```json
{
  "amount": 250.00,
  "items": [
    { "productId": "prod_123", "quantity": 2, "priceAtPurchase": 50.00 }
  ],
  "terminalId": "term_abc",
  "cashierId": "user_xyz",
  "isCanteenTransaction": true,
  "customerName": "Cash Sale"
}
```

Payload Example (Credit)
```json
{
  "studentId": "stud_123",
  "amount": 250.00,
  "items": [
    { "productId": "prod_123", "quantity": 2, "priceAtPurchase": 50.00 }
  ],
  "terminalId": "term_abc",
  "cashierId": "user_xyz",
  "isCanteenTransaction": true
}
```

Notes
- Resilience: UI shows success as long as payment and receipt are created. Accounting integration errors are logged server-side and do not block checkout.
- Approval: Journal Entries remain `DRAFT` until approved; only `POSTED` affects GL and reports.
- Decimal: ensure numeric amounts are treated as JS numbers in UI.
