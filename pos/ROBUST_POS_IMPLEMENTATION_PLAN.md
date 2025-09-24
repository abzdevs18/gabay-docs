# Gabay POS System — Robust Implementation Plan

Date: 2025-09-18
Owner: Engineering (Backend/API + Frontend)
Status: Draft for review

---

## Executive Summary

This plan turns the current partially implemented POS into a robust, auditable, and scalable system integrated with Cashiering, Accounting, and Student Finance. It builds on what already exists in the codebase and fills critical gaps: product/category APIs, inventory movement logging, terminal/shift enforcement, void/refund flows, receipt lifecycle, and hardened validations.

---

## Current State Review (Backend)

Based on code inspection in `api/`:

- Data models (Prisma)
  - `api/prisma/schema/pos.prisma` provides:
    - `POSCategory`, `POSProduct`, `POSTransaction`, `POSTransactionItem` with indexes and basic fields (e.g., `sku`, `inventory`, `minStockThreshold`).
    - Enums (`POSPaymentMethod`, `POSTransactionStatus`, `POSProductType`) defined but string columns are used in models (migration opportunity).
  - `api/prisma/schema/cashiering.prisma` provides cashier sessions/adjustments/denominations.
  - Additional finance/payment/accounting schemas exist (see `payment.prisma`, `accounting.prisma`).

- POS endpoints (existing)
  - Transactions
    - `POST /api/v2/pos/transactions/cash-payment` → `api/src/pages/api/v2/pos/transactions/cash-payment.ts`
      - Validates shift via `cashReconciliation` active shift
      - Creates `POSTransaction`, decrements inventory, creates `payment` and `paymentReceipt`, and calls `AccountingService.processPosSaleIntegration()`.
    - `POST /api/v2/pos/transactions/credit-payment` → `.../credit-payment.ts`
      - Validates student & credit balance via ledger, creates `POSTransaction`, decrements inventory, `payment` + `receipt`, and accounting integration.
    - `GET /api/v2/pos/transactions` → list with pagination/caching (`.../transactions/index.tsx`).
    - `GET /api/v2/pos/transactions/:id` → detail (`.../[id]/index.tsx`).
    - `GET /api/v2/pos/transactions/:id/receipt` → receipt data (`.../[id]/receipt.tsx`).
  - Terminals
    - `GET/POST /api/v2/pos/terminals/canteen` → create/list canteen POS terminals (`.../terminals/canteen.ts`).
  - Note: Frontend references `/api/v2/pos/categories` and `/api/v2/pos/products` but no CRUD endpoints are present yet.

- Cashiering/Finance (existing)
  - Cashier sessions and reports exist under `api/src/pages/api/v2/finance/cashier/*` and `.../cash-reconciliation/*`.
  - Core service: `api/src/services/cashier.service.ts` (open/close session, payments, adjustments, session summaries, daily/collection reports).
  - Accounting integration: `api/src/services/accounting.service.ts` with `processPosSaleIntegration()` already called by POS payment endpoints.

- Caching
  - `CacheService` is used; POS cache keys scaffolded at `api/src/services/cache-keys/pos.ts`.

- Gaps observed
  - No product/category CRUD APIs; no inventory adjustment/restock API; no inventory movement log.
  - No POS-specific void/refund endpoints (cashiering has a void flow for `cashTransaction`, but POS needs its own to reverse inventory and post accounting reversal).
  - Terminal management is limited (canteen only) and split between `finance/terminals.ts` and `pos/terminals/canteen.ts`.
  - Enums defined in Prisma but models store strings (possible mismatch/typo risks).
  - Image upload for products absent (frontend currently leans on URLs & previews).

---

## Goals & Quality Standards

- Functional
  - Robust product/catalog and inventory management with audit trail.
  - Reliable transaction flows (cash + credit) with shift enforcement and receipts.
  - Accurate accounting integration and reporting.

- Quality
  - Strict TypeScript typing, Zod input validation, consistent error handling.
  - Multi-tenant safety using `getPrismaClient(req)` + `getTenantId(req)` consistently.
  - Caching with clear invalidation.
  - Security: AuthZ with role/permission checks (POS cashier/supervisor/admin).

---

## Gap Analysis → Action Items

1) Product & Category APIs [Missing]
- Add CRUD endpoints:
  - `GET /api/v2/pos/categories`, `POST`, `PUT :id`, `DELETE :id`.
  - `GET /api/v2/pos/products`, `POST`, `PUT :id`, `DELETE :id`.
