# Gabay Form - Worker System

> Background job processing for AI feedback and form generation

---

## Overview

The Gabay Form system uses a **unified worker manager** that handles all background processing tasks in a single, coordinated process.

For complete worker system documentation, see:
- **[Unified Worker System](../../UNIFIED_WORKER_SYSTEM.md)** - Main worker documentation
- **[Multi-Tenant Worker Support](../../MULTI_TENANT_WORKER_SUPPORT.md)** - Multi-tenancy guide

---

## Worker Types

### 1. Question Generation Workers
- **Purpose**: AI-powered question generation from documents
- **Queue**: `question-gen`
- **Concurrency**: 3 workers
- **Provider**: DeepSeek + OpenAI

### 2. Form Response Worker
- **Purpose**: AI-powered feedback for exam submissions
- **Queue**: `form-response-processing`
- **Concurrency**: 3 jobs
- **Rate Limit**: 10 jobs/minute
- **Provider**: OpenAI (gpt-4o-mini)

---

## Quick Start

### Start All Workers

```bash
# Development
npm run dev:workers

# Production
npm run start:workers
```

**Both worker types start automatically!**

### Monitor Status

```bash
# Console logs every 30 seconds
📈 Question Generation - Workers: 3, Active: 0, Waiting: 0
📧 Form Response - Active: 2, Waiting: 5, Completed: 1,234
```

---

## Architecture

```
WorkerManager (Singleton)
    ├── Question Generation Workers
    │   └── BullMQ Worker Pool
    └── Form Response Worker
        └── BullMQ Worker

All connected to Redis for job queue management
```

---

## Configuration

### Environment Variables

```bash
# AI Providers
OPENAI_API_KEY=sk-...
OPENAI_CHAT_MODEL=gpt-4o-mini
DEEPSEEK_API_KEY=sk-...

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Email
BREVO_API_KEY=...
```

### Adjust Settings

```typescript
// Disable form response worker
enableFormResponseWorker: false

// Change concurrency
concurrency: 5

// Adjust rate limit
limiter: { max: 20, duration: 60000 }
```

---

## Form Response Worker Details

### Job Data Structure

```typescript
{
  responseId: string;
  formId: string;
  studentEmail: string;
  studentName: string;
  studentLRN: string;
  answers: Record<string, any>;
  formTitle: string;
  teacherEmail?: string;
  teacherName?: string;
  metadata?: {...};
  tenantId?: string;      // Multi-tenant support
  tenantToken?: string;   // Multi-tenant support
}
```

### Processing Steps

1. **Fetch form data** (with tenant context)
2. **Analyze responses** (match answers to questions)
3. **Generate AI feedback** (via OpenAI)
4. **Create email HTML** (beautiful template)
5. **Send email** (via Brevo)
6. **Notify teacher** (if suspicious activity)

### Multi-Tenant Support

The worker respects tenant boundaries:
- Extracts tenant context from job data
- Uses correct Prisma client for tenant schema
- Sends emails with tenant branding

---

## Monitoring & Troubleshooting

### Health Checks

```typescript
const status = await workerManager.getStatus();
// {
//   healthy: true,
//   workers: {...},
//   queues: {...},
//   formResponseWorker: {...}
// }
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Worker not running | Check `npm run start:workers` |
| No emails sent | Verify `BREVO_API_KEY` |
| Redis errors | Check Redis connection |
| Rate limit errors | Reduce `limiter.max` |

### Debug Commands

```bash
# Check Redis
redis-cli ping

# Check queue stats
redis-cli LLEN bull:form-response-processing:wait

# View logs
tail -f logs/worker.log
```

---

## Production Deployment

### PM2 Configuration

```javascript
// ecosystem.config.js
{
  apps: [
    {
      name: 'gabay-workers',
      script: 'npm',
      args: 'run start:workers',
      instances: 1,  // Always 1 for BullMQ
      autorestart: true
    }
  ]
}
```

### Docker

```yaml
services:
  workers:
    build: ./api
    command: npm run start:workers
    environment:
      - WORKER_PROCESS=true
    depends_on:
      - redis
```

---

## Performance Metrics

**Form Response Worker:**
- Processing: 10-20 feedbacks/minute
- Success Rate: >99%
- Avg Processing Time: 5-8 seconds
- Email Delivery: 1-2 seconds

**Resource Usage:**
- CPU: 20-60% (during processing)
- Memory: 300-600 MB
- Redis: 100-200 MB

---

## Related Documentation

- [Unified Worker System](../../UNIFIED_WORKER_SYSTEM.md)
- [Multi-Tenant Worker Support](../../MULTI_TENANT_WORKER_SUPPORT.md)
- [AI Feedback System](./ai-feedback-system.md)
- [Form Response Worker System](../../FORM_RESPONSE_WORKER_SYSTEM.md)
