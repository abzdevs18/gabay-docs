# Invoice Automation System - Documentation Index

**Version:** 2.0.0  
**Last Updated:** October 17, 2025  
**Status:** Production-Ready ✅

---

## 📚 Documentation Overview

This directory contains comprehensive technical documentation for the Invoice Automation System, a complete billing solution supporting automatic invoice generation, PDF creation, email automation, and recurring subscriptions.

---

## 📖 Documentation Files

### 1. **INVOICE_SYSTEM_TECHNICAL_DOCS.md**
**Complete technical reference covering:**
- System architecture and data flow
- Database schema (Invoice, InvoiceConfiguration models)
- Core services (InvoiceService, PDFGeneratorService, InvoiceEmailService)
- API endpoints (create, list, get, send-email, mark-paid)
- Scheduled jobs (recurring generation, payment reminders)
- Configuration and deployment guide

**👉 Start here for system understanding and deployment**

---

### 2. **INVOICE_API_INTEGRATION_GUIDE.md**
**API reference and integration guide covering:**
- Complete API endpoint documentation with examples
- Request/response formats
- Email template specifications
- Frontend integration patterns (React hooks, queries, mutations)
- Webhook events
- Code examples for common use cases

**👉 Use this for API integration and frontend development**

---

### 3. **RECURRING_SUBSCRIPTIONS_GUIDE.md**
**Comprehensive guide for recurring billing:**
- How recurring subscriptions work
- Billing cycles (WEEKLY, MONTHLY, QUARTERLY, SEMI_ANNUAL, ANNUAL)
- Database structure for recurring invoices
- Creating and managing recurring invoices
- Automated generation process
- Cancellation and modification procedures
- Troubleshooting common issues

**👉 Essential for implementing and managing recurring billing**

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL database
- MinIO or S3 storage
- Brevo/SendGrid API key

### Installation

**1. Install dependencies:**
```bash
cd backend
npm install puppeteer@latest node-cron@^3.0.0
```

**2. Run database migration:**
```bash
npx prisma db push
npx prisma generate
```

**3. Seed email templates:**
```bash
npx tsx src/scripts/setup-invoice-email-templates.ts
```

**4. Start scheduled jobs:**
```bash
pm2 start src/jobs/index.ts --name "invoice-jobs" --interpreter ts-node
pm2 save
```

**5. Verify:**
- ✅ Create test invoice: `POST /api/v2/finance/invoices/create`
- ✅ Check PDF generation: MinIO bucket
- ✅ Check email delivery: Customer inbox
- ✅ Check job status: `pm2 logs invoice-jobs`

---

## 🏗️ System Architecture