- Include search/pagination, low-stock filter, and sku uniqueness check.
- Invalidate caches: `POSCacheKeys.PRODUCT_LIST`, `CATEGORY_LIST`.

2) Inventory Management [Incomplete]
- Add Inventory Movement log table to Prisma (see Data Model Changes) and endpoints:
  - `POST /api/v2/pos/inventory/adjustments` with types: `RESTOCK`, `ADJUSTMENT`.
  - `GET /api/v2/pos/inventory/movements` (paginated, filterable by product/date/type).
- Enforce non-negative inventory during sales with transaction-safe checks.

3) POS Voids/Refunds [Missing]
- Add `PUT /api/v2/pos/transactions/:id/void` (permission-gated):
  - Change `POSTransaction.status → VOIDED`, set `voidedBy`, `voidReason`, `voidedAt`.
  - Create reversing Inventory Movements for each item (increase inventory).
  - Create reversing accounting journal entry (credit/debit swap).
  - Invalidate caches for transactions and low-stock.
- Plan refunds later (Phase 2) with partial returns, separate receipt references.

4) Terminals & Shifts [Partial]
- Unify terminal management under `/api/v2/pos/terminals` with types (`CANTEEN_POS`, `SHOP_POS`, etc.).
- Align shift enforcement: ensure all cash payments require an active shift (`cash-reconciliation` or `cashiering.session`).
- Expose terminal list/status and active shift info for POS UI.

5) Data Contract Consistency [Harden]
- Normalize `type`, `paymentMethod`, `status` to Prisma enums in a future migration (Phase 2) to avoid typos.
- Ensure all monetary values are serialized as numbers in responses (convert `Prisma.Decimal`).

6) Media Uploads [Missing]
- Add `POST /api/v2/pos/uploads/image` (multipart or base64) to store product images (local or S3-compatible). Return URL stored in `POSProduct.imageUrl`.

7) Security & RBAC [Enhance]
- Add permission checks to POS routes using existing middlewares:
  - POS:MANAGE_PRODUCTS (admin/supervisor)
  - POS:SALE (cashier/supervisor)
  - POS:VOID (supervisor/admin)
  - POS:INVENTORY (supervisor/admin)

8) Observability & Auditing
- Standardize structured logging with correlation IDs.
- Create audit logs for product changes, inventory adjustments, and voids.

9) Caching Strategy
- Define TTLs and invalidation rules for product lists, transaction lists/details, low stock.

---

## Data Model Changes (Prisma)

New model (Phase 1):

```prisma
// pos.prisma (add)
model POSInventoryMovement {
  id            String   @id @default(uuid())
  productId     String
  product       POSProduct @relation(fields: [productId], references: [id])
  type          String   // SALE | RESTOCK | ADJUSTMENT | VOID_SALE
  quantity      Int
  referenceId   String?  // POSTransaction.id or manual adjustment id
  reason        String?
  createdBy     String   // userId
  createdAt     DateTime @default(now())

  @@index([productId])
  @@index([type])
  @@index([createdAt])
}
```

Future migration (Phase 2):
- Migrate `POSProduct.type`, `POSTransaction.paymentMethod`, `POSTransaction.status` to Prisma enums (`POSProductType`, `POSPaymentMethod`, `POSTransactionStatus`).
- Add `terminalId` field to `POSTransaction` (currently in metadata) for direct relations to `CashierTerminal`.

---

## API Specification (to add or align)

### Pagination Standard (Cursor-based)
- All list endpoints use cursor-based pagination.
- Query params: `limit` (default 10), `cursor` (optional, last item id from previous page).
- Response shape adds: `{ nextCursor: string|null, hasMore: boolean }` alongside existing fields.
- Sorting is stable and deterministic (typically `createdAt desc, id desc`).

Products & Categories
- `GET /api/v2/pos/categories` → list with `?q`, `?limit`, `?cursor`.
- `POST /api/v2/pos/categories` → create (name, iconName, isActive).
- `PUT /api/v2/pos/categories/:id` → update.
- `DELETE /api/v2/pos/categories/:id` → soft-delete or deactivate.
- `GET /api/v2/pos/products` → list with `?q`, `?categoryId`, `?lowStock`, `?limit`, `?cursor`.
- `POST /api/v2/pos/products` → create product (enforce unique `sku`).
- `PUT /api/v2/pos/products/:id` → update fields (price, inventory, imageUrl, etc.).
- `DELETE /api/v2/pos/products/:id` → soft-delete, disallow if active stock? (configurable).
- `GET /api/v2/pos/products/low-stock` → inventory below threshold.

