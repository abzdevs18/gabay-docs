# Student Checkout - Robust Implementation

## Overview
This document describes the robust student checkout implementation that mirrors the POS credit-payment endpoint with proper transaction handling, audit trails, and comprehensive error handling.

## Key Features

### 1. Transaction Integrity
- **Database Transactions**: All operations wrapped in Prisma transactions with serializable isolation level
- **Optimistic Locking**: Inventory updates use conditional checks to prevent race conditions
- **Rollback on Failure**: Automatic rollback if any step fails

### 2. Security & Validation

#### Input Validation
- Zod schema validation for all inputs
- Amount verification (calculated vs provided)
- Product existence and availability checks
- Inventory level validation before processing

#### Authentication & Authorization
- JWT authentication required
- User must be the student or have `create_student_orders` permission
- Optional PIN verification for credit payments

#### Credit Limits
- Daily credit limit enforcement (per-user or global)
- Balance verification from transaction history
- Real-time balance tracking

### 3. Audit Trail

#### Inventory Movements
```typescript
// Logged for each item sold
{
  productId: string,
  type: 'SALE',
  quantity: -quantity,
  referenceId: transactionId,
  reason: 'Student checkout - ORD-xxx',
  createdBy: userId,
  metadata: {
    orderType: 'DINE_IN',
    studentId: string,
    studentName: string
  }
}
```

#### Audit Logs
- User actions logged with IP and user agent
- Transaction details preserved
- Timestamp and user attribution

### 4. Accounting Integration
- Automatic journal entry creation
- OR number generation
- Integration with AccountingService
- Proper debit/credit entries

## API Endpoint

### POST `/api/v2/students/checkout`

#### Request Body
```typescript
{
  studentId: string,
  items: Array<{
    productId: string,
    quantity: number,
    priceAtPurchase: number
  }>,
  paymentMethod: 'CREDIT' | 'CASH',
  amount: number,
  studentPin?: string,  // Optional, required if PIN is set
  metadata?: {
    orderType?: 'DINE_IN' | 'TAKEOUT' | 'DELIVERY',
    notes?: string,
    estimatedTime?: string
  }
}
```

#### Response (Success)
```typescript
{
  success: true,
  message: 'Checkout completed successfully',
  data: {
    order: {
      id: string,
      orderNumber: string,
      status: string,
      paymentMethod: string,
      total: number,
      createdAt: string,
      estimatedTime: string,
      orderType: string
    },
    items: Array<{
      id: string,
      name: string,
      price: number,
      quantity: number,
      subtotal: number,
      category: string
    }>,
    payment: {
      id: string,
      paymentId: string,
      amount: number,
      status: string,
      paidAt: string
    },
    receipt: {
      id: string,
      receiptNumber: string,
      orNumber: string
    },
    student: {
      id: string,
      userId: string,
      name: string,
      email: string,
      previousBalance?: number,  // For credit payments
      newBalance?: number        // For credit payments
    },
    metadata: {
      journalNumber: string,
      orNumber: string,
      lowStockAlert?: string  // If any products hit low stock threshold
    }
  }
}
```

#### Error Responses

##### 400 Bad Request
```typescript
{
  success: false,
  message: string,
  code: 'INSUFFICIENT_BALANCE' | 'DAILY_LIMIT_EXCEEDED' | 'INSUFFICIENT_INVENTORY'
}
```

##### 401 Unauthorized
```typescript
{
  success: false,
  message: 'Invalid student PIN',
  code: 'INVALID_PIN'
}
```

##### 404 Not Found
```typescript
{
  success: false,
  message: 'Student not found',
  code: 'STUDENT_NOT_FOUND'
}
```

## Frontend Integration

### StudentCanteen Component Updates

#### Enhanced placeOrder Function
```typescript
const placeOrder = async (paymentMethod: 'CREDIT' | 'CASH', studentPin?: string) => {
  // Validates cart
  // Calls /api/v2/students/checkout
  // Handles specific error codes
  // Updates UI state and balance
  // Shows detailed success/error messages
}
```

#### Error Handling
- Specific error messages for each error code
- Automatic inventory refresh on stock errors
- PIN re-entry prompt on authentication failure
- Balance refresh after successful credit payment

### StudentCanteenCheckout Component

#### PIN Support
- Optional PIN input for credit payments
- Progressive disclosure (shows PIN field only when needed)
- Clear error messaging for PIN failures

## Database Schema

### POSTransaction
- Stores order details with proper metadata
- Links to Student via studentId
- Tracks payment method and status

### POSTransactionItem
- Individual line items
- Price at purchase preserved
- Quantity tracking

### POSInventoryMovement (if available)
- Audit trail for all inventory changes
- Type: SALE, RESTOCK, ADJUSTMENT, VOID_SALE
- Reference to transaction
- User attribution

### Payment & PaymentReceipt
- Financial record keeping
- OR number generation
- Gateway tracking

### Transaction (Credit Ledger)
- Credit balance tracking
- Running balance calculation
- Transaction type metadata

## Cache Management

### Invalidated on Checkout
- `student-finance_{studentId}`
- `student-orders_{studentId}`
- `payment-list`
- `receipt-list`
- `pos-transactions`
- `product-list`
- `low-stock` (if thresholds hit)

## Security Best Practices

1. **Never trust client calculations** - Always recalculate totals server-side
2. **Use database transactions** - Ensure atomicity of operations
3. **Implement rate limiting** - Prevent abuse
4. **Log everything** - Maintain audit trail
5. **Validate permissions** - Check user authorization
6. **Sanitize inputs** - Use Zod validation
7. **Handle errors gracefully** - Don't expose internal details

## Testing Checklist

- [ ] Cart with multiple items processes correctly
- [ ] Inventory decrements properly
- [ ] Credit balance updates accurately
- [ ] Daily limit enforcement works
- [ ] PIN validation functions when set
- [ ] Low stock alerts trigger
- [ ] Concurrent orders don't oversell inventory
- [ ] Transaction rollback on failure
- [ ] Audit logs created
- [ ] Accounting integration successful
- [ ] Cache invalidation works
- [ ] Error messages are user-friendly

## Migration from Old Endpoint

### Old: `/api/v2/students/orders`
- Basic order creation
- Limited validation
- No audit trail
- Simple balance deduction

### New: `/api/v2/students/checkout`
- Comprehensive validation
- Full audit trail
- Accounting integration
- Inventory movement tracking
- PIN support
- Daily limits
- Better error handling
- Cache management

## Future Enhancements

1. **Partial refunds** - Allow refunding specific items
2. **Order modifications** - Edit pending orders
3. **Scheduled orders** - Pre-order for specific times
4. **Loyalty points** - Integration with rewards system
5. **Promotions** - Discount codes and special offers
6. **Multi-payment** - Split payment between credit and cash
7. **Order notifications** - Real-time updates via WebSocket
8. **QR code ordering** - Scan to order and pay

## Monitoring & Alerts

### Key Metrics
- Checkout success rate
- Average transaction time
- Failed payment reasons
- Inventory discrepancies
- Daily credit usage

### Alert Triggers
- High failure rate (>5%)
- Slow transaction processing (>3s)
- Inventory mismatches
- Unusual spending patterns

---

Last Updated: 2025-09-20
Implementation Status: ✅ Complete
