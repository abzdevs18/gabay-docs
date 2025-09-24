# Accounting Module – Gap Analysis and Action Plan (Accountant-Focused)

This document reviews current implementation vs. specs in:
- `docs/accounting-module/accounting-system-guide.md`
- `docs/accounting-module/accounting-system-diagrams.md`

It identifies missing or incomplete features and proposes a prioritized plan aligned with accounting controls (double-entry, SoD, auditability), school finance workflows, and reporting needs.

## Executive Summary

The system implements core reporting (financial statements, summary, analytics) and backend services for accounting. However, several accountant-critical workflows remain incomplete on the UI or API surface, notably Chart of Accounts (COA) management, explicit Goals/Targets management, manual Journal Entry creation/approval endpoints, audit trail write integration in the UI, and period closing controls. Addressing these will unlock daily accounting operations and stronger governance.

## Evidence-Based Gap Analysis

Each item references concrete files/paths to show current state.

### 1) Chart of Accounts (COA) – Create/Edit/Deactivate
- Backend route present: `api/src/pages/api/v2/accounting/chart-of-accounts/index.ts` with `GET` and `POST` handlers using `AccountingService.getChartOfAccounts(...)` and `createChartOfAccount(...)`.
- Frontend UI: `frontend/src/pages/accounting/component/chart-of-accounts.tsx` is mostly static/mocked. The "Create Account" dialog does not call any API; no listing from the backend; no persistence; no validation feedback.
- Validation nuance: route uses `z.string().uuid()` for `parentAccountId`. Specs and past decisions prefer CUID-friendly `.min(1)` (see memories). Potential mismatch when IDs are CUID.

Conclusion: UI integration for COA CRUD is missing; backend create likely usable with small validator alignment. Accountant currently cannot maintain COA.

### 2) Goals/Targets (Funds & KPIs)
- Current behavior: "goals" are implicitly derived from budgets in `AccountingService.getDashboardMetrics` using name/category heuristics.
  - File: `api/src/services/accounting.service.ts` (see lines ~828–1004). Variables `emergencyTarget`, `scholarshipTarget`, `technologyTarget`, `maintenanceTarget` are computed from budgets/budget items. Fallback to `0` if budgets are unavailable.
- No dedicated data model or endpoints for explicit, accountant-defined targets/goals by fiscal year.
- No UI to create/update goals; metrics show static or heuristic values.

Conclusion: Missing explicit Goals (e.g., Emergency Fund target, Scholarship Fund target) with fiscal-year context. Current approach depends on budget naming patterns and provides no direct control to the Accountant.

### 3) Journal Entries – Manual Creation & Approval Endpoints/UI
- Frontend hooks exist for loading JEs, but API routes for `journal-entries/` were not found under `api/src/pages/api/v2/accounting/` (quick scan). The docs and hooks assume such endpoints.
- UI for manual JE creation is not obvious. `general-ledger.tsx` appears to be a viewer; `journal-entry-approval.tsx` exists but may rely on missing endpoints.

Conclusion: Verify and implement `POST /journal-entries`, `GET /journal-entries`, and `GET /journal-entries/pending` endpoints per docs, and add/create UI for manual JE entry. Approval flow should enforce SoD and GL posting rules.

### 4) Audit Trail – UI Integration
- API: `/api/v2/accounting/audit-trail` documented in `docs/accounting-module/api-reference.md`.
- Financial Reports UI currently logs activities locally (in-memory list) and recommends wiring to Audit Trail API.

Conclusion: Connect all significant actions (report generation, exports, approvals, COA changes) to real audit logging API for compliance.

### 5) Period Closing / Fiscal Controls
- Specs highlight period close and restrictions. Current implementation shows fiscal-year helper logic in the frontend (`financial-reports.tsx`) but no explicit period close/lock controls in backend or UI.

Conclusion: Missing period close, lock, and reopened period workflows; needed to prevent back-dated postings after close.

### 6) Compliance Checklist & Metrics
- UI placeholders are present in `financial-reports.tsx`. No backend endpoints yet.

