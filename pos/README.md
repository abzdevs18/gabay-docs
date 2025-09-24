# Canteen POS – Developer & AI Agent Guide

This document explains the architecture, code structure, core flows, endpoints, RBAC, and conventions of the Canteen POS. It is written for both human developers and AI agents to quickly understand, extend, and safely modify the system.


## Quick Start
- Frontend (Next.js): `frontend/`
- Backend (Next.js API Routes): `api/`
- Shared docs: `docs/pos/`
- Base URL env: `BASE_URL`
- Auth: JWT in cookie `token`; Tenant in cookie `x-tenant-tag`.
- Centralized HTTP client: `frontend/src/utils/api-client.ts`
- RBAC: CASL. Ability builder: `frontend/src/configs/acl.ts`

To run locally:
1. Create `.env` files (see Env section below).
2. Backend: in `api/` run `npm i && npm run dev`.
3. Frontend: in `frontend/` run `npm i && npm run dev`.


## High-Level Architecture
```
┌──────────────────────┐        AuthN + Tenant           ┌──────────────────────────┐
│  Frontend (Next.js)  │  ────────────────▶  JWT, x-tenant│  Backend (Next.js API)   │
│  - POS UI (pages/pos)│  ◀───────────────  JSON         │  - /api/v2/pos/*         │
│  - shadcn/ui         │        Responses                │  - CASL enforcement      │
└─────────┬────────────┘                                 └────────────┬─────────────┘
          │                                                          │
          │ Centralized apiClient (adds auth + tenant)               │
          ▼                                                          ▼
  axios instance + interceptors                           Prisma + Multi-tenant utils
  `frontend/src/utils/api-client.ts`                       `api/src/...`
```

Key capabilities:
- POS transactions (cash, credit, void)
- Shift lifecycle (open/close)
- Products & inventory (listing, editing, low-stock, movements)
- Student search & credit top-up
- CASL-based RBAC across endpoints and UI


## Frontend Structure (Selected)
- `frontend/src/pages/pos/index.tsx`
  - Top-level POS page orchestrating views (home, orders, inventory, catalog, students, transactions, reports, settings) via `PosLayout`.
  - Loads products, students (search), shifts, transactions.
  - Handles payments and receipt generation state.
  - Uses `apiClient` for HTTP, `toast` for UX feedback, and `checkUserPermission` for CASL gating.

- Views and key components:
  - `frontend/src/components/pos/PosMainView.tsx` – main selling UI (cart, summary, payment).
  - `frontend/src/components/pos/TransactionLogs.tsx` – Transactions list with receipt and void action.
  - `frontend/src/components/pos/PosTransactionsView.tsx` – Transaction experience, maps receipt items with fallback.
  - `frontend/src/components/pos/ProductManagement.tsx` – Product list, create/edit/delete, stock updates.
  - `frontend/src/components/pos/PosInventoryView.tsx` – Inventory UI (includes movements panel trigger).
  - `frontend/src/components/pos/InventoryMovementsPanel.tsx` – Fetches and shows inventory movements for a product (cursor pagination).
  - `frontend/src/components/pos/PosCatalogView.tsx` – Catalog management (pending full `apiClient` refactor).
  - `frontend/src/components/pos/Categories.tsx` – Category filtering and listing (pending full `apiClient` refactor).

- Utilities & RBAC:
  - `frontend/src/utils/api-client.ts` – axios instance with interceptors injecting `Authorization`, `x-tenant-tag`, and `uuid`.
  - `frontend/src/hooks/useTenantSafeApi.ts` – wait until tenant context is ready.
  - `frontend/src/configs/acl.ts` – `buildAbilityForUser`, `checkUserPermission`.
  - `frontend/src/@core/components/auth/AclGuard.tsx` – wraps pages to enforce CASL abilities.


