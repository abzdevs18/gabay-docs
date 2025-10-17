# Unified Worker System - Single Process Management

## 🎯 Overview

The Gabay platform now uses a **unified Worker Manager** that manages all background workers in a **single process**. This simplifies deployment, monitoring, and resource management.

---

## 🏗️ Architecture

```
Single Worker Process (start-workers.ts)
        ↓
Worker Manager Service
        ↓
    ┌───────────────────────────────────┐
    │                                   │
    ▼                                   ▼
Question Generation Workers     Form Response Worker
    (BullMQ Pool)                  (BullMQ Worker)
        ↓                                   ↓
  Multiple Queues                    Single Queue
  - retrieval                    - form-response-processing
  - generation
  - validation
```

---

## ✅ Managed Worker Types

### 1. **Question Generation Workers**
- **Purpose**: AI-powered question generation from documents
- **Concurrency**: Multiple workers with parallel processing
- **Queues**: Retrieval, Generation, Validation
- **Provider**: DeepSeek (draft) + OpenAI (validation)

### 2. **Form Response Worker** (NEW)
- **Purpose**: AI-powered personalized feedback for exam submissions
- **Concurrency**: 3 simultaneous jobs
- **Queue**: form-response-processing
- **Provider**: OpenAI (gpt-4o-mini) or DeepSeek
- **Rate Limit**: 10 jobs/minute

---

## 🚀 Starting the Unified Worker System

### Single Command

```bash
# Development
npm run dev:workers

# Production
npm run start:workers
```

That's it! Both worker types start automatically.

---

## ⚙️ Configuration

### Environment Variables

```bash
# AI Provider Keys
OPENAI_API_KEY=sk-...           # Primary for both workers
DEEPSEEK_API_KEY=...            # Fallback for both workers

# Model Configuration (Optional)
OPENAI_CHAT_MODEL=gpt-4o-mini       # For chat & question generation
OPENAI_FEEDBACK_MODEL=gpt-4o-mini   # For form feedback (defaults to CHAT_MODEL)

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Email Service (for form response worker)
BREVO_API_KEY=...
```

### Worker Configuration

To disable form response worker (if needed):

```typescript
// In start-workers.ts or programmatically
const workerManager = WorkerManager.getInstance({
  enableFormResponseWorker: false  // Disable form feedback
});
```

---

## 📊 Monitoring

### Console Logs

Every 30 seconds, you'll see:

```bash
📈 Question Generation - Workers: 3, Active: 2, Waiting: 5, Completed: 143
📧 Form Response - Active: 1, Waiting: 3, Completed: 87, Failed: 0
```

### Status API (Future Enhancement)

```typescript
const status = await workerManager.getStatus();

console.log(status);
// {
//   healthy: true,
//   workers: { isRunning: true, workerCount: 3, concurrency: 3 },
//   queues: { active: 2, waiting: 5, completed: 143, failed: 1 },
//   formResponseWorker: { active: 1, waiting: 3, completed: 87, failed: 0 },
//   restartAttempts: 0,
//   uptime: 3600
// }
```

---

## 🛑 Graceful Shutdown

The unified system handles shutdown gracefully:

```bash
# Press Ctrl+C or send SIGTERM
📡 Received SIGINT, shutting down gracefully...
⏸️  Queues paused
⏳ Waiting for 3 active jobs to complete...
🛑 Stopping form response worker...
✅ Form response worker stopped
✅ Form response queue closed
🛑 Stopping question generation workers...
✅ Question generation workers stopped
✅ Question generation queue closed
✅ All worker systems stopped
✅ Graceful shutdown completed
```

**Features:**
- Pauses queues (no new jobs accepted)
- Waits for active jobs to complete (max 30 seconds)
- Closes all workers cleanly
- Closes all queue connections

---

## 🔧 Management Commands

### Pause All Queues

```typescript
await workerManager.pauseQueues();
```

### Resume All Queues

```typescript
await workerManager.resumeQueues();
```

### Restart Workers

```typescript
await workerManager.restart();
```

### Get Status

```typescript
const status = await workerManager.getStatus();
```

---

## 🎯 Benefits of Unified System

### ✅ Simplified Deployment

**Before (Separate Workers):**
```bash
# Terminal 1
npm run start:workers

# Terminal 2  
npm run start:form-worker

# Need to manage 2 processes
```

**After (Unified):**
```bash
# Single terminal
npm run start:workers

# Manages both worker types
```

### ✅ Centralized Monitoring

- Single health check for all workers
- Unified logging
- Single status endpoint
- Easier debugging

### ✅ Resource Efficiency

- Shared Redis connections
- Single process overhead
- Better memory management
- Unified error handling

### ✅ Easier Maintenance