Inventory
- `POST /api/v2/pos/inventory/adjustments` → `{ productId, type: 'RESTOCK'|'ADJUSTMENT', quantity, reason }`.
- `GET /api/v2/pos/inventory/movements` → filter by productId/date/type.

Transactions (existing + to add)
- `POST /api/v2/pos/transactions/cash-payment` (exists) → enforce active shift.
- `POST /api/v2/pos/transactions/credit-payment` (exists).
- `GET /api/v2/pos/transactions` (exists) → list with `?status`, `?paymentMethod`, `?startDate`, `?endDate`, `?limit`, `?cursor`.
- `GET /api/v2/pos/transactions/:id` (exists).
- `GET /api/v2/pos/transactions/:id/receipt` (exists).
- `PUT /api/v2/pos/transactions/:id/void` (to add) → reverse inventory + accounting.

Terminals & Shifts
- `GET /api/v2/pos/terminals` → unify listing (include canteen & others).
- `POST /api/v2/pos/terminals` → create terminal (generalized from canteen).
- `GET /api/v2/finance/cash-reconciliation/active-shift` (exists) → expose to POS UI.
- `POST /api/v2/finance/cash-reconciliation/start-shift` / `end-shift` (exists) → POS workflow integration.

Uploads
- `POST /api/v2/pos/uploads/image` → returns `{ url }` to be stored in `POSProduct.imageUrl`.

Security & Validation
- All routes use `authenticate`, and Zod schemas.
- Apply role/permission checks for create/update/delete/void/adjust.

Response Shape Rules
- Convert all `Prisma.Decimal` to numbers in API responses.
- Use consistent response envelope `{ success, data, message? }`.

---

## Business Rules & Flows

Sales (Cash/Credit)
- Validate inventory inside a single DB transaction.
- On success, create `POSTransaction` + `items`, decrement inventory, create `payment` + `receipt`, call accounting integration.
- Cache invalidation: POS transactions + low stock + product lists (if inventory thresholds crossed).

Voids (POS)
- Permission required, optional time-window enforcement.
- Steps:
  1. Validate original transaction is `COMPLETED` and not already voided.
  2. Update `POSTransaction` to `VOIDED`, set `voidedBy`, `voidedAt`, `voidReason`.
  3. Create `POSInventoryMovement` entries with type `VOID_SALE` for each item (increase inventory).
  4. Create reversing accounting journal entry (Dr Revenue, Cr Cash or Cr Student Credits Liability).
  5. Invalidate caches.

Inventory Adjustments
- RESTOCK increases inventory and logs movement.
- ADJUSTMENT can be +/- with mandatory `reason` and `createdBy`.
- Guardrails: non-negative inventory unless explicitly allowed by role.

Images
- Accept upload (multipart or base64) and return `imageUrl`.
- Optionally add media cleanup job and S3/Cloud storage integration later.

RBAC
- Roles: `POS_CASHIER`, `POS_SUPERVISOR`, `POS_ADMIN`.
- Permissions mapping to endpoints (manage products, inventory, sales, voids).

Caching
- TTL examples: product list 5–10 mins, transaction list 2–5 mins, details 30 mins.
- Invalidate on writes (products/inventory/transactions).

---

## Phased Implementation Plan

Phase 0 — Hardening (1–2 days)
- Add consistent error envelopes and decimal serialization.
- Add request validation (Zod) to all POS routes.
- Add authZ checks scaffold.

Phase 1 — Core POS (5–8 days)
- Build Product & Category CRUD APIs with caching + invalidation.
- Build Inventory Adjustments + Movement log + list endpoint.
- Add `PUT /api/v2/pos/transactions/:id/void` with inventory reversal + accounting reversal.
- Unify Terminal listing/creation under `/api/v2/pos/terminals` and wire into POS UI needs.
- Ensure `cash-payment` strictly requires active shift and responds consistently.
- Add low-stock endpoint; expose thresholds.
- QA + unit/integration tests for all above.

Phase 2 — Data & UX Improvements (5–7 days)
- Prisma enums migration (type/paymentMethod/status) with safe data migration.
- Add `terminalId` field to `POSTransaction` and backfill from `metadata`.
- Add product image upload endpoint.
- Add partial refund/return flow and receipt reprint endpoint.
- Strengthen concurrency on inventory updates (transaction-level checks or `SELECT FOR UPDATE`).