```
┌────────────────────────────────────────────────────────────┐
│              Invoice Automation System                      │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  Subscription Created                                        │
│         ↓                                                    │
│  InvoiceService.createInvoiceFromSubscription()             │
│         ├─ Generate invoice number                          │
│         ├─ Calculate totals                                 │
│         ├─ Set recurring billing (if enabled)               │
│         └─ Calculate nextInvoiceDate                        │
│         ↓                                                    │
│  PDFGeneratorService.generateAndUploadPDF()                 │
│         ├─ Render HTML template                             │
│         ├─ Generate PDF (Puppeteer)                         │
│         └─ Upload to MinIO                                  │
│         ↓                                                    │
│  InvoiceEmailService.sendInvoiceEmail()                     │
│         ├─ Fetch SUBSCRIPTION_INVOICE template              │
│         ├─ Compile with Handlebars                          │
│         ├─ Attach PDF                                       │
│         └─ Send via Brevo/SendGrid                          │
│                                                              │
│  ┌──────────────────┐        ┌──────────────────┐          │
│  │  Scheduled Jobs  │        │   Admin Dashboard│          │
│  │  (node-cron)     │        │   (/finance/    │          │
│  │                  │        │    invoices)     │          │
│  │  • Daily 1 AM:   │        │                  │          │
│  │    Generate      │        │  • View list     │          │
│  │    recurring     │        │  • Invoice detail│          │
│  │                  │        │  • Send email    │          │
│  │  • Daily 9 AM:   │        │  • Mark paid     │          │
│  │    Send          │        │  • Download PDF  │          │
│  │    reminders     │        │  • Create manual │          │
│  └──────────────────┘        └──────────────────┘          │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

---

## 🎯 Core Features

### ✅ Automatic Invoice Generation
- Auto-generate from subscriptions (INDIVIDUAL or TENANT)
- Manual invoice creation via API or dashboard
- Professional PDF generation with Puppeteer
- MinIO storage with secure URLs

### ✅ Email Automation
- 3 professional email templates:
  - **SUBSCRIPTION_INVOICE** - New invoice notification
  - **INVOICE_REMINDER** - Overdue payment reminder
  - **INVOICE_RECEIPT** - Payment confirmation
- PDF attachments
- Handlebars variable interpolation
- Tracking (emailSentAt, reminderCount)

### ✅ Recurring Subscriptions (NEW in v2.0)
- 5 billing cycles: WEEKLY, MONTHLY, QUARTERLY, SEMI_ANNUAL, ANNUAL
- Automated generation via scheduled job
- Intelligent date calculations
- Parent-child invoice relationships
- Duplicate prevention
- Easy cancellation and modification

### ✅ Payment Tracking
- Multiple statuses (DRAFT, UNPAID, PAID, OVERDUE, etc.)
- Payment linking
- Automatic receipt sending
- Payment history

### ✅ Admin Dashboard
- Invoice list with filtering and search
- Summary statistics (total, unpaid, paid, overdue)
- Invoice detail view
- Actions: Download PDF, Send email, Mark as paid
- Create manual invoices

### ✅ Scheduled Jobs
- **Invoice Generation Job** - Daily at 1:00 AM
- **Payment Reminder Job** - Daily at 9:00 AM
- PM2 process management
- Error handling and logging

---

## 📊 Database Schema

### Key Models

**Invoice:**
- Customer info (userId, tenantId, subscriptionId)
- Recurring settings (isRecurring, billingCycle, nextInvoiceDate, parentInvoiceId)
- Amounts (amount, subtotal, tax, discount)
- Dates (issueDate, dueDate, paidDate)
- Status tracking
- File storage (pdfUrl, pdfPath)
- Email tracking (emailSentAt, reminderCount)

**InvoiceConfiguration:**
- Tenant-specific branding
- Company details
- Tax settings
- Default terms

---

## 🔌 API Endpoints

### Base URL
`/api/v2/finance/invoices`

### Available Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/create` | Create new invoice (manual or recurring) |
| GET | `/list` | List invoices with filters |
| GET | `/[id]` | Get invoice details |
| POST | `/[id]/send-email` | Send/resend invoice email |
| POST | `/[id]/mark-paid` | Mark invoice as paid |
| DELETE | `/[id]` | Cancel/delete invoice |

**See INVOICE_API_INTEGRATION_GUIDE.md for detailed API documentation**

---

## 🔄 Recurring Subscriptions

### Billing Cycles

| Cycle | Next Invoice Calculation |
|-------|-------------------------|
| WEEKLY | Current due date + 7 days |
| MONTHLY | Current due date + 1 month |
| QUARTERLY | Current due date + 3 months |
| SEMI_ANNUAL | Current due date + 6 months |
| ANNUAL | Current due date + 1 year |

### Automated Process

**Daily at 1:00 AM:**
1. Find invoices where `isRecurring = true` and `nextInvoiceDate <= TODAY`
2. For each:
   - Check for duplicates
   - Create new invoice (duplicate parent)
   - Update dates
   - Generate PDF
   - Send email
   - Update parent's nextInvoiceDate

**See RECURRING_SUBSCRIPTIONS_GUIDE.md for complete details**

---

## 🖥️ Frontend Routes

| Route | Description |
|-------|-------------|
| `/finance/invoices` | Invoice list dashboard |
| `/finance/invoices/[id]` | Invoice detail view |
| `/finance/invoices/create` | Create new invoice form |

**Features:**
- Summary cards
- Tab filtering (All, Unpaid, Paid, Overdue)
- Search and sort
- Status badges
- PDF download
- Email resend
- Mark as paid
- Recurring subscription management

---

## ⚙️ Configuration

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:password@host:port/database

# Email Service
BREVO_API_KEY=your_brevo_api_key

