# Financial Reports – Dynamic Integration

This document describes the dynamic data integration for the Financial Reports feature, covering frontend components, analytics hooks, backend endpoints consumed, export behavior, audit logging, and known limitations.

## Overview

- Component: `frontend/src/pages/accounting/component/financial-reports.tsx` (export: `FinancialReportsEnhanced`)
- Goal: Remove all simulated/static data, wire all charts/tables to backend APIs via analytics + statements hooks, add robust null/error handling, and log audit trail for report generation and exports.

## Data Sources (Backend)

- Financial statements: `GET /api/v2/accounting/financial-statements`
  - Query: `type` ('BALANCE_SHEET'|'INCOME_STATEMENT'|'CASH_FLOW'), `startDate?`, `endDate?`, `format?` ('summary'|'detailed'), `includeComparativePeriod?`
- Financial summary: `GET /api/v2/accounting/financial-summary`
  - Query: `period?`, `includeRatios?`, `includeComparison?`
- Advanced analytics: `GET /api/v2/accounting/analytics/advanced`
  - Used analytic types:
    - `revenue-analysis`
    - `expense-analysis`
    - `cash-flow`
    - `budget-performance`
  - Common query params: `startDate?`, `endDate?`, `period?` ('daily'|'weekly'|'monthly'|'quarterly'|'yearly'), `compareWithPrevious?`
- Journal entries (for compliance metrics): `GET /api/v2/accounting/journal-entries`
- Audit trail: `POST /api/v2/accounting/audit-trail` (recommended; see Audit Trail section)

Auth and tenancy
- Include auth token in headers.
- Include `x-tenant-tag` where applicable.

## Frontend Hooks

Defined in `frontend/src/hooks/useAccounting.ts`:

- `useFinancialStatements(params)`
- `useFinancialSummary(asOfDate)`
- `useRevenueAnalytics(params)`
- `useExpenseAnalytics(params)`
- `useCashFlowAnalytics(params)`
- `useBudgetPerformanceAnalytics(params)`
- `useJournalEntries(params)`

Analytics params (example)
```ts
const analyticsParams = {
  startDate: '2025-01-01',
  endDate: '2025-09-30',
  period: 'monthly' as const,
  compareWithPrevious: true,
}
```

## UI Tabs and Data Binding

- Balance Sheet
  - Uses `useFinancialStatements({ type: 'BALANCE_SHEET', asOfDate, format, includeComparativePeriod })`.
  - The statement section renders BIR-compliant headings and figures. When comparative data is present, the UI shows current vs previous period.
  - The comparison chart (`BarChart`) is derived from statement totals with fallback to `useFinancialSummary` when statements are unavailable.

- Income Statement
  - Summary totals are from `useFinancialSummary`.
  - Trend chart is analytics-driven (`revenue-analysis` + `expense-analysis`) combined as `revenueExpenseData`.

- Cash Flow
  - Summary cards use `useCashFlowAnalytics` totals (inflow, outflow, netFlow) and `useFinancialSummary` for cash at end.
  - Projection chart uses analytics series (`cashFlow.current[]`) mapped to `{ month, inflow, outflow, netFlow }`.
  - Cash Conversion Cycle (CCC) and Free Cash Flow (FCF) are placeholders pending backend support; UI shows "Pending analytics support".

- Budget Variance
  - Uses `useBudgetPerformanceAnalytics`:
    - Summary cards: total budgeted, total actual, variance, variance%.
    - Department performance (`BarChart`) and detailed variance table.

- Compliance
  - Derived client-side compliance metrics:
    - Journal posting rate from `useJournalEntries` (posted vs total).
    - Budget utilization from `useBudgetPerformanceAnalytics` totals.
    - Ratios (current ratio, debt-to-equity) from `useFinancialSummary`.
  - Compliance checklist is hidden with a placeholder until backend endpoints are ready.

## Exports

- PDF: `jsPDF` + `html2canvas`
- Excel/CSV: `XLSX` + `file-saver`
- Exports reflect the current dynamic state of charts/tables.
- Export coverage per tab:
  - Balance Sheet: BIR-style table from `useFinancialStatements` with comparative columns when available; summary fallback via `useFinancialSummary`.
  - Budget Variance: department performance list with variance%.
  - Trend/Analytics: revenue vs expenses with net income.

## Audit Trail

- Actions logged:
  - `GENERATE_REPORT` — when the user generates a report.
  - `EXPORT_PDF`, `EXPORT_EXCEL`, `EXPORT_CSV` — when exporting.
  - `CHANGE_REPORT_TYPE`, `CHANGE_COMPARISON`, `NAVIGATE_TAB` — key UI interactions.
- Recommended API: `POST /api/v2/accounting/audit-trail` with `{ action, module: 'FINANCIAL_REPORTS', details, metadata }`.
- Current implementation in `financial-reports.tsx` logs locally for demo; wire this to the Audit Trail API in production.

## Error, Empty, and Loading States

- All charts/tables have explicit fallbacks:
  - Loading spinners (`Loader2`) on major sections.
  - "No data available" messages when series/arrays are empty.
  - Guard against divide-by-zero for ratios; show `N/A` or `0.0%` accordingly.

## Security Considerations

- All hooks rely on shared fetch utilities injecting auth tokens.
- Respect multi-tenancy headers.

## Known Limitations / Pending APIs

- CCC and FCF metrics require backend analytics; currently show placeholders.
- Compliance checklist is hidden until endpoints exist.
- "Consolidated" format is reserved; current FE treats unknown formats as `'summary'` for stability.

## Developer Notes

- Prefer `useMemo` for computed series to prevent re-renders.
- Keep analytics params stable; avoid using a moving `now` in query keys.
- Ensure numbers are cast via `Number(...)` for Decimal values before calculations.

## QA Checklist

- Verify each tab across date ranges: current month, quarter, YTD, fiscal year, and custom.
- Turn on comparison modes: previous period, previous year, budget.
- Validate exports contain accurate dynamic values and appropriate column headers.
- Inspect audit trail entries created for generation and export actions.
- Exercise empty/error states by forcing network errors or using empty datasets.