Phase 3 — Reporting & Advanced Features (4–6 days)
- POS daily Z-reports and cashier performance reports (reusing `CashierService`).
- Promotions/discounts framework (optional, feature-flagged).
- Real-time updates via Socket.io (inventory low stock, new transactions) if needed.

---

## Testing Strategy

- Unit tests: services (inventory adjustment, void flow, product CRUD validation).
- Integration tests: API routes with in-memory or test DB, including rollback checks.
- E2E happy paths: sale (cash/credit) → receipt → void → inventory restored.
- Load tests on transaction endpoints.

---

## Security, Auditing, and Compliance

- Enforce authZ per route; log user IDs.
- Audit log entries for: product create/update/delete, inventory adjustments, voids.
- Input validation with Zod; sanitize/escape strings.
- Rate limiting for mutation endpoints.

---

## Centralized POS Service Layer Architecture

Create a centralized service entrypoint `api/src/services/pos.service.ts` (facade) to orchestrate all POS operations. Internally this can compose thin modules (e.g., `pos.products.ts`, `pos.inventory.ts`, `pos.transactions.ts`, `pos.reports.ts`) but expose a single API to route handlers.

Responsibilities
- Product & Category CRUD with validation and caching invalidation.
- Inventory adjustments + movement logging (RESTOCK/ADJUSTMENT/SALE/VOID_SALE).
- Sales orchestration: cash/credit (reusing existing endpoints’ logic), enforcing active shifts for cash.
- Void orchestration: status change, inventory reversal, reversing journal entry.
- Reporting aggregators: daily sales, product mix, cashier performance, inventory movements.
- Decimal serialization and response shaping (convert `Prisma.Decimal` to numbers consistently).
- Multi-tenant safety: always accept `prisma` from `getPrismaClient(req)` and `tenantId` from `getTenantId(req)`.

Suggested Public API (TypeScript)
```ts
export class POSService {
  constructor(private prisma: PrismaClient) {}

  // Catalog
  listCategories(params: { q?: string; page?: number; limit?: number }): Promise<...>
  createCategory(input: { name: string; iconName?: string; isActive?: boolean }, userId: string): Promise<...>
  updateCategory(id: string, input: Partial<...>, userId: string): Promise<...>
  listProducts(params: { q?: string; categoryId?: string; page?: number; limit?: number; lowStock?: boolean }): Promise<...>
  createProduct(input: { name: string; sku: string; price: number; categoryId: string; type: 'menu'|'shelf'; imageUrl?: string; minStockThreshold?: number }, userId: string): Promise<...>
  updateProduct(id: string, input: Partial<...>, userId: string): Promise<...>

  // Inventory
  adjustInventory(input: { productId: string; type: 'RESTOCK'|'ADJUSTMENT'; quantity: number; reason?: string }, userId: string): Promise<...>
  listInventoryMovements(params: { productId?: string; type?: string; startDate?: string; endDate?: string; page?: number; limit?: number }): Promise<...>

  // Sales
  processCashSale(input: { items: { productId: string; quantity: number; priceAtPurchase: number }[]; amount: number; terminalId: string; cashierId: string; isCanteenTransaction?: boolean; customerName?: string }, userId: string): Promise<...>
  processCreditSale(input: { studentId: string; items: { productId: string; quantity: number; priceAtPurchase: number }[]; amount: number; terminalId: string; cashierId?: string; isCanteenTransaction?: boolean }, userId: string): Promise<...>
  voidTransaction(id: string, reason: string, userId: string): Promise<...>

  // Reports
  reportDailySales(params: { date?: string; cashierId?: string; terminalId?: string }): Promise<...>
  reportCashierPerformance(params: { startDate: string; endDate: string; cashierId?: string }): Promise<...>
  reportProductMix(params: { startDate: string; endDate: string; categoryId?: string }): Promise<...>
  reportInventoryMovements(params: { startDate?: string; endDate?: string; productId?: string; type?: string }): Promise<...>
}
```

Route Handlers
- All `/api/v2/pos/*` routes inject `prisma = getPrismaClient(req)` and call `POSService` methods.
- Existing `cash-payment` and `credit-payment` can be refactored to use the service without changing response contracts.

Caching & Invalidation
- Use `CacheService` with `POSCacheKeys` for lists/detail.
- Invalidate on product changes, inventory adjustments, transactions, and voids.