## Backend Structure (Selected)
- `api/src/pages/api/v2/pos/transactions/*`
  - `index.tsx` – list transactions; enforces `read` on `POS Transactions`.
  - `cash-payment.ts` – creates cash sale transaction; accounting integration.
  - `credit-payment.ts` – creates credit payment; may require `studentPin` and respects daily credit limits.
  - `void.tsx` – voids a transaction; restores inventory; accounting reversal; enforces `update` on `POS Transactions` or `POS Supervisor`.

- `api/src/pages/api/v2/pos/shifts/*`
  - `open.ts` – open a cashier session; enforces `create` on `POS Shifts` or `POS Cashiering`.
  - `close.ts` – close the active session; enforces `update`/`create` similarly.

- `api/src/pages/api/v2/pos/inventory/*`
  - `movements.ts` – list inventory movements (cursor paginated).
  - `adjustments.ts` – adjust stock (if exposed; ensure RBAC).

- `api/src/pages/api/v2/pos/self/pos-settings.ts` – save per-user POS PIN & daily credit limit.

- Cross-cutting:
  - `authenticate` middleware; `assertAbility` CASL checks; `getPrismaClient` with tenant routing; `CacheService` invalidations.


## Authentication & Tenant Model
- Frontend sends headers via `apiClient`:
  - `Authorization: Bearer <token>` from `parseCookies().token`.
  - `x-tenant-tag` from `getTenantCookie('x-tenant-tag')`.
  - Optional `uuid` header.
- Backend uses `authenticate(req)` and tenant-aware Prisma client (`getPrismaClient(req)`).


## RBAC with CASL
- Ability builder: `frontend/src/configs/acl.ts`
  - Fetches roles/permissions from `/api/v2/user/:id/roles-permissions`.
  - Caches ability; exposes `checkUserPermission(action, subject)`.
- Common subjects used in POS:
  - `POS Transactions`, `POS Supervisor`, `POS Shifts`, `POS Cashiering`.
- Example UI gating:
  - Shift buttons: require `create` on `POS Shifts` or `POS Cashiering`.
  - Create transactions: require `create` on `POS Transactions`.
  - Void transactions: require `update` on `POS Transactions` or `POS Supervisor`.


## Core User Flows

### 1) Shift Lifecycle
- Open Shift
  - Frontend: `index.tsx -> handleOpenShift()`
  - POST `/api/v2/pos/shifts/open` with `{ openingFloat }`
  - CASL: `create` on `POS Shifts` or `POS Cashiering`.
- Close Shift
  - Frontend: `index.tsx -> handleCloseShift()`
  - POST `/api/v2/pos/shifts/close` with `{ closingAmount }`.
- UI guards: Payments blocked when no active shift.

### 2) Product Loading & Management
- List Products: GET `/api/v2/pos/products` → `index.tsx` and `ProductManagement.tsx`.
  - Transformations: normalize `type` to lowercase; map `imageUrl`→`image`; price to number.
- Edit/Create/Delete: `ProductManagement.tsx`
  - PUT `/api/v2/pos/products/:id`
  - POST `/api/v2/pos/products/create`
  - DELETE `/api/v2/pos/products/:id`
- Low stock thresholds and flags supported.

### 3) Student Search & Credit Top-up
- Search: GET `/api/user/search-user?search=<q>&includePos=true` → mapped to local `Student`.
- Credit top-up: POST `/api/v2/pos/transactions/credit-topup`.

### 4) Checkout & Payments
- Credit Payment
  - Frontend: `index.tsx -> handleProcessPayment('credit')`
  - Endpoint: POST `/api/v2/pos/transactions/credit-payment`
  - Payload: `{ studentId, amount, items[], terminalId, cashierId, studentPin? }`
  - Behavior: may prompt for `studentPin` if required; enforces daily limit; updates student balances.
- Cash Payment
  - Frontend: `index.tsx -> handleProcessPayment('cash')`
  - Endpoint: POST `/api/v2/pos/transactions/cash-payment`
  - Payload: `{ amount, items[], terminalId, cashierId, isCanteenTransaction, customerName }`
