# Invoice System - API & Integration Guide

**Version:** 2.0.0  
**Last Updated:** October 17, 2025  

---

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [API Endpoints Reference](#api-endpoints-reference)
4. [Email Templates](#email-templates)
5. [Frontend Integration](#frontend-integration)
6. [Webhook Events](#webhook-events)
7. [Code Examples](#code-examples)

---

## API Overview

### Base URLs
- **Production:** `https://gabay.online/api/v2/finance/invoices`
- **Staging:** `https://staging.gabay.online/api/v2/finance/invoices`
- **Local:** `http://localhost:3000/api/v2/finance/invoices`

### Content Type
All requests must include:
```
Content-Type: application/json
```

### Response Format
All responses follow this structure:
```json
{
  "success": true | false,
  "message": "Description",
  "data": { ... } | "error": "Error message"
}
```

---

## Authentication

### Headers Required
```typescript
{
  "Authorization": "Bearer <jwt_token>",
  "X-Tenant-ID": "<tenant_tag>",
  "Content-Type": "application/json"
}
```

### Getting JWT Token
```typescript
// Login first
POST /api/v2/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

// Response includes token
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

---

## API Endpoints Reference

### 1. Create Invoice

**Endpoint:** `POST /api/v2/finance/invoices/create`

**Purpose:** Create a new invoice (manual or recurring)

**Request:**
```json
{
  "userId": "uuid",              // User invoice
  "tenantId": "uuid",            // OR tenant invoice (one required)
  "amount": 206.00,              // Total amount (required)
  "subtotal": 200.00,            // Subtotal before tax
  "tax": 6.00,                   // Tax amount
  "dueDate": "2025-11-16",       // ISO date (required)
  "status": "UNPAID",            // DRAFT | UNPAID (default: UNPAID)
  "billingEmail": "user@example.com",  // Required
  "billingName": "John Doe",     // Required
  "billingAddress": {            // Optional
    "street": "123 Main St",
    "city": "Manila",
    "postal": "1000",
    "country": "Philippines"
  },
  "isRecurring": true,           // Enable recurring (default: false)
  "billingCycle": "MONTHLY",     // WEEKLY|MONTHLY|QUARTERLY|SEMI_ANNUAL|ANNUAL
  "metadata": {                  // Optional
    "items": [
      {
        "description": "Monthly Subscription",
        "quantity": 1,
        "unitPrice": 200.00,
        "amount": 200.00
      }
    ],
    "notes": "Payment due within 30 days"
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Invoice created successfully",
  "invoice": {
    "id": "abc123",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "status": "UNPAID",
    "dueDate": "2025-11-16T00:00:00.000Z",
    "billingEmail": "user@example.com",
    "billingName": "John Doe",
    "isRecurring": true,
    "billingCycle": "MONTHLY",
    "nextInvoiceDate": "2025-12-16T00:00:00.000Z"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Either userId or tenantId is required"
}
```

**Validation Rules:**
- `userId` OR `tenantId` required (not both)
- `amount` > 0
- `dueDate` required
- `billingEmail` valid email format
- If `isRecurring = true`, `billingCycle` required

---

### 2. Get Invoice Details

**Endpoint:** `GET /api/v2/finance/invoices/[id]`

**Purpose:** Retrieve full invoice information

**Request:**
```
GET /api/v2/finance/invoices/abc123
Headers: Authorization, X-Tenant-ID
```

**Response:**
```json
{
  "success": true,
  "invoice": {
    "id": "abc123",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "subtotal": 200.00,
    "tax": 6.00,
    "discount": 0,
    "status": "UNPAID",
    "issueDate": "2025-10-17T00:00:00.000Z",
    "dueDate": "2025-11-16T00:00:00.000Z",
    "paidDate": null,
    "billingEmail": "user@example.com",
    "billingName": "John Doe",
    "billingAddress": {
      "street": "123 Main St",
      "city": "Manila"
    },
    "pdfUrl": "https://minio.gabay.online/invoices/INV-2025-001.pdf",
    "emailSentAt": "2025-10-17T01:00:00.000Z",
    "reminderCount": 0,
    "isRecurring": true,
    "billingCycle": "MONTHLY",
    "nextInvoiceDate": "2025-12-16T00:00:00.000Z",
    "parentInvoiceId": null,
    "metadata": {
      "items": [
        {
          "description": "Monthly Subscription",
          "quantity": 1,
          "unitPrice": 200.00,
          "amount": 200.00
        }
      ],
      "notes": "Payment due within 30 days"
    },
    "user": {
      "f_name": "John",
      "l_name": "Doe",
      "email": [{ "email": "user@example.com" }]
    },
    "createdAt": "2025-10-17T00:00:00.000Z",
    "updatedAt": "2025-10-17T00:00:00.000Z"
  }
}
```

---

### 3. List Invoices with Filters

**Endpoint:** `GET /api/v2/finance/invoices/list`

**Purpose:** Query invoices with advanced filtering

**Query Parameters:**
```typescript
{
  status?: "UNPAID" | "PAID" | "OVERDUE" | "DRAFT",
  dateFrom?: "2025-01-01",      // ISO date
  dateTo?: "2025-12-31",        // ISO date
  tenantId?: "uuid",
  userId?: "uuid",
  search?: "john",              // Search invoice#, name, email
  page?: 1,                     // Default: 1
  limit?: 20,                   // Default: 20 (max: 100)
  sortBy?: "dueDate",           // Field to sort
  sortOrder?: "asc" | "desc"    // Default: desc
}
```

**Example Request:**
```
GET /api/v2/finance/invoices/list?status=UNPAID&search=john&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "invoices": [
      {
        "id": "abc123",
        "invoiceNumber": "INV-2025-001",
        "amount": 206.00,
        "status": "UNPAID",
        "dueDate": "2025-11-16",
        "billingName": "John Doe",
        "billingEmail": "user@example.com",
        "isRecurring": true,
        "billingCycle": "MONTHLY"
      }
    ],
    "total": 45,
    "page": 1,
    "limit": 20,
    "stats": {
      "total": 100,
      "unpaid": 45,
      "paid": 50,
      "overdue": 5,
      "totalAmount": 20600.00,
      "unpaidAmount": 9270.00
    }
  }
}
```

---

### 4. Send Invoice Email

**Endpoint:** `POST /api/v2/finance/invoices/[id]/send-email`

**Purpose:** Send or resend invoice email with PDF

**Request:**
```json
{
  "recipientEmail": "custom@example.com",  // Optional: override billing email
  "customSubject": "Your Invoice",         // Optional: override template subject
  "customMessage": "Hello...",             // Optional: override template message
  "attachPDF": true                        // Optional: default true
}
```

**Example:**
```
POST /api/v2/finance/invoices/abc123/send-email
{
  "recipientEmail": "billing@company.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice email sent successfully"
}
```

**Process:**
1. Fetch invoice details
2. Generate or fetch PDF from MinIO
3. Compile SUBSCRIPTION_INVOICE template
4. Attach PDF
5. Send email via Brevo/SendGrid
6. Track emailSentAt and emailSentTo

---

### 5. Mark Invoice as Paid

**Endpoint:** `POST /api/v2/finance/invoices/[id]/mark-paid`

**Purpose:** Update invoice to PAID status and send receipt

**Request:**
```json
{
  "paymentId": "payment_uuid",   // Optional: link to payment record
  "paidDate": "2025-10-17",      // Optional: defaults to now
  "sendReceipt": true            // Optional: default true
}
```

**Example:**
```
POST /api/v2/finance/invoices/abc123/mark-paid
{
  "sendReceipt": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice marked as paid",
  "invoice": {
    "id": "abc123",
    "status": "PAID",
    "paidDate": "2025-10-17T10:00:00.000Z"
  }
}
```

**Process:**
1. Validate invoice exists and is unpaid
2. Update status to PAID
3. Set paidDate
4. Link payment record (if provided)
5. Send INVOICE_RECEIPT email (if sendReceipt = true)

---

### 6. Delete Invoice

**Endpoint:** `DELETE /api/v2/finance/invoices/[id]`

**Purpose:** Cancel/delete invoice (only DRAFT or UNPAID)

**Request:**
```
DELETE /api/v2/finance/invoices/abc123
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice cancelled successfully"
}
```

**Restrictions:**
- Can only delete invoices with status DRAFT or UNPAID
- Cannot delete PAID invoices
- Cannot delete if linked to payment

---

## Email Templates

### Template Structure
All templates use Handlebars for variable interpolation.

### 1. SUBSCRIPTION_INVOICE

**Code:** `SUBSCRIPTION_INVOICE`

**Subject:**
```
Invoice {{invoiceNumber}} from {{companyName}} - Due {{dueDate}}
```

**Variables:**
```typescript
{
  invoiceNumber: string;        // "INV-2025-001"
  customerName: string;         // "John Doe"
  companyName: string;          // "Gabay Online"
  issueDate: string;            // "October 17, 2025"
  dueDate: string;              // "November 16, 2025"
  amount: string;               // "206.00"
  currency: string;             // "PHP"
  paymentLink: string;          // Optional payment URL
  invoiceItems: Array<{
    description: string;
    quantity: number;
    unitPrice: string;
    total: string;
  }>;
  subtotal: string;             // "200.00"
  tax: string;                  // "6.00"
  discount: string;             // "0.00"
  total: string;                // "206.00"
  notes: string[];              // Array of notes
  currentYear: number;          // 2025
}
```

**Attachment:** Invoice PDF

---

### 2. INVOICE_REMINDER

**Code:** `INVOICE_REMINDER`

**Subject:**
```
Payment Reminder: Invoice {{invoiceNumber}} is overdue
```

**Variables:**
```typescript
{
  invoiceNumber: string;
  customerName: string;
  companyName: string;
  dueDate: string;
  amount: string;
  currency: string;
  daysOverdue: number;          // Calculated: today - dueDate
  paymentLink: string;
  currentYear: number;
}
```

**Attachment:** Invoice PDF

---

### 3. INVOICE_RECEIPT

**Code:** `INVOICE_RECEIPT`

**Subject:**
```
Payment Received - Receipt for Invoice {{invoiceNumber}}
```

**Variables:**
```typescript
{
  invoiceNumber: string;
  customerName: string;
  companyName: string;
  paidDate: string;             // "October 17, 2025"
  amount: string;
  currency: string;
  paymentMethod: string;        // "Credit Card", "Bank Transfer", etc.
  currentYear: number;
}
```

**Attachment:** Paid invoice PDF

---

## Frontend Integration

### React Hook Example

```typescript
import { useQuery, useMutation } from '@tanstack/react-query';
import axios from 'axios';

// Fetch invoice list
const useInvoices = (filters: InvoiceFilters) => {
  return useQuery({
    queryKey: ['invoices', filters],
    queryFn: async () => {
      const { data } = await axios.get('/api/v2/finance/invoices/list', {
        params: filters,
        headers: {
          'x-tenant-tag': getTenantTag()
        }
      });
      return data;
    }
  });
};

// Fetch single invoice
const useInvoice = (id: string) => {
  return useQuery({
    queryKey: ['invoice', id],
    queryFn: async () => {
      const { data } = await axios.get(`/api/v2/finance/invoices/${id}`, {
        headers: {
          'x-tenant-tag': getTenantTag()
        }
      });
      return data.invoice;
    }
  });
};

// Create invoice
const useCreateInvoice = () => {
  return useMutation({
    mutationFn: async (invoiceData: CreateInvoiceDto) => {
      const { data } = await axios.post(
        '/api/v2/finance/invoices/create',
        invoiceData,
        {
          headers: {
            'x-tenant-tag': getTenantTag()
          }
        }
      );
      return data;
    }
  });
};

// Send email
const useSendInvoiceEmail = () => {
  return useMutation({
    mutationFn: async ({ id, recipientEmail }: { id: string; recipientEmail?: string }) => {
      const { data } = await axios.post(
        `/api/v2/finance/invoices/${id}/send-email`,
        { recipientEmail },
        {
          headers: {
            'x-tenant-tag': getTenantTag()
          }
        }
      );
      return data;
    }
  });
};

// Mark as paid
const useMarkInvoicePaid = () => {
  return useMutation({
    mutationFn: async ({ id, paymentId }: { id: string; paymentId?: string }) => {
      const { data } = await axios.post(
        `/api/v2/finance/invoices/${id}/mark-paid`,
        { paymentId, sendReceipt: true },
        {
          headers: {
            'x-tenant-tag': getTenantTag()
          }
        }
      );
      return data;
    }
  });
};

// Usage in component
function InvoiceList() {
  const { data, isLoading } = useInvoices({ status: 'UNPAID' });
  const sendEmail = useSendInvoiceEmail();

  const handleSendEmail = (invoiceId: string) => {
    sendEmail.mutate(
      { id: invoiceId },
      {
        onSuccess: () => {
          toast.success('Email sent successfully');
        }
      }
    );
  };

  return (
    <div>
      {data?.data.invoices.map(invoice => (
        <div key={invoice.id}>
          <h3>{invoice.invoiceNumber}</h3>
          <button onClick={() => handleSendEmail(invoice.id)}>
            Send Email
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## Webhook Events

### Invoice Created
```json
{
  "event": "invoice.created",
  "timestamp": "2025-10-17T10:00:00.000Z",
  "data": {
    "invoiceId": "abc123",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "status": "UNPAID"
  }
}
```

### Invoice Paid
```json
{
  "event": "invoice.paid",
  "timestamp": "2025-10-17T10:00:00.000Z",
  "data": {
    "invoiceId": "abc123",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "paidDate": "2025-10-17T10:00:00.000Z"
  }
}
```

### Invoice Overdue
```json
{
  "event": "invoice.overdue",
  "timestamp": "2025-10-17T10:00:00.000Z",
  "data": {
    "invoiceId": "abc123",
    "invoiceNumber": "INV-2025-001",
    "daysOverdue": 5
  }
}
```

---

## Code Examples

### Complete Subscription Flow

```typescript
// 1. User subscribes
const subscription = await prisma.userSubscription.create({
  data: {
    userId: "user123",
    planId: "plan456",
    status: "ACTIVE",
    billingCycle: "MONTHLY",
    startDate: new Date(),
    nextBillingAt: addMonths(new Date(), 1)
  }
});

// 2. Auto-generate invoice
const invoiceService = new InvoiceService(prisma);
const invoice = await invoiceService.createInvoiceFromSubscription(
  subscription.id,
  'INDIVIDUAL'
);

// 3. Generate PDF
const pdfService = new PDFGeneratorService();
const pdfUrl = await pdfService.generateAndUploadPDF(invoice);

// 4. Send email
const emailService = new InvoiceEmailService(prisma);
await emailService.sendInvoiceEmail(invoice.id, user.email);

console.log(`Invoice ${invoice.invoiceNumber} created and sent!`);
```

### Create Recurring Invoice

```typescript
const response = await fetch('/api/v2/finance/invoices/create', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-tenant-tag': 'school-abc'
  },
  body: JSON.stringify({
    userId: "user123",
    amount: 206.00,
    dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    billingEmail: "user@example.com",
    billingName: "John Doe",
    isRecurring: true,
    billingCycle: "MONTHLY",
    metadata: {
      items: [
        {
          description: "Monthly LMS Subscription",
          quantity: 1,
          unitPrice: 206.00,
          amount: 206.00
        }
      ]
    }
  })
});

const data = await response.json();
console.log('Next invoice date:', data.invoice.nextInvoiceDate);
```

---

## Rate Limits

- **Invoice Creation:** 100 requests/minute
- **Email Sending:** 50 requests/minute
- **List Queries:** 200 requests/minute

---

## Testing

### Test Credentials
```
Email: test@gabay.online
Password: TestPassword123
Tenant: test-school
```

### Test Invoice Data
```json
{
  "userId": "test-user-id",
  "amount": 206.00,
  "dueDate": "2025-12-31",
  "billingEmail": "test@example.com",
  "billingName": "Test User",
  "metadata": {
    "items": [
      {
        "description": "Test Item",
        "quantity": 1,
        "unitPrice": 206.00,
        "amount": 206.00
      }
    ]
  }
}
```

---

**Document Version:** 2.0.0  
**Last Updated:** October 17, 2025
