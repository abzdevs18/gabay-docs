# Recurring Subscriptions - Complete Guide

**Version:** 2.0.0  
**Last Updated:** October 17, 2025  
**Status:** Production-Ready  

---

## Table of Contents

1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [Billing Cycles](#billing-cycles)
4. [Database Structure](#database-structure)
5. [Creating Recurring Invoices](#creating-recurring-invoices)
6. [Automated Generation](#automated-generation)
7. [Managing Recurring Invoices](#managing-recurring-invoices)
8. [Cancellation & Modifications](#cancellation--modifications)
9. [Troubleshooting](#troubleshooting)

---

## Overview

### What is Recurring Billing?
Recurring billing automatically generates invoices at regular intervals (weekly, monthly, quarterly, etc.) without manual intervention.

### Use Cases
- **Monthly subscriptions** - LMS access fees
- **Quarterly tuition** - School term payments
- **Annual memberships** - Yearly renewals
- **Weekly services** - Recurring coaching sessions
- **Semi-annual fees** - Bi-annual payments

### Key Benefits
- ✅ **Zero manual work** - Fully automated
- ✅ **Predictable revenue** - Regular billing cycles
- ✅ **Reduced errors** - No manual data entry
- ✅ **Customer convenience** - Auto-renewal
- ✅ **Scalable** - Handle unlimited subscriptions

---

## How It Works

### Workflow Overview

```
1. Create Initial Invoice (with recurring settings)
   ├─ Set isRecurring = true
   ├─ Choose billingCycle (MONTHLY, etc.)
   └─ System calculates nextInvoiceDate

2. Payment & Activation
   └─ Customer pays first invoice

3. Automated Generation (Scheduled Job)
   ├─ Daily at 1:00 AM
   ├─ Check nextInvoiceDate <= TODAY
   ├─ Duplicate parent invoice
   ├─ Update dates
   ├─ Generate PDF
   ├─ Send email
   └─ Update nextInvoiceDate for next cycle

4. Repeat Step 3 indefinitely
```

### Timeline Example (Monthly)

```
Oct 17, 2025  →  Initial invoice created
                  - amount: 206.00
                  - dueDate: Nov 16, 2025
                  - nextInvoiceDate: Nov 17, 2025
                  
Nov 17, 2025  →  Scheduled job runs
                  - Creates new invoice
                  - dueDate: Dec 16, 2025
                  - nextInvoiceDate: Dec 17, 2025
                  
Dec 17, 2025  →  Scheduled job runs again
                  - Creates new invoice
                  - dueDate: Jan 16, 2026
                  - nextInvoiceDate: Jan 17, 2026
                  
... continues automatically ...
```

---

## Billing Cycles

### Supported Cycles

| Cycle | Description | Next Invoice Date Calculation |
|-------|-------------|-------------------------------|
| **WEEKLY** | Every 7 days | currentDueDate + 7 days |
| **MONTHLY** | Every month | currentDueDate + 1 month |
| **QUARTERLY** | Every 3 months | currentDueDate + 3 months |
| **SEMI_ANNUAL** | Every 6 months | currentDueDate + 6 months |
| **ANNUAL** | Every year | currentDueDate + 1 year |

### Calculation Examples

**WEEKLY:**
```
dueDate: 2025-10-17
nextInvoiceDate: 2025-10-24 (+ 7 days)
```

**MONTHLY:**
```
dueDate: 2025-10-17
nextInvoiceDate: 2025-11-17 (+ 1 month)
```

**QUARTERLY:**
```
dueDate: 2025-10-17
nextInvoiceDate: 2026-01-17 (+ 3 months)
```

**SEMI_ANNUAL:**
```
dueDate: 2025-10-17
nextInvoiceDate: 2026-04-17 (+ 6 months)
```

**ANNUAL:**
```
dueDate: 2025-10-17
nextInvoiceDate: 2026-10-17 (+ 1 year)
```

### Date Handling
- **Preserves day of month** - 17th stays 17th
- **Handles month-end** - Jan 31 → Feb 28 (non-leap)
- **Time zone** - UTC for consistency
- **Daylight savings** - Not affected (date-only calculation)

---

## Database Structure

### Invoice Fields

```prisma
model Invoice {
  // ... other fields ...
  
  // Recurring fields
  isRecurring       Boolean       @default(false)
  billingCycle      BillingCycle?  // WEEKLY|MONTHLY|QUARTERLY|SEMI_ANNUAL|ANNUAL
  nextInvoiceDate   DateTime?      // When to generate next invoice
  parentInvoiceId   String?        // Link to original invoice
  
  @@index([isRecurring, nextInvoiceDate])
  @@index([parentInvoiceId])
}
```

### Relationship Structure

```
Parent Invoice (Initial)
  ├─ id: "parent-123"
  ├─ isRecurring: true
  ├─ billingCycle: MONTHLY
  ├─ nextInvoiceDate: 2025-11-17
  └─ parentInvoiceId: null

Child Invoice 1 (Auto-generated)
  ├─ id: "child-456"
  ├─ isRecurring: true
  ├─ billingCycle: MONTHLY
  ├─ nextInvoiceDate: 2025-12-17
  └─ parentInvoiceId: "parent-123"

Child Invoice 2 (Auto-generated)
  ├─ id: "child-789"
  ├─ isRecurring: true
  ├─ billingCycle: MONTHLY
  ├─ nextInvoiceDate: 2026-01-17
  └─ parentInvoiceId: "parent-123"
```

### Querying Recurring Invoices

```typescript
// Find all child invoices for a parent
const childInvoices = await prisma.invoice.findMany({
  where: {
    parentInvoiceId: "parent-123"
  },
  orderBy: {
    issueDate: 'asc'
  }
});

// Find all recurring invoices due for generation
const dueInvoices = await prisma.invoice.findMany({
  where: {
    isRecurring: true,
    nextInvoiceDate: {
      lte: new Date() // Less than or equal to today
    },
    status: 'PAID' // Only generate next if current is paid
  }
});
```

---

## Creating Recurring Invoices

### Via API

**Endpoint:** `POST /api/v2/finance/invoices/create`

```json
{
  "userId": "user-123",
  "amount": 206.00,
  "dueDate": "2025-11-16",
  "billingEmail": "user@example.com",
  "billingName": "John Doe",
  "isRecurring": true,
  "billingCycle": "MONTHLY",
  "metadata": {
    "items": [
      {
        "description": "Monthly LMS Subscription",
        "quantity": 1,
        "unitPrice": 206.00,
        "amount": 206.00
      }
    ],
    "notes": "Auto-renews monthly"
  }
}
```

**Response:**
```json
{
  "success": true,
  "invoice": {
    "id": "abc-123",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "isRecurring": true,
    "billingCycle": "MONTHLY",
    "nextInvoiceDate": "2025-11-17T00:00:00.000Z"
  }
}
```

### Via Frontend

**Component:** `/finance/invoices/create`

```typescript
const [invoiceData, setInvoiceData] = useState({
  // ... other fields ...
  isRecurring: false,
  billingCycle: 'MONTHLY'
});

// UI shows checkbox for recurring
<Checkbox
  id="recurring"
  checked={invoiceData.isRecurring}
  onCheckedChange={(checked) =>
    setInvoiceData({ ...invoiceData, isRecurring: checked })
  }
/>
<Label htmlFor="recurring">Set as recurring subscription</Label>

// When checked, show billing cycle selector
{invoiceData.isRecurring && (
  <Select
    value={invoiceData.billingCycle}
    onValueChange={(value) =>
      setInvoiceData({ ...invoiceData, billingCycle: value })
    }
  >
    <SelectItem value="WEEKLY">Weekly</SelectItem>
    <SelectItem value="MONTHLY">Monthly</SelectItem>
    <SelectItem value="QUARTERLY">Quarterly</SelectItem>
    <SelectItem value="SEMI_ANNUAL">Semi-Annual</SelectItem>
    <SelectItem value="ANNUAL">Annual</SelectItem>
  </Select>
)}
```

### Via Service

```typescript
const invoiceService = new InvoiceService(prisma);

const invoice = await invoiceService.createInvoice({
  userId: "user-123",
  amount: 206.00,
  dueDate: new Date('2025-11-16'),
  billingEmail: "user@example.com",
  billingName: "John Doe",
  isRecurring: true,
  billingCycle: "MONTHLY",
  metadata: {
    items: [
      {
        description: "Monthly Subscription",
        quantity: 1,
        unitPrice: 206.00,
        amount: 206.00
      }
    ]
  }
});

console.log('Next invoice:', invoice.nextInvoiceDate);
// Output: 2025-11-17T00:00:00.000Z
```

---

## Automated Generation

### Scheduled Job

**File:** `backend/src/jobs/invoice-generation.job.ts`  
**Schedule:** Daily at 1:00 AM UTC

**Logic Flow:**

```typescript
async function generateRecurringInvoices() {
  console.log('🔄 Checking for recurring invoices...');
  
  // 1. Find invoices ready for generation
  const dueInvoices = await prisma.invoice.findMany({
    where: {
      isRecurring: true,
      nextInvoiceDate: {
        lte: new Date() // Due today or earlier
      },
      status: {
        in: ['PAID', 'PAYMENT_RECEIVED'] // Only if parent is paid
      }
    },
    include: {
      user: {
        include: {
          email: true
        }
      }
    }
  });
  
  console.log(`📋 Found ${dueInvoices.length} invoices to generate`);
  
  // 2. Process each invoice
  for (const parentInvoice of dueInvoices) {
    try {
      // Check for duplicate
      const existingInvoice = await prisma.invoice.findFirst({
        where: {
          parentInvoiceId: parentInvoice.id,
          issueDate: {
            gte: new Date(new Date().setHours(0, 0, 0, 0)) // Today
          }
        }
      });
      
      if (existingInvoice) {
        console.log(`⏭️  Skipping ${parentInvoice.invoiceNumber} - already generated today`);
        continue;
      }
      
      // Calculate new dates
      const newDueDate = calculateNextDueDate(
        parentInvoice.dueDate,
        parentInvoice.billingCycle
      );
      
      const newNextInvoiceDate = calculateNextDueDate(
        newDueDate,
        parentInvoice.billingCycle
      );
      
      // Create new invoice
      const newInvoice = await prisma.invoice.create({
        data: {
          invoiceNumber: generateInvoiceNumber(),
          userId: parentInvoice.userId,
          tenantId: parentInvoice.tenantId,
          amount: parentInvoice.amount,
          subtotal: parentInvoice.subtotal,
          tax: parentInvoice.tax,
          discount: parentInvoice.discount,
          issueDate: new Date(),
          dueDate: newDueDate,
          status: 'UNPAID',
          billingEmail: parentInvoice.billingEmail,
          billingName: parentInvoice.billingName,
          billingAddress: parentInvoice.billingAddress,
          isRecurring: true,
          billingCycle: parentInvoice.billingCycle,
          nextInvoiceDate: newNextInvoiceDate,
          parentInvoiceId: parentInvoice.id,
          metadata: parentInvoice.metadata
        }
      });
      
      // Generate PDF
      const pdfService = new PDFGeneratorService();
      await pdfService.generateAndUploadPDF(newInvoice);
      
      // Send email
      const emailService = new InvoiceEmailService(prisma);
      await emailService.sendInvoiceEmail(
        newInvoice.id,
        newInvoice.billingEmail
      );
      
      console.log(`✅ Generated ${newInvoice.invoiceNumber} for ${parentInvoice.billingName}`);
      
    } catch (error) {
      console.error(`❌ Error generating invoice for ${parentInvoice.invoiceNumber}:`, error);
    }
  }
  
  console.log('✨ Recurring invoice generation complete');
}

function calculateNextDueDate(currentDate: Date, cycle: string): Date {
  const date = new Date(currentDate);
  
  switch (cycle) {
    case 'WEEKLY':
      date.setDate(date.getDate() + 7);
      break;
    case 'MONTHLY':
      date.setMonth(date.getMonth() + 1);
      break;
    case 'QUARTERLY':
      date.setMonth(date.getMonth() + 3);
      break;
    case 'SEMI_ANNUAL':
      date.setMonth(date.getMonth() + 6);
      break;
    case 'ANNUAL':
      date.setFullYear(date.getFullYear() + 1);
      break;
  }
  
  return date;
}
```

### Duplicate Prevention

The job checks for existing invoices before creating:

```typescript
const existingInvoice = await prisma.invoice.findFirst({
  where: {
    parentInvoiceId: parentInvoice.id,
    issueDate: {
      gte: new Date(new Date().setHours(0, 0, 0, 0)) // Today
    }
  }
});

if (existingInvoice) {
  console.log('⏭️  Skipping - already generated');
  continue;
}
```

### Manual Trigger

For testing or immediate generation:

```bash
# Run generation job manually
npm run jobs:invoice-generation

# Or
ts-node backend/src/jobs/invoice-generation.job.ts
```

---

## Managing Recurring Invoices

### View Recurring Status

**Dashboard:** `/finance/invoices/[id]`

Shows:
- ✅ Recurring badge
- ✅ Billing cycle (MONTHLY, etc.)
- ✅ Next invoice date
- ✅ Parent invoice link (if child)
- ✅ Child invoices list (if parent)

### Update Recurring Settings

```typescript
// Update billing cycle
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    billingCycle: "QUARTERLY" // Changed from MONTHLY
  }
});

// Update next invoice date
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    nextInvoiceDate: new Date('2026-01-01') // Delay next invoice
  }
});
```

### Pause Recurring

```typescript
// Pause by setting far future date
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    nextInvoiceDate: new Date('2099-12-31') // Effectively paused
  }
});
```

### Resume Recurring

```typescript
// Resume by setting appropriate next date
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    nextInvoiceDate: new Date('2025-11-17') // Resume
  }
});
```

---

## Cancellation & Modifications

### Cancel Recurring Subscription

**Option 1: Soft Cancel (Recommended)**
```typescript
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    isRecurring: false,
    nextInvoiceDate: null
  }
});
```

**Option 2: Hard Cancel**
```typescript
await prisma.invoice.updateMany({
  where: {
    OR: [
      { id: "invoice-123" },
      { parentInvoiceId: "invoice-123" }
    ],
    status: 'UNPAID'
  },
  data: {
    status: 'CANCELLED',
    isRecurring: false,
    nextInvoiceDate: null
  }
});
```

### Modify Amount

```typescript
// Update parent invoice amount
// Next generated invoices will use new amount
await prisma.invoice.update({
  where: { id: "parent-invoice-id" },
  data: {
    amount: 250.00, // Increased from 206.00
    subtotal: 242.72,
    tax: 7.28,
    metadata: {
      items: [
        {
          description: "Monthly Subscription (Premium)",
          quantity: 1,
          unitPrice: 250.00,
          amount: 250.00
        }
      ]
    }
  }
});
```

### Change Billing Cycle

```typescript
// Change from MONTHLY to QUARTERLY
await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    billingCycle: "QUARTERLY",
    nextInvoiceDate: calculateNextDate(
      currentDueDate,
      "QUARTERLY"
    )
  }
});
```

---

## Troubleshooting

### Issue: Invoices not generating automatically

**Check:**
1. Job is running: `pm2 status invoice-jobs`
2. View logs: `pm2 logs invoice-jobs`
3. Check nextInvoiceDate: `SELECT id, invoiceNumber, nextInvoiceDate FROM Invoice WHERE isRecurring = true;`

**Fix:**
```bash
# Restart jobs
pm2 restart invoice-jobs

# Manual trigger
npm run jobs:invoice-generation
```

---

### Issue: Duplicate invoices created

**Check:**
```sql
SELECT parentInvoiceId, COUNT(*) as count, DATE(issueDate) as date
FROM Invoice
GROUP BY parentInvoiceId, DATE(issueDate)
HAVING COUNT(*) > 1;
```

**Fix:**
Delete duplicates (keep earliest):
```sql
DELETE FROM Invoice
WHERE id NOT IN (
  SELECT MIN(id)
  FROM Invoice
  GROUP BY parentInvoiceId, DATE(issueDate)
);
```

---

### Issue: Wrong next invoice date

**Recalculate:**
```typescript
const invoice = await prisma.invoice.findUnique({
  where: { id: "invoice-123" }
});

const correctNextDate = calculateNextDueDate(
  invoice.dueDate,
  invoice.billingCycle
);

await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    nextInvoiceDate: correctNextDate
  }
});
```

---

### Issue: Customer wants to skip one billing period

**Solution:**
```typescript
// Skip next invoice by moving date forward by one cycle
const currentNext = invoice.nextInvoiceDate;
const skippedNext = calculateNextDueDate(currentNext, invoice.billingCycle);

await prisma.invoice.update({
  where: { id: "invoice-123" },
  data: {
    nextInvoiceDate: skippedNext
  }
});
```

---

## Best Practices

### 1. Always Test First
- Create test recurring invoice
- Wait for scheduled job
- Verify generation

### 2. Monitor Regularly
- Check job logs daily
- Review nextInvoiceDate values
- Monitor email delivery

### 3. Customer Communication
- Inform customers about auto-renewal
- Send reminder before next charge
- Provide easy cancellation

### 4. Handle Failed Payments
- Set up payment retry logic
- Send payment failure notifications
- Pause recurring after 3 failures

### 5. Data Integrity
- Regular database backups
- Audit invoice chains (parent→child)
- Validate nextInvoiceDate calculations

---

**Document Version:** 2.0.0  
**Last Updated:** October 17, 2025
