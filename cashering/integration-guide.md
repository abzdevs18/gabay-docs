# Cashiering System Integration Guide

This document provides guidance on integrating the Cashiering System with other components of the application.

## Frontend Integration

### 1. Cashier Dashboard

To integrate the cashier dashboard:

```typescript
// Example usage in frontend components
import { useEffect, useState } from 'react';
import axios from 'axios';

interface CashierSession {
  id: string;
  startBalance: number;
  isActive: boolean;
  // Additional fields...
}

const CashierDashboard = () => {
  const [activeSession, setActiveSession] = useState<CashierSession | null>(null);
  
  useEffect(() => {
    const fetchActiveSession = async () => {
      try {
        const response = await axios.get('/api/v2/finance/cashier');
        setActiveSession(response.data);
      } catch (error) {
        console.error('Failed to fetch active session:', error);
      }
    };
    
    fetchActiveSession();
  }, []);
  
  // Dashboard implementation...
};
```

### 2. Processing Transactions

To integrate transaction processing:

```typescript
// Example usage in payment processing components
const processPayment = async (paymentData) => {
  try {
    const response = await axios.post('/api/v2/finance/cashier/transactions', {
      sessionId: activeSession.id,
      studentId: selectedStudent.id,
      amount: paymentAmount,
      paymentMethod: 'CASH',
      feeId: selectedFee.id,
      paidBy: payerName,
    });
    
    // Handle successful payment
    return response.data;
  } catch (error) {
    // Handle payment error
    console.error('Payment processing failed:', error);
    throw error;
  }
};
```

### 3. Fetching Reports

To integrate reporting functionality:

```typescript
// Example usage in reporting components
const fetchDailyReport = async (date: string) => {
  try {
    const response = await axios.get(`/api/v2/finance/cashier/reports/daily?date=${date}`);
    return response.data;
  } catch (error) {
    console.error('Failed to fetch daily report:', error);
    throw error;
  }
};
```

## Backend Integration

### 1. Using CashierService

To use the CashierService in other backend components:

```typescript
// Example usage in other services
import { CashierService } from '@services/cashier.service';

// In your service class
constructor(private cashierService: CashierService) {}

async processStudentPayment(studentId: string, amount: number) {
  // Your business logic
  
  // Get active session for the cashier
  const activeSession = await this.cashierService.getActiveSessionForCashier(cashierId);
  
  if (!activeSession) {
    throw new Error('No active session found for cashier');
  }
  
  // Process the payment
  const transaction = await this.cashierService.processCashPayment({
    sessionId: activeSession.id,
    studentId,
    amount,
    paymentMethod: 'CASH',
    feeId: feeId,
  });
  
  // Additional processing
  return transaction;
}
```

### 2. Integrating with Payment System

To integrate with the existing payment system:

```typescript
// In payment service
import { CashierService } from '@services/cashier.service';
import { PaymentService } from '@services/payment.service';

class IntegratedPaymentService {
  constructor(
    private cashierService: CashierService,
    private paymentService: PaymentService
  ) {}
  
  async processPayment(paymentData) {
    if (paymentData.paymentMethod === 'CASH') {
      // Use cashier service for cash payments
      return this.cashierService.processCashPayment(paymentData);
    } else {
      // Use regular payment service for other payment methods
      return this.paymentService.processPayment(paymentData);
    }
  }
  
  // Additional integration methods...
}
```

### 3. Database Migrations

When integrating with the existing database:

1. Create migrations for the new cashier-related tables
2. Add relations to existing models
3. Update indexes for performance optimization

Example migration:

```typescript
import { Prisma } from '@prisma/client';

export const migration = {
  up: async (prisma) => {
    // Add isCashier field to User model
    await prisma.$executeRaw`
      ALTER TABLE "User" ADD COLUMN "isCashier" BOOLEAN NOT NULL DEFAULT false;
    `;
    
    // Create necessary indexes
    await prisma.$executeRaw`
      CREATE INDEX "Transaction_sessionId_idx" ON "Transaction"("sessionId");
    `;
    
    // Additional migration steps...
  },
  
  down: async (prisma) => {
    // Reversion steps...
  }
};
```

## Authentication Integration

The Cashiering System relies on the existing authentication system:

```typescript
// Inside API endpoint
import { withAuth } from '@middleware/auth';

export default withAuth(async (req, res) => {
  // req.user will contain authenticated user information
  const { user } = req;
  
  // Check cashier permissions
  if (!user.isCashier) {
    return res.status(403).json({ error: 'User is not a cashier' });
  }
  
  // Process cashier-specific request
  // ...
});
```

## Testing Integration

When writing tests that involve the Cashiering System:

```typescript
// Example test for integrated functionality
import { CashierService } from '@services/cashier.service';
import { PaymentService } from '@services/payment.service';

describe('Integrated Payment Flow', () => {
  let cashierService: CashierService;
  let paymentService: PaymentService;
  
  beforeEach(() => {
    // Setup test environment
    cashierService = new CashierService(prisma);
    paymentService = new PaymentService(prisma);
  });
  
  test('should process cash payment through cashier service', async () => {
    // Test implementation
    // ...
  });
  
  // Additional tests...
});
```

## Deployment Considerations

When deploying the Cashiering System:

1. Ensure database migrations are applied in the correct order
2. Update API routes to include new cashiering endpoints
3. Update frontend components to use the cashiering API
4. Update user permissions to include cashier roles
5. Test the integrated system thoroughly before production deployment 