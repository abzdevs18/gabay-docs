# Gabay Accounting System Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Accounting Workflow](#accounting-workflow)
3. [System Components](#system-components)
4. [Data Flow Process](#data-flow-process)
5. [Accounting Principles](#accounting-principles)
6. [Data Validation & Reconciliation](#data-validation--reconciliation)
7. [Integration Points](#integration-points)
8. [API Reference](#api-reference)

---

## System Overview

The Gabay Accounting System is a comprehensive double-entry bookkeeping system designed to handle all financial transactions within the educational management platform. It provides complete financial tracking from transaction entry to financial statement generation.

### Key Features
- **Double-Entry Bookkeeping**: Ensures accounting equation balance (Assets = Liabilities + Equity)
- **Chart of Accounts Management**: Hierarchical account structure with customizable account codes
- **Journal Entry Processing**: Complete transaction recording with approval workflows
- **General Ledger**: Centralized transaction repository with running balances
- **Financial Reporting**: Automated generation of financial statements
- **Integration Support**: Seamless connection with payment, fee assignment, and cashiering systems
- **Audit Trail**: Complete transaction history and change tracking

---

## Accounting Workflow

### Complete Transaction Lifecycle

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Source System  │───▶│ Journal Entry   │───▶│ General Ledger  │
│  (Payment/Fee)  │    │   Creation      │    │    Posting     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Validation    │    │ Account Balance │
                       │   & Approval    │    │    Updates     │
                       └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Audit Trail   │    │   Financial     │
                       │    Creation     │    │   Statements    │
                       └─────────────────┘    └─────────────────┘
```

### Workflow Steps

1. **Transaction Initiation**
   - Source systems (Payment, Fee Assignment, Cashier) generate transactions
   - Manual journal entries created by accounting staff
   - System validates transaction data and business rules

2. **Journal Entry Creation**
   - Transactions converted to double-entry journal entries
   - Automatic account mapping based on transaction type
   - Debit and credit amounts calculated and balanced

3. **Validation & Approval**
   - System validates accounting equation balance
   - Business rule validation (account types, amounts, dates)
   - Optional approval workflow for manual entries

4. **General Ledger Posting**
   - Approved entries posted to general ledger
   - Running balances calculated for each account
   - Account balances updated in real-time

5. **Financial Reporting**
   - Trial balance generation
   - Financial statements (Balance Sheet, Income Statement, Cash Flow)
   - Custom reports and analytics

---

## System Components

### 1. Chart of Accounts (`ChartOfAccount`)

**Purpose**: Defines the structure of all accounts used in the accounting system.

**Key Features**:
- Hierarchical account structure with parent-child relationships
- Account type classification (Asset, Liability, Equity, Revenue, Expense)
- Unique account codes for easy identification
- Normal balance designation (Debit/Credit)
- Active/inactive status management

**Account Code Structure**:
```
1000-1999: Assets
  1000-1099: Current Assets (Cash, Accounts Receivable)
  1100-1199: Inventory
  1200-1999: Fixed Assets

2000-2999: Liabilities
  2000-2099: Current Liabilities (Accounts Payable)
  2100-2999: Long-term Liabilities

3000-3999: Equity
  3000-3099: Owner's Equity
  3100-3199: Retained Earnings

4000-4999: Revenue
  4000-4099: Tuition Revenue
  4100-4199: Fee Revenue

5000-5999: Expenses
  5000-5099: Operating Expenses
  5100-5199: Administrative Expenses
```

### 2. Journal Entries (`JournalEntry` & `JournalLineItem`)

**Purpose**: Records all financial transactions using double-entry bookkeeping.

**Components**:
- **Journal Entry Header**: Contains transaction metadata (date, description, totals)
- **Journal Line Items**: Individual debit/credit entries for each account affected

**Status Flow**:
```
DRAFT → PENDING_APPROVAL → APPROVED → POSTED
  ↓           ↓              ↓         ↓
REJECTED   CANCELLED     CANCELLED  REVERSED
```

### 3. General Ledger (`GeneralLedgerEntry`)

**Purpose**: Maintains chronological record of all posted transactions by account.

**Features**:
- Running balance calculation for each account
- Transaction history with full audit trail
- Date-based filtering and reporting
- Account-specific transaction summaries

### 4. Financial Statements (`FinancialStatement`)

**Purpose**: Generates standard financial reports from general ledger data.

**Report Types**:
- **Balance Sheet**: Assets, Liabilities, and Equity at a point in time
- **Income Statement**: Revenue and Expenses over a period
- **Cash Flow Statement**: Cash inflows and outflows
- **Trial Balance**: Account balances verification
- **General Ledger Report**: Detailed transaction listings

### 5. Audit Trail (`AuditTrail`)

**Purpose**: Maintains complete history of all system changes for compliance and security.

**Tracked Actions**:
- CREATE: New record creation
- UPDATE: Record modifications
- DELETE: Record deletions
- APPROVE: Transaction approvals
- REVERSE: Transaction reversals
- CANCEL: Transaction cancellations

---

## Data Flow Process

### 1. From Source Documents to Journal Entries

```
┌─────────────────┐
│ Source Document │
│ (Payment/Fee)   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Data Validation │
│ & Mapping       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Journal Entry   │
│ Generation      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Balance         │
│ Verification    │
└─────────────────┘
```

**Process Details**:

1. **Source Document Processing**
   - Payment transactions from payment gateway
   - Fee assignments from student billing
   - Cash transactions from cashier system
   - Manual adjustments from accounting staff

2. **Data Validation & Mapping**
   - Validate transaction amounts and dates
   - Map transaction types to appropriate accounts
   - Apply business rules and constraints
   - Generate unique journal numbers

3. **Journal Entry Generation**
   - Create journal entry header with metadata
   - Generate corresponding debit and credit line items
   - Ensure accounting equation balance (Debits = Credits)
   - Set appropriate status (DRAFT/POSTED)

### 2. Through the General Ledger

```
┌─────────────────┐
│ Posted Journal  │
│ Entry           │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ General Ledger  │
│ Entry Creation  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Running Balance │
│ Calculation     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Account Balance │
│ Update          │
└─────────────────┘
```

**Process Details**:

1. **General Ledger Entry Creation**
   - Create individual ledger entries for each journal line item
   - Maintain chronological order by transaction date
   - Link back to original journal entry for audit trail

2. **Running Balance Calculation**
   - Calculate cumulative balance for each account
   - Consider account's normal balance (Debit/Credit)
   - Update running totals in real-time

3. **Account Balance Update**
   - Update chart of accounts with current balances
   - Maintain balance history for reporting
   - Trigger balance alerts if configured

### 3. To Trial Balance and Financial Statements

```
┌─────────────────┐
│ General Ledger  │
│ Data            │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Trial Balance   │
│ Generation      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Financial       │
│ Statements      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Report          │
│ Distribution    │
└─────────────────┘
```

**Process Details**:

1. **Trial Balance Generation**
   - Aggregate account balances by account type
   - Verify total debits equal total credits
   - Generate balance verification report

2. **Financial Statement Preparation**
   - **Balance Sheet**: Group accounts by Assets, Liabilities, Equity
   - **Income Statement**: Calculate Revenue minus Expenses
   - **Cash Flow**: Track cash account movements

3. **Report Distribution**
   - Generate reports in multiple formats (PDF, Excel, JSON)
   - Schedule automated report generation
   - Distribute to authorized users

---

## Accounting Principles

### 1. Double-Entry Bookkeeping

**Principle**: Every transaction affects at least two accounts, with total debits equaling total credits.

**Implementation**:
- All journal entries must balance (∑Debits = ∑Credits)
- System validates balance before posting
- Automatic rejection of unbalanced entries

**Example - Student Payment**:
```
Debit: Cash Account           $1,000
Credit: Tuition Revenue       $1,000
```

### 2. Accounting Equation

**Formula**: Assets = Liabilities + Equity

**Maintenance**:
- Real-time balance verification
- Automated equation checking
- Alert system for imbalances

### 3. Revenue Recognition

**Principle**: Revenue recognized when earned, not when cash received.

**Implementation**:
- Fee assignments create receivables
- Payments reduce receivables and increase cash
- Proper timing of revenue recognition

### 4. Matching Principle

**Principle**: Expenses matched with related revenues in the same period.

**Implementation**:
- Accrual-based accounting
- Proper period allocation
- Adjustment entries for prepaid/accrued items

### 5. Consistency Principle

**Principle**: Same accounting methods used consistently across periods.

**Implementation**:
- Standardized account mapping
- Consistent transaction processing
- Documented accounting policies

---

## Data Validation & Reconciliation

### 1. Input Validation

**Transaction Level Validation**:
- Amount validation (positive values, decimal precision)
- Date validation (reasonable date ranges)
- Account existence verification
- Required field validation

**Business Rule Validation**:
- Account type compatibility
- Transaction source authorization
- Amount limits and thresholds
- Period closing restrictions

### 2. Balance Reconciliation

**Daily Reconciliation Process**:
```
1. Generate trial balance
2. Verify debit/credit equality
3. Compare with previous period
4. Identify and investigate variances
5. Generate reconciliation report
```

**Bank Reconciliation**:
- Compare book balances with bank statements
- Identify outstanding items
- Record necessary adjustments
- Maintain reconciliation history

### 3. Integration Reconciliation

**Payment System Integration**:
- Verify payment amounts match journal entries
- Reconcile payment gateway fees
- Handle failed/reversed payments
- Generate integration reports

**Fee Assignment Integration**:
- Ensure fee assignments create proper receivables
- Verify student account balances
- Handle fee adjustments and waivers
- Maintain student financial history

### 4. Audit Controls

**Segregation of Duties**:
- Separate transaction entry and approval
- Independent reconciliation process
- Management review and authorization

**Audit Trail Maintenance**:
- Complete transaction history
- User activity logging
- Change tracking and approval
- Backup and recovery procedures

---

## Integration Points

### 1. Payment System Integration

**Integration Flow**:
```
Payment Gateway → Payment Service → Accounting Service
                      ↓
              Journal Entry Creation
                      ↓
              General Ledger Posting
```

**Journal Entry Pattern**:
```
Debit: Cash/Bank Account
Credit: Accounts Receivable (if paying outstanding fees)
Credit: Revenue Account (if direct payment)
```

**Integration Service**: `processPaymentIntegration()`
- Receives payment data from PaymentService
- Maps payment to appropriate accounts
- Creates balanced journal entries
- Handles payment fees and adjustments

### 2. Fee Assignment Integration

**Integration Flow**:
```
Fee Assignment → Fee Assignment Service → Accounting Service
                        ↓
                Journal Entry Creation
                        ↓
                General Ledger Posting
```

**Journal Entry Pattern**:
```
Debit: Accounts Receivable
Credit: Revenue Account (by fee type)
```

**Integration Service**: `processFeeAssignmentIntegration()`
- Receives fee assignment data
- Creates receivable entries
- Maps fees to revenue accounts
- Handles fee adjustments and waivers

### 3. Cashier System Integration

**Integration Flow**:
```
Cashier Terminal → Cashier Service → Accounting Service
                      ↓
              Cash Transaction Recording
                      ↓
              Daily Cash Reconciliation
```

**Journal Entry Pattern**:
```
Debit: Cash Account
Credit: Revenue Account
```

**Features**:
- Real-time cash balance tracking
- Daily cash reconciliation
- Cash over/short handling
- Cashier session management

---

## API Reference

### Chart of Accounts

#### Create Account
```typescript
POST /api/v2/accounting/chart-of-accounts

Request Body:
{
  "accountCode": "1010",
  "accountName": "Cash - Operating",
  "accountType": "ASSET",
  "parentAccountId": "parent-account-id",
  "description": "Main operating cash account",
  "normalBalance": "DEBIT"
}

Response:
{
  "success": true,
  "data": {
    "id": "account-id",
    "accountCode": "1010",
    "accountName": "Cash - Operating",
    "accountType": "ASSET",
    "balance": 0,
    "isActive": true,
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

#### Get Accounts
```typescript
GET /api/v2/accounting/chart-of-accounts

Query Parameters:
- accountType?: AccountType
- includeInactive?: boolean

Response:
{
  "success": true,
  "data": [
    {
      "id": "account-id",
      "accountCode": "1010",
      "accountName": "Cash - Operating",
      "accountType": "ASSET",
      "balance": 15000.00,
      "isActive": true
    }
  ]
}
```

### Journal Entries

#### Create Journal Entry
```typescript
POST /api/v2/accounting/journal-entries

Request Body:
{
  "date": "2024-01-15",
  "description": "Student tuition payment",
  "reference": "PAY-001",
  "lineItems": [
    {
      "accountId": "cash-account-id",
      "description": "Cash received",
      "debitAmount": 1000.00,
      "creditAmount": 0
    },
    {
      "accountId": "revenue-account-id",
      "description": "Tuition revenue",
      "debitAmount": 0,
      "creditAmount": 1000.00
    }
  ]
}

Response:
{
  "success": true,
  "data": {
    "id": "journal-entry-id",
    "journalNumber": "JE-2024-001",
    "date": "2024-01-15",
    "description": "Student tuition payment",
    "totalDebit": 1000.00,
    "totalCredit": 1000.00,
    "status": "POSTED",
    "lineItems": [...]
  }
}
```

#### Get Journal Entries
```typescript
GET /api/v2/accounting/journal-entries

Query Parameters:
- status?: string
- source?: string
- dateFrom?: string
- dateTo?: string
- page?: number
- limit?: number

Response:
{
  "success": true,
  "data": {
    "journalEntries": [...],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 100,
      "totalPages": 2
    }
  }
}
```

### Financial Reports

#### Generate Trial Balance
```typescript
GET /api/v2/accounting/reports/trial-balance

Query Parameters:
- asOfDate: string (required)
- includeInactive?: boolean
- accountTypes?: AccountType[]

Response:
{
  "success": true,
  "data": [
    {
      "accountId": "account-id",
      "accountCode": "1010",
      "accountName": "Cash - Operating",
      "accountType": "ASSET",
      "debitBalance": 15000.00,
      "creditBalance": 0,
      "normalBalance": "DEBIT"
    }
  ]
}
```

#### Generate Financial Statement
```typescript
GET /api/v2/accounting/reports/financial-statement

Query Parameters:
- type: FinancialStatementType (required)
- periodStart: string (required)
- periodEnd: string (required)

Response:
{
  "success": true,
  "data": {
    "id": "statement-id",
    "type": "BALANCE_SHEET",
    "periodStart": "2024-01-01",
    "periodEnd": "2024-01-31",
    "data": {
      "assets": {...},
      "liabilities": {...},
      "equity": {...}
    },
    "generatedAt": "2024-01-31T23:59:59Z"
  }
}
```

---

## Visual Data Flow Diagrams

### Complete Accounting Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GABAY ACCOUNTING SYSTEM                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PAYMENT       │    │ FEE ASSIGNMENT  │    │    CASHIER      │
│   SYSTEM        │    │    SYSTEM       │    │    SYSTEM       │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ACCOUNTING SERVICE                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Payment         │  │ Fee Assignment  │  │ Cash            │ │
│  │ Integration     │  │ Integration     │  │ Integration     │ │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘ │
│            │                    │                    │         │
│            └────────────────────┼────────────────────┘         │
│                                 ▼                              │
│                    ┌─────────────────┐                        │
│                    │ JOURNAL ENTRY   │                        │
│                    │   CREATION      │                        │
│                    └─────────┬───────┘                        │
│                              │                                │
│                              ▼                                │
│                    ┌─────────────────┐                        │
│                    │ VALIDATION &    │                        │
│                    │ BALANCE CHECK   │                        │
│                    └─────────┬───────┘                        │
│                              │                                │
│                              ▼                                │
│                    ┌─────────────────┐                        │
│                    │ GENERAL LEDGER  │                        │
│                    │    POSTING      │                        │
│                    └─────────┬───────┘                        │
└──────────────────────────────┼────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA STORAGE                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ CHART OF        │  │ JOURNAL         │  │ GENERAL         │ │
│  │ ACCOUNTS        │  │ ENTRIES         │  │ LEDGER          │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ AUDIT           │  │ FINANCIAL       │  │ INTEGRATION     │ │
│  │ TRAIL           │  │ STATEMENTS      │  │ LOGS            │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FINANCIAL REPORTING                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ TRIAL           │  │ BALANCE         │  │ INCOME          │ │
│  │ BALANCE         │  │ SHEET           │  │ STATEMENT       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ CASH FLOW       │  │ GENERAL LEDGER  │  │ CUSTOM          │ │
│  │ STATEMENT       │  │ REPORT          │  │ REPORTS         │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Transaction Processing Flow

```
┌─────────────────┐
│ TRANSACTION     │
│ SOURCE          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ DATA            │
│ VALIDATION      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ ACCOUNT         │
│ MAPPING         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ JOURNAL ENTRY   │
│ CREATION        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ BALANCE         │
│ VERIFICATION    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ GENERAL LEDGER  │
│ POSTING         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ ACCOUNT BALANCE │
│ UPDATE          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ AUDIT TRAIL     │
│ CREATION        │
└─────────────────┘
```

---

## Conclusion

The Gabay Accounting System provides a robust, compliant, and integrated financial management solution. Its double-entry bookkeeping foundation ensures accuracy and auditability, while its integration capabilities provide seamless data flow from operational systems to financial reporting.

Key benefits:
- **Accuracy**: Double-entry system with automatic balance verification
- **Compliance**: Complete audit trail and standard accounting practices
- **Integration**: Seamless connection with payment and billing systems
- **Reporting**: Comprehensive financial statements and custom reports
- **Scalability**: Designed to handle growing transaction volumes
- **Security**: Role-based access and complete change tracking

For technical implementation details, refer to the source code in `/api/src/services/accounting.service.ts` and the Prisma schema at `/api/prisma/schema/accounting.prisma`.