Conclusion: Implement checklists and metrics endpoints; drive UI from server data (e.g., posting SLAs, JE timeliness, exception counts).

### 7) Bank Reconciliation – UI Completeness
- Docs and hooks (`useBankReconciliations`, etc.) mention support. Confirm all related API routes exist and connect a UI for import/matching/approval stages.

Conclusion: Likely partial; ensure end-to-end reconciliation flow with import, matching, adjustments, approval, and reporting.

### 8) COA Validation/ID Strategy Alignment
- Some validators expect UUID; elsewhere, the system uses CUID. Align to avoid creation failures.

Conclusion: Standardize to CUID-friendly validation or support both.

### 9) Role/Permission Enforcement (SoD)
- Specs include Permission Matrix and roles. Ensure routes enforce permissions (create vs. approve) and UI hides actions for unauthorized roles.

Conclusion: Review middleware and route checks; unify across accounting endpoints.

## Prioritized Action Plan (No Code Changes Yet)

### Phase 1 – Core Operations for Accountant
1. COA Management (UI + API wiring)
   - Fetch and display COA from `GET /accounting/chart-of-accounts`.
   - Implement Create Account from modal; show validation errors; refresh list.
   - Add basic Edit/Deactivate flows; enforce type and normal balance rules.
   - Align `parentAccountId` validator to CUID-friendly.

2. Goals/Targets Management
   - Introduce a dedicated "Financial Goals" spec: by fiscal year, category, target amount, owner, notes.
   - Provide API spec (create/list/update) and UI page for goals setup and tracking.
   - Integrate into dashboard metrics; fall back to budgets only when goals are absent.

3. Audit Trail Integration
   - Wire Financial Reports and COA actions to `POST /accounting/audit-trail`.
   - Standardize events: `COA_CREATE/UPDATE/DEACTIVATE`, `REPORT_GENERATE`, `EXPORT_*`.

### Phase 2 – Journal Entry & Posting Controls
4. Manual JE Creation + Approval
   - Confirm/implement `POST /journal-entries`, `GET /journal-entries`, `GET /journal-entries/pending`.
   - Add UI for manual entry with validation and balance enforcement; approval ui enforces SoD.

5. Period Closing Controls
   - Define fiscal calendar settings and closing states.
   - Prevent postings to closed periods; allow authorized reopen with audit trail.

### Phase 3 – Compliance & Reconciliation
6. Compliance Checklist & Metrics
   - Backend endpoints for checklist templates and metrics.
   - UI to track completion and evidence (documents/links).

7. Bank Reconciliation UI
   - Implement import (CSV/OFX/QIF), matching, adjustments, approvals, and reconciliation reports.

### Phase 4 – Hardening & Governance
8. Validation/ID Consistency
   - Standardize CUID/UUID validation; ensure client/server consistency.

9. Role/Permission & Tenant Controls
   - Audit and enforce permission matrix across all accounting routes.
   - Verify `x-tenant-tag` handling for all endpoints.

## Milestones & Deliverables
- M1 (COA + Goals + Audit): Accountant can manage COA and goals; activities audited.
- M2 (JE + Close): Manual entries and approvals operational; period close prevents late postings.
- M3 (Compliance + Reco): Compliance checklist and bank rec fully functional.
- M4 (Hardening): Validation alignment; permissions enforced end-to-end.

## Risks & Considerations
- ID validation mismatch can block COA creation.
- Without explicit goals, dashboard KPIs may be misleading when budgets are absent.
- Period closing is critical to avoid audit exceptions; prioritize design carefully (override workflow with audit trail).

## References
- Specs: `docs/accounting-module/accounting-system-guide.md`, `docs/accounting-module/accounting-system-diagrams.md`
- COA API: `api/src/pages/api/v2/accounting/chart-of-accounts/index.ts`
- Metrics (targets via budgets): `api/src/services/accounting.service.ts` (lines ~828–1004)
- COA UI (mocked): `frontend/src/pages/accounting/component/chart-of-accounts.tsx`
