# Accounting Module – Data Model (Prisma)

This document summarizes the core Prisma models, enums, and relationships powering the Accounting Module. Source of truth: `api/prisma/schema/accounting.prisma`.

## Enums

- AccountType: `ASSET | LIABILITY | EQUITY | REVENUE | EXPENSE`
- JournalEntryStatus: `DRAFT | POSTED | REVERSED | CANCELLED`
- TransactionSource: `MANUAL | PAYMENT | FEE_ASSIGNMENT | CASHIER | INVOICE | ADJUSTMENT | SYSTEM`
- AuditAction: `CREATE | UPDATE | DELETE | APPROVE | REVERSE | CANCEL`
- FinancialStatementType: `BALANCE_SHEET | INCOME_STATEMENT | CASH_FLOW | TRIAL_BALANCE | GENERAL_LEDGER`
- VendorType: `SUPPLIER | SERVICE_PROVIDER | CONTRACTOR | UTILITY | OTHER`
- PaymentTerms: `NET_15 | NET_30 | NET_45 | NET_60 | IMMEDIATE`
- VendorInvoiceStatus: `PENDING | APPROVED | REJECTED | PAID | OVERDUE | CANCELLED`
- PurchaseOrderStatus: `DRAFT | PENDING_APPROVAL | APPROVED | PARTIALLY_RECEIVED | FULLY_RECEIVED | CANCELLED`
- ReceiptStatus: `PENDING | PARTIAL | COMPLETE | CANCELLED`

## Core Accounting Models

### ChartOfAccount (`chart_of_accounts`)
- id: String (cuid, PK)
- accountCode: String (unique, 4-digit suggested)
- accountName: String
- accountType: AccountType
- parentAccountId: String? (self-relation)
- description: String?
- normalBalance: `'DEBIT' | 'CREDIT'`
- balance: Decimal(15, 2) – current balance; convert with `Number()` in services
- isActive: Boolean
- createdAt, updatedAt, createdBy
- Relations: `childAccounts`, `journalLineItems`, `generalLedgerEntries`, `budgetItems`, `bankReconciliations`

### JournalEntry (`journal_entries`)
- id: String (cuid, PK)
- journalNumber: String (unique)
- date: Date
- description: String
- reference: String?
- totalDebit: Decimal(15, 2)
- totalCredit: Decimal(15, 2)
- status: JournalEntryStatus (default DRAFT)
- source: TransactionSource (default MANUAL)
- sourceId: String?
- metadata: Json?
- createdAt, updatedAt
- createdBy: String
- approvedBy: String?
- approvedAt: DateTime?
- Relations: `lineItems`, `generalLedgerEntries`

Notes
- JE is created as `DRAFT`. On approval it becomes `POSTED` (or `CANCELLED` on rejection). Only `POSTED` affects GL and reports.

### JournalLineItem (`journal_line_items`)
- id: String (cuid, PK)
- journalEntryId: String (FK -> JournalEntry)
- accountId: String (FK -> ChartOfAccount)
- description: String
- debitAmount: Decimal(15, 2) default 0
- creditAmount: Decimal(15, 2) default 0
- reference: String?
- metadata: Json?
- createdAt: DateTime

Constraints
- Each line must have either debit or credit (exclusively), amounts non-negative.

### GeneralLedgerEntry (`general_ledger_entries`)
- id: String (cuid, PK)
- accountId: String (FK -> ChartOfAccount)
- journalEntryId: String (FK -> JournalEntry)
- date: Date
- description: String
- reference: String?
- debitAmount: Decimal(15, 2)
- creditAmount: Decimal(15, 2)
- runningBalance: Decimal(15, 2)
- createdAt: DateTime

Notes
- Created per journal line on approval and used for GL and reporting. `runningBalance` may be recalculated as needed.

### FinancialStatement (`financial_statements`)
- id: String (cuid, PK)
- type: FinancialStatementType
- periodStart, periodEnd: Date
- data: Json (report payload)
- generatedAt: DateTime, generatedBy: String

### AuditTrail (`audit_trail`)
- id: String (cuid, PK)
- entityType: String
- entityId: String
- action: AuditAction
- oldValues: Json?, newValues: Json?
- userId: String
- timestamp: DateTime
- ipAddress: String?, userAgent: String?

## Budgeting and Forecasting

### Budget (`budgets`)
- id: String (cuid, PK)
- name: String
- description: String?
- fiscalYear: Int
- startDate, endDate: Date
- status: String (e.g., DRAFT, PENDING_APPROVAL, APPROVED, ACTIVE, CLOSED)
- totalBudget: Decimal(15, 2)
- createdAt, updatedAt
- createdBy, approvedBy?, approvedAt?
- Relations: `budgetItems`

### BudgetItem (`budget_items`)
- id: String (cuid, PK)
- budgetId: String (FK -> Budget)
- accountId: String (FK -> ChartOfAccount)
- category: String?
- budgetedAmount: Decimal(15, 2)
- actualAmount: Decimal(15, 2) default 0
- variance: Decimal(15, 2) default 0
- notes: String?
- createdAt, updatedAt
- Unique: (budgetId, accountId)