- One codebase to update
- Single restart command
- Consistent configuration
- Simplified PM2/Docker setup

---

## 📦 Production Deployment

### Option 1: PM2 (Recommended)

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'gabay-api',
      script: 'npm',
      args: 'start',
      cwd: './api',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      }
    },
    {
      name: 'gabay-workers',  // Single worker process
      script: 'npm',
      args: 'run start:workers',
      cwd: './api',
      env: {
        NODE_ENV: 'production',
        WORKER_PROCESS: 'true'
      },
      instances: 1,  // Always 1 for workers
      autorestart: true,
      max_memory_restart: '1G'
    }
  ]
};
```

Start:
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Option 2: Docker Compose

```yaml
# docker-compose.yml
services:
  api:
    build: ./api
    ports:
      - "3001:3001"
    env_file:
      - .env
    depends_on:
      - redis
      - postgres

  workers:  # Single worker container
    build: ./api
    command: npm run start:workers
    env_file:
      - .env
    environment:
      - WORKER_PROCESS=true
    depends_on:
      - redis
      - postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: gabay
    ports:
      - "5432:5432"
```

Start:
```bash
docker-compose up -d
```

### Option 3: Kubernetes

```yaml
# workers-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gabay-workers
spec:
  replicas: 1  # Always 1 for BullMQ workers
  selector:
    matchLabels:
      app: gabay-workers
  template:
    metadata:
      labels:
        app: gabay-workers
    spec:
      containers:
      - name: workers
        image: gabay-api:latest
        command: ["npm", "run", "start:workers"]
        env:
        - name: WORKER_PROCESS
          value: "true"
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: gabay-secrets
              key: openai-api-key
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

---

## 🔍 Troubleshooting

### Workers Not Starting

```bash
# Check Redis connection
redis-cli ping

# Check environment variables
echo $OPENAI_API_KEY

# Check logs
tail -f logs/worker.log
```

### One Worker Type Not Running

Check configuration:
```typescript
// Verify in worker-manager.service.ts
enableFormResponseWorker: true  // Should be true
```

### High Memory Usage

Adjust concurrency:
```typescript
// In form-response-worker.service.ts
concurrency: 2  // Reduce from 3

// Or in question-generation config
concurrency: 2  // Reduce if needed
```

### Queue Stuck

```bash
# Pause all queues
redis-cli
> SMEMBERS bull:*:paused

# Resume via worker manager or manually
> DEL bull:form-response-processing:paused
```

---

## 📈 Performance Metrics

### Typical Resource Usage

**Idle State:**
- CPU: 1-5%
- Memory: 150-300 MB
- Redis: < 100 MB

**Active Processing:**
- CPU: 20-60%
- Memory: 300-600 MB
- Redis: 100-200 MB

**Peak Load (100 jobs):**
- CPU: 60-80%
- Memory: 600-900 MB
- Redis: 200-400 MB

### Throughput

**Question Generation:**
- 5-10 questions/minute (depends on complexity)

**Form Response Feedback:**
- 10-20 feedbacks/minute (rate limited)

---

## 🎯 Future Enhancements

### Planned Features

1. **Dynamic Worker Scaling**: Auto-scale based on queue depth
2. **Worker Health Dashboard**: Web UI for monitoring
3. **Job Prioritization**: Priority queues for urgent tasks
4. **Scheduled Jobs**: Cron-based background tasks
5. **Worker Metrics API**: REST API for status/metrics
6. **Alert System**: Email/Slack alerts for failures

### Potential Additional Workers

- **Grade Calculation Worker**: Auto-grade submissions
- **Report Generation Worker**: PDF reports for teachers
- **Email Digest Worker**: Daily/weekly summary emails
- **Analytics Worker**: Data processing and insights
- **Backup Worker**: Automated database backups

---

## 📚 Related Documentation

- [Form Response Worker System](./FORM_RESPONSE_WORKER_SYSTEM.md)
- [AI Chat System](./ai-chat-system/README.md)
- [Question Generation Workers](./ai-chat-system/QUESTION_GENERATION.md)
- [AI Feedback Cost Estimate](./AI_FEEDBACK_COST_ESTIMATE.md)

---

## ✅ Migration from Separate Workers

If you were using the separate `start-form-response-worker.ts`:

### Before
```bash
# Terminal 1
npm run start:workers

# Terminal 2
npm run start:form-worker
```

### After
```bash
# Single terminal
npm run start:workers

# Both workers start automatically!
```

### No Code Changes Needed

The integration is **backward compatible**. Both workers run automatically with the existing `start-workers` command.

---

**Version:** 2.0.0  
**Last Updated:** January 4, 2025  
**Migration Status:** ✅ Complete - Single unified worker system  
**Maintained by:** Gabay Development Team
