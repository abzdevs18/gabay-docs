# Cashiering System Database Schema

This document outlines the database schema for the Cashiering System, including models, relationships, and field descriptions.

## Core Models

### CashierSession

```typescript
model CashierSession {
  id           String        @id @default(cuid())
  cashierId    String
  startBalance Float
  endBalance   Float?
  isActive     Boolean       @default(true)
  startTime    DateTime      @default(now())
  endTime      DateTime?
  cashier      User          @relation(fields: [cashierId], references: [id])
  transactions Transaction[]
  adjustments  Adjustment[]
  
  // Denominations for start and end balance
  startDenominations Json?
  endDenominations   Json?
  
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt
}
```

The CashierSession model tracks a single session of a cashier, from opening to closing the cash drawer.

**Key Fields:**
- `id`: Unique identifier for the session
- `cashierId`: ID of the user acting as cashier
- `startBalance`: Opening balance of the cash drawer
- `endBalance`: Closing balance (null if session is still active)
- `isActive`: Whether the session is currently active
- `startDenominations`: JSON object tracking bill/coin counts at opening
- `endDenominations`: JSON object tracking bill/coin counts at closing

### Transaction

```typescript
model Transaction {
  id              String         @id @default(cuid())
  amount          Float
  paymentMethod   String         // CASH, CHECK, etc.
  referenceNumber String?        // For checks, etc.
  cashierId       String
  sessionId       String
  status          String         @default("COMPLETED") // COMPLETED, VOIDED, PENDING
  voidReason      String?
  voidedAt        DateTime?
  
  cashier         User           @relation(fields: [cashierId], references: [id])
  session         CashierSession @relation(fields: [sessionId], references: [id])
  feePayments     FeePayment[]
  
  createdAt       DateTime       @default(now())
  updatedAt       DateTime       @updatedAt
}
```

The Transaction model represents a single payment transaction processed by a cashier.

**Key Fields:**
- `id`: Unique identifier for the transaction
- `amount`: Monetary amount of the transaction
- `paymentMethod`: Method of payment (CASH, CHECK, etc.)
- `referenceNumber`: Optional reference number for the payment
- `cashierId`: ID of the cashier who processed the transaction
- `sessionId`: ID of the session during which the transaction was processed
- `status`: Current status of the transaction
- `voidReason`: Reason if transaction was voided
- `voidedAt`: Timestamp when transaction was voided

### Adjustment

```typescript
model Adjustment {
  id             String         @id @default(cuid())
  sessionId      String
  amount         Float
  adjustmentType String         // ADD or REMOVE
  reason         String
  
  session        CashierSession @relation(fields: [sessionId], references: [id])
  
  createdAt      DateTime       @default(now())
  updatedAt      DateTime       @updatedAt
}
```

The Adjustment model tracks additions or removals of cash from the drawer during a session.

**Key Fields:**
- `id`: Unique identifier for the adjustment
- `sessionId`: ID of the session during which the adjustment was made
- `amount`: Monetary amount of the adjustment
- `adjustmentType`: Whether cash was added or removed
- `reason`: Explanation for the adjustment

### FeePayment

```typescript
model FeePayment {
  id            String      @id @default(cuid())
  transactionId String
  feeId         String
  amount        Float
  studentId     String
  
  transaction   Transaction @relation(fields: [transactionId], references: [id])
  fee           Fee         @relation(fields: [feeId], references: [id])
  student       Student     @relation(fields: [studentId], references: [id])
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
}
```

The FeePayment model links transactions to specific fees and students.

**Key Fields:**
- `id`: Unique identifier for the fee payment
- `transactionId`: ID of the transaction
- `feeId`: ID of the fee being paid
- `amount`: Monetary amount applied to this fee
- `studentId`: ID of the student for whom the fee is being paid

## Extended Models

### User (Extended)

```typescript
model User {
  // Existing fields...
  
  // Cashier-related fields
  cashierSessions CashierSession[]
  transactions    Transaction[]
  isCashier       Boolean         @default(false)
  cashierMetadata Json?           // Stores cashier-specific settings
}
```

Extensions to the User model to support cashier functionality.

### Fee (Relationship)

```typescript
model Fee {
  // Existing fields...
  
  // Cashier-related fields
  feePayments FeePayment[]
}
```

### Student (Relationship)

```typescript
model Student {
  // Existing fields...
  
  // Cashier-related fields
  feePayments FeePayment[]
}
```

## Relationship Diagram

```
CashierSession 1──* Transaction
       │                │
       │                │
       │                │
       │                *
User ──┘           FeePayment
       │                │
       │                │
       *                │
Transaction             │
       │                │
       └────────────────┘
                │
                │
                *
      Fee ── Student
```

## Indexes and Performance Considerations

For optimal performance, the following indexes are recommended:

1. `Transaction.sessionId` - For quick lookup of transactions by session
2. `Transaction.cashierId` - For quick lookup of transactions by cashier
3. `FeePayment.transactionId` - For quick lookup of payments by transaction
4. `CashierSession.cashierId` - For quick lookup of sessions by cashier
5. `CashierSession.isActive` - For quick lookup of active sessions

## Data Validation Rules

- `CashierSession.endBalance` must be null when `isActive` is true
- `CashierSession.endTime` must be null when `isActive` is true
- `Transaction.voidReason` must not be null when `status` is "VOIDED"
- `Transaction.voidedAt` must not be null when `status` is "VOIDED"
- `Adjustment.amount` must be positive
- Sum of `FeePayment.amount` for a transaction should equal `Transaction.amount` 