# Invoice Automation System - Technical Documentation

**Version:** 2.0.0  
**Last Updated:** October 17, 2025  
**Status:** Production-Ready  

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [Core Services](#core-services)
5. [API Endpoints](#api-endpoints)
6. [Scheduled Jobs](#scheduled-jobs)
7. [Configuration](#configuration)
8. [Deployment](#deployment)

---

## System Overview

### Purpose
Complete billing automation system supporting:
- **Automatic invoice generation** from subscriptions
- **PDF creation** with Puppeteer
- **Email automation** with templates
- **Recurring billing** (WEEKLY, MONTHLY, QUARTERLY, SEMI_ANNUAL, ANNUAL)
- **Payment tracking** and receipts
- **Scheduled reminders** for overdue payments

### Technology Stack
- **Backend:** Node.js, TypeScript, Next.js API, Prisma
- **PDF:** Puppeteer
- **Email:** Brevo/SendGrid
- **Storage:** MinIO (S3-compatible)
- **Scheduling:** node-cron
- **Frontend:** React, Next.js, shadcn/ui

---

## Architecture

### System Flow

```
Subscription Created
    ↓
InvoiceService.createInvoiceFromSubscription()
    ├─ Generate invoice number
    ├─ Calculate totals
    ├─ Set recurring billing (if applicable)
    └─ Calculate nextInvoiceDate
    ↓
PDFGeneratorService.generateAndUploadPDF()
    ├─ Render HTML template
    ├─ Generate PDF (Puppeteer)
    └─ Upload to MinIO
    ↓
InvoiceEmailService.sendInvoiceEmail()
    ├─ Fetch SUBSCRIPTION_INVOICE template
    ├─ Compile with Handlebars
    ├─ Attach PDF
    └─ Send via sendCustomEmail
```

---

## Database Schema

### Invoice Model
**File:** `backend/prisma/schema/invoice.prisma`

```prisma
model Invoice {
  id                String        @id @unique @default(uuid())
  invoiceNumber     String        @unique
  
  // Customer
  studentId         String?
  tenantId          String?
  subscriptionId    String?
  subscriptionType  String?       // INDIVIDUAL | TENANT
  
  // Recurring (NEW in v2.0)
  isRecurring       Boolean       @default(false)
  billingCycle      BillingCycle? // WEEKLY|MONTHLY|QUARTERLY|SEMI_ANNUAL|ANNUAL
  nextInvoiceDate   DateTime?
  parentInvoiceId   String?
  
  // Amounts
  amount            Float
  subtotal          Float?
  tax               Float?        @default(0)
  discount          Float?        @default(0)
  
  // Dates
  issueDate         DateTime      @default(now())
  dueDate           DateTime
  paidDate          DateTime?
  
  // Status
  status            InvoiceStatus @default(UNPAID)
  
  // Billing Info
  billingEmail      String?
  billingName       String?
  billingAddress    Json?
  
  // Storage
  pdfUrl            String?
  pdfPath           String?
  
  // Email Tracking
  emailSentAt       DateTime?
  emailSentTo       Json?
  lastReminderSentAt DateTime?
  reminderCount     Int           @default(0)
  
  // Data
  metadata          Json?
  
  // Audit
  createdAt         DateTime      @default(now())
  updatedAt         DateTime      @updatedAt
  userId            String?
  createdBy         String?

  payments          Payment[]
  user              User?         @relation(fields: [userId], references: [id])

  @@index([subscriptionId])
  @@index([status])
  @@index([dueDate])
  @@index([isRecurring, nextInvoiceDate])
  @@index([parentInvoiceId])
}
```

### Status Enum
```prisma
enum InvoiceStatus {
  DRAFT | UNPAID | PARTIALLY_PAID | PAID | 
  PAYMENT_RECEIVED | OVERDUE | CANCELLED | REFUNDED
}
```

### Billing Cycle Enum
```prisma
enum BillingCycle {
  WEEKLY | MONTHLY | QUARTERLY | SEMI_ANNUAL | ANNUAL
}
```

---

## Core Services

### 1. InvoiceService
**File:** `backend/src/services/invoice.service.ts` (663 lines)

#### Key Methods

```typescript
// Create from subscription
createInvoiceFromSubscription(
  subscriptionId: string,
  subscriptionType: 'INDIVIDUAL' | 'TENANT'
): Promise<Invoice>

// Manual creation
createInvoice(data: CreateInvoiceDto): Promise<Invoice>

// Payment handling
markAsPaid(invoiceId: string, paymentId?: string): Promise<Invoice>

// Queries
listInvoicesWithFilters(filters): Promise<{
  invoices: Invoice[];
  total: number;
  stats: InvoiceStats;
}>

getOverdueInvoices(maxReminders: number = 3): Promise<Invoice[]>

// Tracking
trackEmailSent(invoiceId: string, email: string): Promise<void>
trackReminderSent(invoiceId: string): Promise<void>
```

---

### 2. PDFGeneratorService
**File:** `backend/src/services/pdf-generator.service.ts` (400+ lines)

#### Purpose
Generate professional PDF invoices using Puppeteer.

#### Main Method
```typescript
async generateAndUploadPDF(invoice: Invoice): Promise<string>
```

**Process:**
1. Fetch invoice configuration
2. Generate HTML template
3. Launch Puppeteer headless browser
4. Render PDF (A4, portrait)
5. Upload to MinIO
6. Update invoice.pdfUrl
7. Cleanup temp files
8. Return MinIO URL

**PDF Template Features:**
- Professional styling (blue accents)
- Company branding
- Line items table
- Totals with tax/discount
- Status badges
- Responsive for print

---

### 3. InvoiceEmailService
**File:** `backend/src/services/invoice-email.service.ts` (350+ lines)

#### Purpose
Handle all invoice email communications.

#### Key Methods

```typescript
// Send invoice
sendInvoiceEmail(
  invoiceId: string,
  recipientEmail: string,
  options?: { customSubject?, customMessage?, attachPDF? }
): Promise<void>

// Send reminder
sendPaymentReminder(invoiceId: string): Promise<void>

// Send receipt
sendPaymentReceipt(invoiceId: string): Promise<void>

// Batch send
batchSendInvoices(invoiceIds: string[]): Promise<{
  successful: string[];
  failed: Array<{ id: string; error: string }>;
}>
```

#### Email Templates Used
1. **SUBSCRIPTION_INVOICE** - New invoice notification
2. **INVOICE_REMINDER** - Overdue payment reminder
3. **INVOICE_RECEIPT** - Payment confirmation

---

## API Endpoints

### Base: `/api/v2/finance/invoices`

---

### 1. Create Invoice
```
POST /api/v2/finance/invoices/create
```

**Body:**
```json
{
  "userId": "uuid",
  "amount": 206.00,
  "dueDate": "2025-11-16",
  "billingEmail": "user@example.com",
  "billingName": "John Doe",
  "isRecurring": true,
  "billingCycle": "MONTHLY",
  "metadata": {
    "items": [
      {
        "description": "Monthly Subscription",
        "quantity": 1,
        "unitPrice": 206.00,
        "amount": 206.00
      }
    ]
  }
}
```

**Response:**
```json
{
  "success": true,
  "invoice": {
    "id": "uuid",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "isRecurring": true,
    "billingCycle": "MONTHLY",
    "nextInvoiceDate": "2025-11-17T00:00:00Z"
  }
}
```

---

### 2. Get Invoice
```
GET /api/v2/finance/invoices/[id]
```

**Response:**
```json
{
  "success": true,
  "invoice": {
    "id": "uuid",
    "invoiceNumber": "INV-2025-001",
    "amount": 206.00,
    "status": "UNPAID",
    "pdfUrl": "https://minio.../invoice.pdf",
    "isRecurring": true,
    "billingCycle": "MONTHLY",
    "nextInvoiceDate": "2025-11-17",
    "metadata": { "items": [...] }
  }
}
```

---

### 3. List Invoices
```
GET /api/v2/finance/invoices/list?status=UNPAID&search=john
```

**Query Params:**
- `status` - Filter by status
- `dateFrom`, `dateTo` - Date range
- `search` - Search invoice number/name/email
- `page`, `limit` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "invoices": [...],
    "total": 45,
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

### 4. Send Email
```
POST /api/v2/finance/invoices/[id]/send-email
```

**Body:**
```json
{
  "recipientEmail": "custom@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice email sent successfully"
}
```

---

### 5. Mark as Paid
```
POST /api/v2/finance/invoices/[id]/mark-paid
```

**Body:**
```json
{
  "paymentId": "uuid",
  "sendReceipt": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice marked as paid",
  "invoice": {
    "id": "uuid",
    "status": "PAID",
    "paidDate": "2025-10-17T10:00:00Z"
  }
}
```

---

## Scheduled Jobs

### 1. Invoice Generation Job
**File:** `backend/src/jobs/invoice-generation.job.ts`  
**Schedule:** Daily at 1:00 AM

**Purpose:** Auto-generate recurring invoices

**Logic:**
```typescript
1. Find invoices WHERE:
   - isRecurring = true
   - nextInvoiceDate <= TODAY
   - status = PAID (parent)

2. For each:
   - Create new invoice (duplicate parent)
   - Set issueDate = TODAY
   - Calculate new dueDate based on billingCycle
   - Calculate new nextInvoiceDate
   - Link parentInvoiceId
   - Generate PDF
   - Send email
   - Update parent.nextInvoiceDate
```

**Next Invoice Date Calculation:**
```typescript
WEEKLY:      currentDueDate + 7 days
MONTHLY:     currentDueDate + 1 month
QUARTERLY:   currentDueDate + 3 months
SEMI_ANNUAL: currentDueDate + 6 months
ANNUAL:      currentDueDate + 1 year
```

---

### 2. Payment Reminder Job
**File:** `backend/src/jobs/invoice-reminder.job.ts`  
**Schedule:** Daily at 9:00 AM

**Purpose:** Send overdue reminders

**Logic:**
```typescript
1. Find invoices WHERE:
   - status = UNPAID
   - dueDate < TODAY
   - reminderCount < 3

2. For each:
   - Calculate days overdue
   - Send INVOICE_REMINDER email
   - Increment reminderCount
   - Update lastReminderSentAt
```

**Reminder Schedule:**
- 1st: 1-3 days after due
- 2nd: 7 days after due
- 3rd: 14 days after due
- After 3: Manual intervention

---

### Running Jobs

**Start all jobs:**
```bash
npm run jobs:start
```

**With PM2 (production):**
```bash
pm2 start src/jobs/index.ts --name "invoice-jobs" --interpreter ts-node
pm2 save
pm2 startup
```

**Monitor:**
```bash
pm2 logs invoice-jobs
```

---

## Configuration

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://...

# Email (Brevo)
BREVO_API_KEY=your_key

# MinIO Storage
MINIO_ENDPOINT=your_endpoint
MINIO_ACCESS_KEY=your_key
MINIO_SECRET_KEY=your_secret
MINIO_BUCKET=invoices

# Base URLs
BASE_URL=https://gabay.online
NEXT_PUBLIC_API_URL=https://api.gabay.online
```

---

## Deployment

### 1. Database Setup
```bash
cd backend
npx prisma db push
npx prisma generate
```

### 2. Seed Email Templates
```bash
npx tsx src/scripts/setup-invoice-email-templates.ts
```

Expected output:
```
🚀 Starting invoice email templates setup...
📧 Setting up template: Subscription Invoice (SUBSCRIPTION_INVOICE)
✅ Successfully set up: Subscription Invoice
📧 Setting up template: Invoice Payment Reminder (INVOICE_REMINDER)
✅ Successfully set up: Invoice Payment Reminder
📧 Setting up template: Payment Receipt (INVOICE_RECEIPT)
✅ Successfully set up: Payment Receipt
✨ Invoice email templates setup completed!
```

### 3. Start Scheduled Jobs
```bash
pm2 start src/jobs/index.ts --name "invoice-jobs" --interpreter ts-node
pm2 save
```

### 4. Deploy Frontend
```bash
cd frontend
npm run build
```

### 5. Verify
- ✅ Check invoice creation: POST /api/v2/finance/invoices/create
- ✅ Check PDF generation: MinIO bucket
- ✅ Check email sending: Customer inbox
- ✅ Check jobs: `pm2 logs invoice-jobs`
- ✅ Check dashboard: `/finance/invoices`

---

## Frontend Routes

### Pages
- `/finance/invoices` - List all invoices
- `/finance/invoices/[id]` - Invoice details
- `/finance/invoices/create` - Create new invoice

### Features
- Summary cards (Total, Unpaid, Paid, Overdue)
- Tab filtering
- Search & sort
- Status badges
- PDF download
- Email resend
- Mark as paid
- Recurring subscription management

---

## API Error Codes

- `400` - Bad request (validation error)
- `401` - Unauthorized
- `403` - Forbidden (access denied)
- `404` - Invoice not found
- `500` - Server error

---

## Monitoring

### Health Checks
- Invoice creation rate
- PDF generation success rate
- Email delivery rate
- Job execution logs
- Overdue invoice count

### PM2 Commands
```bash
pm2 status          # Check job status
pm2 logs            # View logs
pm2 restart         # Restart jobs
pm2 stop            # Stop jobs
```

---

## Troubleshooting

### Emails not sending
1. Check BREVO_API_KEY
2. Verify templates exist: `SELECT * FROM EmailTemplate WHERE code LIKE 'INVOICE%'`
3. Check EmailTemplateService logs

### PDFs not generating
1. Check Puppeteer installation: `npm list puppeteer`
2. Verify MinIO credentials
3. Check disk space for temp files

### Jobs not running
1. Check PM2 status: `pm2 status`
2. View logs: `pm2 logs invoice-jobs`
3. Restart: `pm2 restart invoice-jobs`

### Duplicate invoices
1. Check nextInvoiceDate values
2. Verify job ran only once
3. Check logs for duplicate prevention

---

## Support Files

Related documentation:
- `INVOICE_AUTOMATION_PLAN.md` - Original implementation plan
- `INVOICE_AUTOMATION_COMPLETE.md` - Feature completion status
- `INVOICE_QUICK_START_GUIDE.md` - Quick reference
- `backend/src/jobs/README.md` - Jobs documentation

---

**Document Version:** 2.0.0  
**Last Updated:** October 17, 2025  
**Maintained By:** Development Team
