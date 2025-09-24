# Gabay Accounting System - Visual Diagrams

## System Architecture Diagram

```mermaid
graph TB
    subgraph "External Systems"
        PS[Payment System]
        FAS[Fee Assignment System]
        CS[Cashier System]
        MS[Manual Entry]
    end
    
    subgraph "Accounting Service Layer"
        AS[Accounting Service]
        PI[Payment Integration]
        FAI[Fee Assignment Integration]
        CI[Cashier Integration]
        JEC[Journal Entry Creator]
        VAL[Validation Engine]
        GLP[General Ledger Processor]
    end
    
    subgraph "Data Layer"
        COA[(Chart of Accounts)]
        JE[(Journal Entries)]
        GL[(General Ledger)]
        AT[(Audit Trail)]
        FS[(Financial Statements)]
        IL[(Integration Logs)]
    end
    
    subgraph "Reporting Layer"
        TB[Trial Balance]
        BS[Balance Sheet]
        IS[Income Statement]
        CF[Cash Flow Statement]
        CR[Custom Reports]
    end
    
    PS --> PI
    FAS --> FAI
    CS --> CI
    MS --> AS
    
    PI --> JEC
    FAI --> JEC
    CI --> JEC
    AS --> JEC
    
    JEC --> VAL
    VAL --> GLP
    
    GLP --> COA
    GLP --> JE
    GLP --> GL
    GLP --> AT
    
    GL --> TB
    GL --> BS
    GL --> IS
    GL --> CF
    GL --> CR
    
    AS --> FS
    AS --> IL
```

## Double-Entry Bookkeeping Flow

```mermaid
flowchart TD
    A[Transaction Occurs] --> B{Transaction Type}
    
    B -->|Payment| C[Payment Integration]
    B -->|Fee Assignment| D[Fee Assignment Integration]
    B -->|Cash Transaction| E[Cashier Integration]
    B -->|Manual Entry| F[Manual Journal Entry]
    
    C --> G[Create Journal Entry]
    D --> G
    E --> G
    F --> G
    
    G --> H[Validate Debits = Credits]
    H -->|Valid| I[Post to General Ledger]
    H -->|Invalid| J[Reject Transaction]
    
    I --> K[Update Account Balances]
    K --> L[Create Audit Trail]
    L --> M[Generate Reports]
    
    J --> N[Return Error]
```

## Journal Entry Processing Workflow

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> PendingApproval: Submit for Approval
    Draft --> Cancelled: Cancel
    
    PendingApproval --> Approved: Approve
    PendingApproval --> Rejected: Reject
    PendingApproval --> Cancelled: Cancel
    
    Approved --> Posted: Post to GL
    Approved --> Cancelled: Cancel
    
    Posted --> Reversed: Reverse Entry
    
    Rejected --> Draft: Modify and Resubmit
    Rejected --> Cancelled: Cancel
    
    Cancelled --> [*]
    Reversed --> [*]
```

## Account Balance Calculation Flow

```mermaid
flowchart LR
    subgraph "Account Types"
        A1[Assets]
        L1[Liabilities]
        E1[Equity]
        R1[Revenue]
        X1[Expenses]
    end
    
    subgraph "Normal Balances"
        A2[Debit]
        L2[Credit]
        E2[Credit]
        R2[Credit]
        X2[Debit]
    end
    
    subgraph "Balance Calculation"
        A3[Debits - Credits]
        L3[Credits - Debits]
        E3[Credits - Debits]
        R3[Credits - Debits]
        X3[Debits - Credits]
    end
    
    A1 --> A2 --> A3
    L1 --> L2 --> L3
    E1 --> E2 --> E3
    R1 --> R2 --> R3
    X1 --> X2 --> X3
```

## Payment Integration Flow

```mermaid
sequenceDiagram
    participant PS as Payment System
    participant AS as Accounting Service
    participant DB as Database
    participant GL as General Ledger
    
    PS->>AS: processPaymentIntegration(paymentData)
    AS->>AS: validatePaymentData()
    AS->>AS: mapPaymentToAccounts()
    
    AS->>DB: createJournalEntry()
    Note over AS,DB: Debit: Cash Account<br/>Credit: Revenue/AR Account
    
    AS->>AS: validateJournalBalance()
    AS->>GL: postToGeneralLedger()
    AS->>DB: updateAccountBalances()
    AS->>DB: createAuditTrail()
    AS->>DB: logIntegration()
    
    AS-->>PS: success response