## Bank Reconciliation

### BankReconciliation (`bank_reconciliations`)
- id: String (cuid, PK)
- accountId: String (FK -> ChartOfAccount)
- statementDate: Date
- statementBalance, bookBalance, reconciledBalance: Decimal(15, 2)
- status: String (e.g., IN_PROGRESS, DRAFT, READY_FOR_APPROVAL, APPROVED, etc.)
- notes: String?
- createdAt, updatedAt
- createdBy, reviewedBy?, reviewedAt?
- Relations: `reconciliationItems`

### ReconciliationItem (`reconciliation_items`)
- id: String (cuid, PK)
- reconciliationId: String (FK -> BankReconciliation)
- transactionId: String? (bank or book reference)
- transactionType: String ('BANK' | 'BOOK')
- date: Date, description: String
- amount: Decimal(15, 2)
- isReconciled: Boolean
- notes: String?
- createdAt: DateTime

## Reporting Configurations

### ReportTemplate (`report_templates`)
- id: String (cuid, PK)
- name: String
- type: FinancialStatementType
- description: String?
- template: Json
- isDefault: Boolean, isActive: Boolean
- createdAt, updatedAt, createdBy

### AccountingPeriod (`accounting_periods`)
- id: String (cuid, PK)
- name: String
- startDate, endDate: Date
- fiscalYear: Int
- quarter?: Int, month?: Int
- status: String ('OPEN' | 'CLOSED' | 'LOCKED')
- closedAt?: Date, closedBy?: String
- createdAt: Date

## Vendors & AP

### Vendor (`vendors`)
- id: String (cuid, PK)
- vendorName, contactPerson?, email?, phone?, address?, taxId?
- bankDetails: Json?
- paymentTerms: PaymentTerms
- vendorType: VendorType
- isActive: Boolean
- notes?: String
- createdAt, updatedAt, createdBy
- Relations: `invoices`, `purchaseOrders`

### PurchaseOrder (`purchase_orders`)
- id: String (cuid, PK)
- poNumber: String (unique)
- vendorId: String (FK -> Vendor)
- requestedBy: String, approvedBy?: String, approvedAt?: Date
- orderDate: Date, expectedDeliveryDate?: Date
- status: PurchaseOrderStatus
- totalAmount, taxAmount?, shippingAmount?, discountAmount?, netAmount: Decimal
- department?, budgetCategory?
- deliveryAddress?, terms?, notes?
- createdAt, updatedAt, createdBy
- Relations: `lineItems`, `invoices`, `receipts`

### PurchaseOrderLineItem (`purchase_order_line_items`)
- id: String (cuid, PK)
- purchaseOrderId: String (FK -> PurchaseOrder)
- itemDescription: String, itemCode?: String
- quantity: Decimal(10,3)
- unitPrice: Decimal(15,2)
- totals: totalPrice Decimal(15,2), taxRate?, taxAmount?, discountRate?, discountAmount?, netAmount Decimal(15,2)
- receivedQuantity: Decimal(10,3)
- notes?: String
- createdAt, updatedAt

### Receipt (`receipts`) and ReceiptLineItem (`receipt_line_items`)
- Receipt: id, receiptNumber (unique), purchaseOrderId, receivedBy, receivedDate, status, notes, attachments?, createdAt, updatedAt, createdBy
- ReceiptLineItem: id, receiptId, poLineItemId?, itemDescription, itemCode?, quantityReceived, quantityAccepted, quantityRejected, unitPrice, totalValue, condition?, notes?, createdAt

### VendorInvoice (`vendor_invoices`)
- id: String (cuid, PK)
- vendorId: String (FK -> Vendor)
- purchaseOrderId?: String (FK -> PurchaseOrder)
- invoiceNumber: String
- description: String
- amount: Decimal(15,2)
- dueDate: Date
- status: VendorInvoiceStatus
- departmentId?: String, budgetCategory: String
- poNumber?: String
- attachments?: Json, lineItems?: Json, notes?: String, approvalNotes?: String
- createdAt, updatedAt, createdBy, approvedBy?, approvedAt?, paidAt?
- Relations: createdByUser, approvedByUser, department

## Workflow & Integration

### WorkflowTemplate, WorkflowTemplateStep
- Define multi-step approval templates and assignments.

### IntegrationLog (`integration_logs`)
- id: String (cuid, PK)
- sourceSystem: String (e.g., PAYMENT, FEE_ASSIGNMENT)
- sourceId: String
- targetSystem: String (default ACCOUNTING)
- targetId?: String
- operation: String
- status: String (SUCCESS | FAILED | PENDING)
- requestData?: Json, responseData?: Json, errorMessage?: String
- processedAt: Date, retryCount: Int

## Notes and Conventions

- Always convert Decimal to Number at service/route boundaries for UI and calculations.
- Journal entries are `DRAFT` until approved; GL posting happens on approval, not creation.
- Use account code patterns to map Cash (e.g., 1010/1110) and AR (e.g., 1020/1120) when resolving default accounts.
- Audit trails are created for key lifecycle events (JE create/approve/reject, COA create/update, Vendor ops, budgets).