## Reporting Layer: KPIs and Endpoints

Data Sources
- `POSTransaction` + `POSTransactionItem` (sales, items, totals).
- `Payment` + `PaymentReceipt` (amounts, OR numbers).
- `CashierSession` + `CashTransaction` (cashier-level summaries).
- `POSInventoryMovement` (stock ins/outs, voids, adjustments).

Endpoints (read-only)
- `GET /api/v2/pos/reports/daily-sales?date=&cashierId=&terminalId=`
- `GET /api/v2/pos/reports/cashier-performance?startDate=&endDate=&cashierId=`
- `GET /api/v2/pos/reports/product-mix?startDate=&endDate=&categoryId=`
- `GET /api/v2/pos/reports/inventory-movements?startDate=&endDate=&type=&productId=`
- `GET /api/v2/pos/reports/summary?startDate=&endDate=` (aggregated dashboard)

KPIs
- Daily totals by payment method (CASH/CREDIT), average ticket size, items per ticket.
- Cashier performance: count, total, variance with expected cash.
- Product mix: top items by quantity/revenue, category breakdown.
- Inventory: net movement per product, low-stock counts over time.

Implementation Notes
- Reuse parts of `CashierService` (daily/collection) where applicable.
- Ensure `Prisma.Decimal` to number conversion is applied consistently.

## RBAC Model and Temporary Assignments

Roles
- `POS_ADMIN`: full access; can assign roles.
- `POS_SUPERVISOR`: manage catalog/inventory, approve voids, view reports.
- `POS_CASHIER`: create sales, view receipts.

Temporary Assignments
- Short-term approach (no schema change): store role grants in `User.metadata` as `posRoles: [{ role: 'POS_CASHIER'|'POS_SUPERVISOR'|'POS_ADMIN', expiresAt?: string }]`.
- Middleware checks: accept a role when either permanent or not expired.
- API
  - `POST /api/v2/pos/rbac/assign-role` → `{ userId, role, expiresAt? }` (requires `POS_ADMIN`).
  - `DELETE /api/v2/pos/rbac/assign-role` → `{ userId, role }`.
  - `GET /api/v2/pos/rbac/roles?userId=` → returns effective roles.

Hardening (Phase 2)
- Optional dedicated table `UserRoleAssignment { id, userId, role, effectiveFrom, effectiveTo, createdBy }` for auditability and queries.

Route Guards
- Map endpoints to permissions (as listed earlier). Add Zod validation + permission middleware consistently to new routes.

## Terminal Handling Strategy (Phased Options)

Existing Model
- `CashierTerminal` already used in credit-payment and canteen routes.

Options
- Option A: Service-account terminals (current canteen model)
  - `metadata.isCanteenTerminal = true`, `requiresCashier = false`.
  - Use `serviceAccountId` as `cashierId` for canteen transactions.
  - Pros: Simple ops, no cashier login required. Cons: Limited individual accountability.
- Option B: Cashier-bound terminals
  - `metadata.requiresCashier = true`. Logged-in user is the cashier; require active shift for cash.
  - Pros: Strong audit trail per cashier. Cons: Requires login + shift management.
- Option C: Hybrid (recommended)
  - Terminal has `type` and `metadata.requiresCashier` toggle; can run in either mode.

Endpoints
- Unify under `GET/POST /api/v2/pos/terminals` (generalize from canteen).
- Include fields: `name, location, type, isActive, serviceAccountId (optional), metadata: { isCanteenTerminal, requiresCashier }`.

Phasing
- Phase 1: Keep canteen as service-account terminals by default; add unified listing/creation. Cash routes must validate active shift when `requiresCashier` is true.
- Phase 2: Add UI to toggle modes per terminal; add `terminalId` column to `POSTransaction` and backfill.

## Open Questions / Decisions Needed

- Should voids be time-limited (e.g., same day) without supervisor approval?
- Storage choice for images (local vs S3-compatible bucket)?
- Do we unify terminal management fully under `/pos/terminals` or keep finance endpoints and proxy in POS?
- Discount strategy (line-item vs cart-level) and accounting mappings.

---

## Next Steps

1. Approve Phase 1 scope and endpoints.
2. Implement Product/Category CRUD + Inventory movements.
3. Implement POS Void flow with accounting reversal.
4. Unify Terminal listing and enforce active shifts for cash.
5. QA + document API in `docs/` and update frontend integration.