```

## Fee Assignment Integration Flow

```mermaid
sequenceDiagram
    participant FAS as Fee Assignment System
    participant AS as Accounting Service
    participant DB as Database
    participant GL as General Ledger
    
    FAS->>AS: processFeeAssignmentIntegration(feeData)
    AS->>AS: validateFeeData()
    AS->>AS: mapFeeToAccounts()
    
    AS->>DB: createJournalEntry()
    Note over AS,DB: Debit: Accounts Receivable<br/>Credit: Revenue Account
    
    AS->>AS: validateJournalBalance()
    AS->>GL: postToGeneralLedger()
    AS->>DB: updateAccountBalances()
    AS->>DB: createAuditTrail()
    AS->>DB: logIntegration()
    
    AS-->>FAS: success response
```

## Financial Statement Generation Process

```mermaid
flowchart TD
    A[Request Financial Statement] --> B{Statement Type}
    
    B -->|Balance Sheet| C[Get Asset Accounts]
    B -->|Income Statement| D[Get Revenue/Expense Accounts]
    B -->|Cash Flow| E[Get Cash Accounts]
    B -->|Trial Balance| F[Get All Accounts]
    
    C --> G[Calculate Current Assets]
    C --> H[Calculate Fixed Assets]
    C --> I[Calculate Current Liabilities]
    C --> J[Calculate Long-term Liabilities]
    C --> K[Calculate Equity]
    
    D --> L[Calculate Total Revenue]
    D --> M[Calculate Total Expenses]
    D --> N[Calculate Net Income]
    
    E --> O[Calculate Operating Cash Flow]
    E --> P[Calculate Investing Cash Flow]
    E --> Q[Calculate Financing Cash Flow]
    
    F --> R[List All Account Balances]
    F --> S[Verify Debit/Credit Balance]
    
    G --> T[Generate Balance Sheet]
    H --> T
    I --> T
    J --> T
    K --> T
    
    L --> U[Generate Income Statement]
    M --> U
    N --> U
    
    O --> V[Generate Cash Flow Statement]
    P --> V
    Q --> V
    
    R --> W[Generate Trial Balance]
    S --> W
    
    T --> X[Format and Return Report]
    U --> X
    V --> X
    W --> X
```

## Data Validation and Error Handling

```mermaid
flowchart TD
    A[Transaction Input] --> B[Schema Validation]
    B -->|Pass| C[Business Rule Validation]
    B -->|Fail| D[Return Validation Error]
    
    C -->|Pass| E[Balance Validation]
    C -->|Fail| F[Return Business Rule Error]
    
    E -->|Pass| G[Account Existence Check]
    E -->|Fail| H[Return Balance Error]
    
    G -->|Pass| I[Permission Check]
    G -->|Fail| J[Return Account Error]
    
    I -->|Pass| K[Process Transaction]
    I -->|Fail| L[Return Permission Error]
    
    K --> M[Success Response]
    
    D --> N[Log Error]
    F --> N
    H --> N
    J --> N
    L --> N
    
    N --> O[Return Error Response]
```

## Audit Trail and Compliance

```mermaid
flowchart LR
    subgraph "User Actions"
        A1[Create]
        A2[Update]
        A3[Delete]
        A4[Approve]
        A5[Reverse]
    end
    
    subgraph "Audit Capture"
        B1[User ID]
        B2[Timestamp]
        B3[IP Address]
        B4[Old Values]
        B5[New Values]
        B6[Action Type]
    end
    
    subgraph "Audit Storage"
        C1[(Audit Trail Table)]
    end
    
    subgraph "Compliance Reports"
        D1[User Activity Report]
        D2[Change History Report]
        D3[Access Log Report]
        D4[Data Integrity Report]
    end
    
    A1 --> B1
    A2 --> B2
    A3 --> B3
    A4 --> B4
    A5 --> B5
    
    B1 --> C1
    B2 --> C1
    B3 --> C1
    B4 --> C1
    B5 --> C1
    B6 --> C1
    
    C1 --> D1
    C1 --> D2
    C1 --> D3
    C1 --> D4
```

## Bank Reconciliation Process

```mermaid
flowchart TD
    A[Bank Statement Import] --> B[Extract Transactions]
    B --> C[Match with Book Transactions]
    
    C --> D{Transaction Matched?}
    D -->|Yes| E[Mark as Reconciled]
    D -->|No| F[Outstanding Item]
    
    E --> G[Update Reconciliation Status]
    F --> H[Investigate Discrepancy]
    
    H --> I{Discrepancy Type}
    I -->|Bank Error| J[Contact Bank]
    I -->|Book Error| K[Create Adjustment Entry]
    I -->|Timing Difference| L[Note for Next Period]
    
    G --> M[Calculate Reconciled Balance]
    J --> M
    K --> M
    L --> M
    
    M --> N[Generate Reconciliation Report]
    N --> O[Review and Approve]