# MinIO Storage
MINIO_ENDPOINT=your_minio_endpoint
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key
MINIO_BUCKET=invoices

# Base URLs
BASE_URL=https://gabay.online
NEXT_PUBLIC_API_URL=https://api.gabay.online
```

---

## 🔧 Operations

### Starting Scheduled Jobs

**Development:**
```bash
npm run jobs:start
```

**Production (PM2):**
```bash
pm2 start src/jobs/index.ts --name "invoice-jobs" --interpreter ts-node
pm2 save
pm2 startup
```

### Monitoring

**View logs:**
```bash
pm2 logs invoice-jobs
```

**Check status:**
```bash
pm2 status
```

**Restart:**
```bash
pm2 restart invoice-jobs
```

---

## 🧪 Testing

### Manual Tests

**1. Create invoice:**
```bash
POST /api/v2/finance/invoices/create
{
  "userId": "test-user-id",
  "amount": 206.00,
  "dueDate": "2025-12-31",
  "billingEmail": "test@example.com",
  "billingName": "Test User",
  "isRecurring": true,
  "billingCycle": "MONTHLY"
}
```

**2. Check MinIO:**
- Verify PDF uploaded
- URL accessible

**3. Check email:**
- Verify email delivered
- PDF attached
- Variables rendered

**4. Check scheduled job:**
```bash
npm run jobs:invoice-generation
```

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Emails not sending | Check BREVO_API_KEY, verify templates exist |
| PDFs not generating | Check Puppeteer installation, MinIO credentials |
| Jobs not running | Check PM2 status, restart jobs |
| Duplicate invoices | Verify nextInvoiceDate, check logs |
| Wrong amounts | Check metadata.items array |

**See documentation files for detailed troubleshooting**

---

## 📞 Support

### Documentation Files Priority

1. **For deployment:** Read INVOICE_SYSTEM_TECHNICAL_DOCS.md
2. **For API integration:** Read INVOICE_API_INTEGRATION_GUIDE.md
3. **For recurring billing:** Read RECURRING_SUBSCRIPTIONS_GUIDE.md

### External Resources

- Puppeteer Docs: https://pptr.dev/
- Prisma Docs: https://www.prisma.io/docs
- node-cron: https://www.npmjs.com/package/node-cron
- PM2 Docs: https://pm2.keymetrics.io/docs

---

## 📝 Changelog

### Version 2.0.0 (October 17, 2025)
- ✅ Added recurring subscription support
- ✅ Added billing cycles (WEEKLY, MONTHLY, QUARTERLY, SEMI_ANNUAL, ANNUAL)
- ✅ Added nextInvoiceDate calculation
- ✅ Added parentInvoiceId linking
- ✅ Updated invoice creation API
- ✅ Updated frontend create form
- ✅ Enhanced scheduled jobs
- ✅ Updated documentation

### Version 1.0.0 (October 16, 2025)
- ✅ Initial invoice automation system
- ✅ PDF generation with Puppeteer
- ✅ Email automation with templates
- ✅ Payment tracking
- ✅ Admin dashboard
- ✅ Scheduled reminders

---

## 🎓 Related Documentation

### Project Root
- `INVOICE_AUTOMATION_PLAN.md` - Original implementation plan
- `INVOICE_AUTOMATION_COMPLETE.md` - Feature completion status
- `INVOICE_QUICK_START_GUIDE.md` - Quick reference guide

### Backend
- `backend/src/jobs/README.md` - Scheduled jobs documentation
- `backend/src/services/` - Service implementations
- `backend/prisma/schema/invoice.prisma` - Database schema

---

## ✅ Production Checklist

- [ ] Database migrated and indexed
- [ ] Email templates seeded
- [ ] MinIO bucket created
- [ ] Environment variables configured
- [ ] Puppeteer dependencies installed
- [ ] Scheduled jobs running (PM2)
- [ ] Test invoice created successfully
- [ ] Test PDF generated and accessible
- [ ] Test email sent and received
- [ ] Recurring invoice tested
- [ ] Dashboard accessible
- [ ] Monitoring configured
- [ ] Backups configured

---

**Maintained By:** Development Team  
**Support:** See individual documentation files  
**Version:** 2.0.0  
**Status:** Production-Ready ✅