- Receipts
  - Transactions appended to local `transactions` state.
  - Receipt display is driven by mapped items (see “Receipt Fallback”).

### 5) Receipt Fallback Logic
- File: `frontend/src/components/pos/PosTransactionsView.tsx`
- If `transaction.products` is empty, receipt items fallback to `transaction.items` to avoid blank receipts.

### 6) Transactions List & Void
- List Transactions:
  - Frontend: `index.tsx` effect when `activeView==='transactions'`
  - GET `/api/v2/pos/transactions?limit=25` → mapped to `{ id, studentId, items, total, timestamp, type, status, reference, paymentMethod }`.
- View Receipt:
  - `frontend/src/components/pos/TransactionLogs.tsx` → opens sheet with shared `TransactionReceipt` component.
- Void Transaction:
  - POST `/api/v2/pos/transactions/void` with `{ transactionId, reason }`.
  - Restores inventory; creates accounting reversal; invalidates caches.
  - UI gating: only show Void if user has permission.

### 7) Inventory Movements
- Panel component: `frontend/src/components/pos/InventoryMovementsPanel.tsx`
  - GET `/api/v2/pos/inventory/movements?productId=<id>&limit=<n>&cursor=<c>`
  - Supports cursor pagination (`hasMore`, `nextCursor`).
- Trigger: From Inventory/Product list (Product menu → “View Movements”).

### 8) POS Settings (Self)
- Save settings from POS “Settings” tab (PIN, Daily Credit Limit).
- Endpoint: POST `/api/v2/pos/self/pos-settings`
- After success: clear inputs, toast confirmation.


## HTTP Client Strategy
- Use `apiClient` everywhere for authenticated + tenant-aware requests:
  - File: `frontend/src/utils/api-client.ts`
  - `baseURL` from `process.env.BASE_URL`.
  - Request interceptor injects `Authorization`, `x-tenant-tag`, `uuid`.
- Known areas pending refactor (still using raw `axios`):
  - `frontend/src/components/pos/PosCatalogView.tsx`
  - `frontend/src/components/pos/Categories.tsx`
  - `frontend/src/components/pos/PosOrdersView.tsx`
  - `frontend/src/components/pos/EditProduct.tsx`


## Error Handling & UX
- Patterns
  - Catch errors and display shadcn `toast` with error message.
  - For 401/403: show user-friendly message and prevent action.
  - For credit payments requiring PIN: prompt and retry.
- Examples
  - Void with 403 → “You do not have permission to void transactions.”
  - Shift not open → “Open Shift Required” blocking payments.


## Environment Variables
- Frontend (`frontend/.env.local`):
  - `BASE_URL=https://your-api-host`
- Backend (`api/.env`):
  - `ALLOWED_METHODS` – e.g. `GET,POST,PUT,DELETE,OPTIONS`
  - JWT secrets, DB connection, tenant configs (see project’s backend envs)


## Data Types (selected)
- `Product`
  - `{ id, name, category, price, inventory, sku, description, type: 'menu'|'shelf', image }`
- `CartItem` extends `Product` with `quantity`.
- `Transaction`
  - `{ id, studentId|'CASH-SALE', products[], items[], total, timestamp, type, status, reference, paymentMethod }`
- `Receipt`
  - `{ studentInfo?, items[], receiptNumber?, ... }` (see receipt component contract)


## Security & Permissions Map
- Shifts: `create` on `POS Shifts` or `POS Cashiering`.
- Create Transactions: `create` on `POS Transactions`.
- Void Transactions: `update` on `POS Transactions` or `POS Supervisor`.
- Inventory Adjustments/Movements: `read`/`update` on inventory-related subjects as configured.


