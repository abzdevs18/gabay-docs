# Gabay Accounting Module – Overview

This documentation set provides a comprehensive reference for the Accounting Module across backend (API, services, data model) and frontend (pages, components, UX) with end-to-end flows and governance (segregation of duties, audit trail, posting rules).

Contents
- backend.md — Backend architecture, services, validation, posting rules
- frontend.md — UI pages/components, UX patterns, state/data flow
- flows.md — End-to-end process flows (Payment ➜ Journal ➜ Approval ➜ GL)
- data-model.md — Prisma data model and relationships
- api-reference.md — Accounting API endpoints and contracts
- statuses-and-controls.md — Status lifecycle, segregation of duties, audit
- developer-guide.md — Setup, environment, transaction guidelines, testing
- financial-reports.md — Financial reports dynamic integration (analytics hooks, exports, audit logging)

Goals
- Ensure strong accounting controls (double-entry, approvals, audit)
- Provide consistent integration for payment/fees into accounting
- Enable accurate reporting (GL, Trial Balance, Financials)
- Offer resilient flows: core operations continue with robust logging

High-level Architecture
- Backend
  - Service layer: `api/src/services/accounting.service.ts` orchestrates journal entry creation, validations, GL, trial balance, financial statements, dashboard metrics, budget helpers.
  - API routes: `api/src/pages/api/v2/accounting/` exposes accounting endpoints (journal entries, GL, COA, budgets, integrations, reporting, etc.).
  - Utilities: `api/src/utils/accounting.utils.ts` for validation, mappings (standard COA), formatting, and error types.
  - Prisma schemas: `api/prisma/schema/accounting.prisma` defines definitive enums, models, relations.
- Frontend
  - Pages: `frontend/src/pages/accounting/` with dashboard and related views.
  - Components: `frontend/src/pages/accounting/component/` includes `treasurer-dashboard.tsx` and feature components (e.g., journal approval).
  - UX patterns: status/error surfaces, z-index conventions for modals and dropdowns.

Core Principles
- Double-entry enforcement: Debits = Credits within 0.01 tolerance.
- Exclusive line amounts: Each line has either a debit or a credit, never both or neither.
- Status model: Journal entries are created as `DRAFT`; approval transitions to `POSTED` or `CANCELLED`. Only `POSTED` impacts GL and official reports.
- Segregation of duties: The approver cannot be the creator. Pending list excludes the creator’s own entries.
- Decimal handling: Convert Prisma `Decimal` ➜ JS `number` for calculations and UI rendering.
- Transaction patterns: Use Prisma `$transaction(async (tx) => ...)` for writes; for concurrent reads prefer `Promise.all` over `$transaction([])` with proxies.

Use the linked documents for detailed implementation notes, examples, and references to concrete code paths.

---

## Recent Integrations

- POS & Cashier Integration (Canteen/Shop)
  - Cash and Credit POS flows now trigger `AccountingService.processPosSaleIntegration` after successful payment/receipt creation.
  - JE mapping:
    - Cash sale: DR Cash, CR General Revenue.
    - Credit sale (student credits): DR Student Credits Liability, CR General Revenue.
  - Created as `DRAFT` and require approval to post to GL (SoD enforced by approval route).
  - See:
    - Backend: `docs/accounting-module/backend.md` (POS & Cashier Integration section)
    - API Reference: `docs/accounting-module/api-reference.md` (Related POS endpoints)
    - Flows: `docs/accounting-module/flows.md` (POS Sales flow)
    - Frontend: `docs/accounting-module/frontend.md` (POS Integration notes)


- Student Fees: Assignment & Adjustments
  - Fee assignment from finance endpoints now triggers `AccountingService.processFeeAssignmentIntegration`.
  - Fee updates (amount/discount) trigger `AccountingService.processFeeAdjustmentIntegration` to create adjustment JEs.
  - JE mapping:
    - Assignment: DR Accounts Receivable, CR Revenue (by fee type).
    - Adjustment increase: DR Accounts Receivable, CR Revenue.
    - Adjustment decrease: DR Revenue, CR Accounts Receivable.
  - Created as `DRAFT` and require approval to post to GL (SoD enforced by approval route). Failures are logged and do not block fee operations.
  - See:
    - Backend: `docs/accounting-module/backend.md` (Student Fee Integration section)
    - API Reference: `docs/accounting-module/api-reference.md` (Related Finance Student Fee endpoints)
    - Flows: `docs/accounting-module/flows.md` (Fee Assignment and Fee Adjustment flows)


- Financial Reports Dynamic Integration
  - All simulated/static data sources removed from `frontend/src/pages/accounting/component/financial-reports.tsx`.
  - Charts and tables are now powered by backend APIs via analytics and statements hooks:
    - Statements/Summary: `GET /api/v2/accounting/financial-statements`, `GET /api/v2/accounting/financial-summary`
    - Analytics: `GET /api/v2/accounting/analytics/advanced` (revenue, expense, cash-flow, budget-performance)
    - Compliance: derived from `GET /api/v2/accounting/journal-entries` + summary/analytics; checklist pending API support
  - Exports (PDF/Excel/CSV) reflect real-time data and log audit trail actions.
  - Known limitations: CCC/FCF metrics and compliance checklist endpoints are pending; placeholders are shown in UI.
  - See:
    - Frontend: `docs/accounting-module/frontend.md` (Financial Reports and Summary)
    - Feature doc: `docs/accounting-module/financial-reports.md`
    - API Reference: `docs/accounting-module/api-reference.md` (financial-statements, financial-summary, analytics, audit-trail)