```

## Chart of Accounts Hierarchy

```mermaid
graph TD
    A[Chart of Accounts] --> B[1000-1999: Assets]
    A --> C[2000-2999: Liabilities]
    A --> D[3000-3999: Equity]
    A --> E[4000-4999: Revenue]
    A --> F[5000-5999: Expenses]
    
    B --> B1[1000-1099: Current Assets]
    B --> B2[1100-1199: Inventory]
    B --> B3[1200-1999: Fixed Assets]
    
    B1 --> B11[1010: Cash - Operating]
    B1 --> B12[1020: Cash - Savings]
    B1 --> B13[1030: Accounts Receivable]
    B1 --> B14[1040: Prepaid Expenses]
    
    C --> C1[2000-2099: Current Liabilities]
    C --> C2[2100-2999: Long-term Liabilities]
    
    C1 --> C11[2010: Accounts Payable]
    C1 --> C12[2020: Accrued Expenses]
    C1 --> C13[2030: Unearned Revenue]
    
    D --> D1[3010: Owner's Equity]
    D --> D2[3020: Retained Earnings]
    
    E --> E1[4000-4099: Tuition Revenue]
    E --> E2[4100-4199: Fee Revenue]
    E --> E3[4200-4299: Other Revenue]
    
    F --> F1[5000-5099: Operating Expenses]
    F --> F2[5100-5199: Administrative Expenses]
    F --> F3[5200-5299: Facility Expenses]
```

## Integration Error Handling

```mermaid
flowchart TD
    A[Integration Request] --> B[Validate Request Data]
    B -->|Valid| C[Process Integration]
    B -->|Invalid| D[Log Validation Error]
    
    C --> E{Processing Success?}
    E -->|Yes| F[Log Success]
    E -->|No| G[Log Processing Error]
    
    D --> H[Increment Retry Count]
    G --> H
    
    H --> I{Retry Count < Max?}
    I -->|Yes| J[Schedule Retry]
    I -->|No| K[Mark as Failed]
    
    J --> L[Wait for Retry Interval]
    L --> A
    
    F --> M[Return Success Response]
    K --> N[Send Alert to Admin]
    N --> O[Return Error Response]
```

## Performance Monitoring

```mermaid
flowchart LR
    subgraph "Metrics Collection"
        A1[Transaction Volume]
        A2[Response Times]
        A3[Error Rates]
        A4[Database Performance]
        A5[Integration Success Rates]
    end
    
    subgraph "Monitoring Dashboard"
        B1[Real-time Metrics]
        B2[Historical Trends]
        B3[Alert Thresholds]
        B4[Performance Reports]
    end
    
    subgraph "Alerting System"
        C1[High Error Rate Alert]
        C2[Slow Response Alert]
        C3[Integration Failure Alert]
        C4[Database Issue Alert]
    end
    
    A1 --> B1
    A2 --> B1
    A3 --> B1
    A4 --> B1
    A5 --> B1
    
    B1 --> B2
    B2 --> B3
    B3 --> C1
    B3 --> C2
    B3 --> C3
    B3 --> C4
    
    B1 --> B4
```

## Security and Access Control

```mermaid
flowchart TD
    A[User Request] --> B[Authentication Check]
    B -->|Authenticated| C[Authorization Check]
    B -->|Not Authenticated| D[Return 401 Unauthorized]
    
    C --> E{Has Permission?}
    E -->|Yes| F[Process Request]
    E -->|No| G[Return 403 Forbidden]
    
    F --> H[Log User Action]
    H --> I[Execute Business Logic]
    I --> J[Return Response]
    
    subgraph "Permission Matrix"
        K[View Accounts]
        L[Create Journal Entries]
        M[Approve Transactions]
        N[Generate Reports]
        O[Manage Chart of Accounts]
    end
    
    subgraph "User Roles"
        P[Accountant]
        Q[Accounting Manager]
        R[Financial Controller]
        S[Auditor]
    end
    
    P --> K
    P --> L
    Q --> K
    Q --> L
    Q --> M
    Q --> N
    R --> K
    R --> L
    R --> M
    R --> N
    R --> O
    S --> K
    S --> N
```

These diagrams provide a comprehensive visual representation of the Gabay Accounting System's architecture, data flow, and operational processes. They complement the main documentation and help stakeholders understand the system's complexity and integration points.