## Testing Checklist
- Shift lifecycle: cannot process payments when shift closed.
- Credit payment PIN prompt appears when required; daily limit enforced.
- Cash sales create transactions and receipts.
- Transactions view loads recent entries; receipts render even if `products` is empty (fallback to `items`).
- Void action only visible to authorized users; on success, status becomes `voided`.
- Inventory movements panel fetches and paginates.
- POS settings save successfully and clear inputs.


## Troubleshooting
- 401/403 on POS endpoints
  - Ensure `token` cookie exists; tenant cookie `x-tenant-tag` set.
  - Confirm requests use `apiClient`, not raw `axios`.
- Receipt shows empty items
  - Ensure `PosTransactionsView.tsx` fallback is in place and transactions supply `items` from backend.
- Can’t Void despite permission
  - Verify CASL `buildAbilityForUser` result and subjects align with backend `assertAbility`.
- Shift open errors
  - Ensure no existing active session for user; backend prevents duplicates.


## Extension Points / How-To
- Add a new POS endpoint
  1) Implement API under `api/src/pages/api/v2/pos/<feature>/...`.
  2) Enforce RBAC with `assertAbility(prisma, user.id, action, [subjects])`.
  3) Invalidate caches via `CacheService` as needed.
  4) Consume via `apiClient` on the frontend.

- Add a new secured UI action
  1) Check ability with `checkUserPermission(action, subject)`.
  2) Hide/disable button unless allowed.
  3) Handle 403 with a toast fallback.

- Introduce React Query hooks (planned)
  - Suggested structure: `frontend/src/services/pos/` with hooks like:
    - `usePosTransactions(query)`, `useCreateCashPayment()`, `useCreateCreditPayment()`, `useVoidTransaction()`
    - `useOpenShift()`, `useCloseShift()`
    - `usePosProducts(query)`, `useUpdateProduct()`, `useCreateProduct()`
    - `useInventoryMovements(productId)`
  - All hooks use `apiClient` internally and return `{ data, isLoading, error, mutate }`.


## File Reference Map
- Frontend
  - `pages/pos/index.tsx` – main POS flows: shifts, payments, load products, load transactions, POS settings.
  - `components/pos/TransactionLogs.tsx` – list + receipt + void (CASL-gated; uses `apiClient`).
  - `components/pos/PosTransactionsView.tsx` – receipt item mapping with fallback.
  - `components/pos/ProductManagement.tsx` – CRUD/stock, category fetch, all via `apiClient`.
  - `components/pos/InventoryMovementsPanel.tsx` – movements fetch (cursor) via `apiClient`.
  - `utils/api-client.ts` – centralized axios client.
  - `configs/acl.ts` – CASL ability; `checkUserPermission`.

- Backend
  - `api/pages/api/v2/pos/transactions/` – cash, credit, void, list.
  - `api/pages/api/v2/pos/shifts/` – open/close.
  - `api/pages/api/v2/pos/inventory/` – movements, adjustments.
  - `api/pages/api/v2/pos/self/pos-settings.ts` – POS PIN & daily limit.


## AI Agent Playbook
- Always use `apiClient` for HTTP to ensure auth + tenant headers.
- Before enabling a UI action (e.g., Void, Open Shift), check CASL via `checkUserPermission`.
- When adding a new feature:
  - Place shared helpers in `frontend/src/utils/`.
  - Place UI components in `frontend/src/components/pos/`.
  - Add endpoints under `api/src/pages/api/v2/pos/...` and enforce RBAC.
  - Update `docs/pos/README.md` with the new flow and endpoint.
- For receipts, ensure fallback paths exist when backend payloads vary.
- For inventory, prefer cursor-based pagination (`hasMore`, `nextCursor`).


## Roadmap / Known Gaps
- Migrate remaining raw `axios` calls in POS components to `apiClient`.
- Add React Query hooks for POS endpoints with standardized error handling.
- Expand automated tests for shifts, payments, void, and inventory flows.
- Unify roles-permissions fetch to use `apiClient`.


---
Last updated: 2025-09-19
