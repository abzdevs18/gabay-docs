# Transaction Data Handling

This document provides detailed information about how transaction data is handled in the Cashiering System, including formatting, storage, and retrieval.

## Transaction Structure

Each transaction in the Cashiering System contains the following core data:

```typescript
interface Transaction {
  id: string;
  amount: number;
  paymentMethod: string;
  referenceNumber?: string;
  cashierId: string;
  sessionId: string;
  status: "COMPLETED" | "VOIDED" | "PENDING";
  createdAt: Date;
  updatedAt: Date;
  voidReason?: string;
  voidedAt?: Date;
  feePayments?: FeePayment[];
  // Additional metadata
}
```

### Fee Payments

Transactions can be linked to specific fee payments:

```typescript
interface FeePayment {
  id: string;
  transactionId: string;
  feeId: string;
  amount: number;
  studentId: string;
  fee?: Fee;
  student?: Student;
  // Additional fields
}
```

## Student Data Handling

### Extraction Logic

Student information is extracted from the transaction's fee payments. The system:

1. Gets the first fee payment from the transaction that contains student data
2. Extracts the student ID and any available name information
3. Creates a formatted student object for display purposes

### Formatting Implementation

The formatting logic handles variations in the Student model's field structure:

```typescript
// In CashierService
private formatTransactionForDisplay(transaction: Transaction): FormattedTransaction {
  // Extract student data from the first fee payment
  const studentData = transaction.feePayments?.[0]?.student;
  
  // Create a student object with fallback values
  const student = {
    id: studentData?.id || 'Unknown',
    name: this.formatStudentName(studentData)
  };
  
  return {
    id: transaction.id,
    amount: transaction.amount,
    createdAt: transaction.createdAt.toISOString(),
    paymentMethod: transaction.paymentMethod,
    referenceNumber: transaction.referenceNumber,
    student,
    cashierId: transaction.cashierId,
    sessionId: transaction.sessionId,
    status: transaction.status,
    // Additional fields...
  };
}

// Helper method to format student name with fallback
private formatStudentName(studentData: any): string {
  if (!studentData) return 'Unknown Student';
  
  // Try different name field variations
  if (studentData.firstName && studentData.lastName) {
    return `${studentData.firstName} ${studentData.lastName}`;
  }
  
  if (studentData.first_name && studentData.last_name) {
    return `${studentData.first_name} ${studentData.last_name}`;
  }
  
  // Fallback to ID-based name if no name fields available
  return `Student ${studentData.id}`;
}
```

### Robustness and Fallbacks

The system includes several fallback mechanisms to ensure transaction data is always properly displayed:

1. **Name Fallbacks**: Uses `Student {id}` format if name fields aren't available
2. **ID Fallbacks**: Uses 'Unknown' if student ID is missing
3. **Type Handling**: Uses type assertions to handle model field variations
4. **Null Safety**: Properly handles undefined or null student data

## Transaction Status Management

Transactions move through various states throughout their lifecycle:

### Status Types

- **COMPLETED**: Transaction has been successfully processed and recorded
- **PENDING**: Transaction is in process (temporary state)
- **VOIDED**: Transaction has been canceled with a specific reason

### Void Process

When a transaction is voided:
1. Status is changed to `VOIDED`
2. `voidReason` is recorded
3. `voidedAt` timestamp is set
4. Original amount remains for audit purposes

## Transaction Reporting

Transactions can be queried and aggregated in various ways for reporting:

### Daily Reports

Daily reports group transactions by:
- Cashier
- Payment method
- Status (including void status)

### Session Reports

Session reports include:
- Opening balance
- Cash transactions
- Adjustments (add/remove)
- Expected closing balance
- Actual closing balance (if session is closed)
- Discrepancy calculation

## Best Practices for Transaction Processing

1. **Always validate input data** before creating transactions
2. **Use proper error handling** to manage failed transactions
3. **Include sufficient metadata** for audit purposes
4. **Use proper transaction status codes** to track lifecycle
5. **Implement proper authorization checks** for void operations
6. **Record detailed reasons** for transaction adjustments and voids 