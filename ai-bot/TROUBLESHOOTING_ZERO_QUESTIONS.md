# Question Generator Troubleshooting Guide - Zero Questions Issue

## Immediate Action Plan

Based on your logs showing **64.5% failure rate** and **0 questions generated**, here's the step-by-step troubleshooting approach:

---

## Step 1: Verify API Key Configuration

### Check Current Configuration
```bash
# Navigate to API directory
cd "c:\Users\clint\Documents\GitHub\api"

# Check if API keys are configured
node -e "console.log('DEEPSEEK:', !!process.env.DEEPSEEK_API_KEY, 'OPENAI:', !!process.env.OPENAI_API_KEY)"
```

### Test API Health Endpoint
```bash
# Test the health endpoint to see API key status
curl http://localhost:3000/api/v2/question-generator/health
```

**Expected Response**:
```json
{
  "success": true,
  "status": "healthy",
  "environment": {
    "deepseekApiKey": true,  // ⚠️ Should be true
    "openaiApiKey": true,    // ⚠️ Should be true
    "databaseConnected": true
  }
}
```

### If API Keys Missing
Create or update your `.env.local` file:
```bash
# api/.env.local
DEEPSEEK_API_KEY=sk-your-deepseek-key-here
OPENAI_API_KEY=sk-your-openai-key-here
```

---

## Step 2: Test LLM Provider Connectivity

### Test DeepSeek API
```bash
curl -X POST https://api.deepseek.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_DEEPSEEK_KEY" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

### Test OpenAI API
```bash
curl -X POST https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_OPENAI_KEY" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

**Expected**: Both should return valid JSON responses, not 401/403 errors.

---

## Step 3: Check Worker Pool Status

### Worker Status API
```bash
# Check if workers are running
curl http://localhost:3000/api/v2/question-generator/workers/status
```

**Expected Response**:
```json
{
  "success": true,
  "workers": {
    "active": 2,
    "idle": 0,
    "failed": 0
  },
  "health": "healthy"
}
```

### Queue Status API
```bash
# Check queue health
curl http://localhost:3000/api/v2/question-generator/queue/stats
```

**Expected Response**:
```json
{
  "success": true,
  "queues": {
    "active": 1,
    "waiting": 0,
    "completed": 10,
    "failed": 20  // ⚠️ High failed count indicates issues
  }
}
```

---

## Step 4: Database Inspection

### Check if Questions Were Actually Generated

Connect to your PostgreSQL database and run:

```sql
-- Check if any questions exist
SELECT COUNT(*) FROM "QuestionItem";

-- Check recent generation jobs
SELECT id, status, "errorMessage", "createdAt" 
FROM "GenerationJob" 
ORDER BY "createdAt" DESC 
LIMIT 10;

-- Check failed tasks
SELECT id, status, "validationResults", "questionType"
FROM "QuestionGenerationTask" 
WHERE status = 'failed' 
ORDER BY "createdAt" DESC 
LIMIT 10;

-- Check if document chunks exist
SELECT COUNT(*) FROM "DocumentChunk";

-- Check if plans were created
SELECT id, status, "totalQuestions", "errorMessage"
FROM "QuestionPlan" 
ORDER BY "createdAt" DESC 
LIMIT 5;
```

**What to Look For**:
- ❌ **0 QuestionItems**: Questions aren't being generated
- ❌ **All Jobs Failed**: Worker execution issues
- ❌ **No DocumentChunks**: Document processing failed
- ❌ **No QuestionPlans**: Planning stage failed

---

## Step 5: Monitor Live Generation Process

### Start a Test Generation with Monitoring

1. **Start API Server** with debug logging:
```bash
cd "c:\Users\clint\Documents\GitHub\api"
export DEBUG=gabay:*
export LOG_LEVEL=debug
npm run dev
```

2. **Upload Test Document**:
```bash
curl -X POST http://localhost:3000/api/v2/question-generator/upload \
  -F "document=@test.txt" \
  -F "extractionStrategy=auto"
```

3. **Create Question Plan**:
```bash
curl -X POST http://localhost:3000/api/v2/question-generator/create-plan \
  -H "Content-Type: application/json" \
  -d '{
    "documentId": "YOUR_DOC_ID",
    "questionTypes": {
      "mcq": {"count": 2, "difficulty": "easy"}
    },
    "subject": "General",
    "gradeLevel": "Middle School"
  }'
```

4. **Start Generation** and monitor logs:
```bash
curl -X POST http://localhost:3000/api/v2/question-generator/start-generation \
  -H "Content-Type: application/json" \
  -d '{
    "planId": "YOUR_PLAN_ID",
    "priority": 5
  }'
```

### Watch for These Log Patterns

**✅ Success Patterns**:
```
🚀 Starting Question Generation Worker Pool...
🤖 Using deepseek for draft generation, openai for validation
▶️ Job xxx is now active on worker 0
[QG] Retrieved context chunks=3, tokens≈850
[QG] Generated question for task xxx
✅ Job xxx completed successfully
```

**❌ Failure Patterns**:
```
⚠️ DEEPSEEK_API_KEY not configured
❌ DeepSeek API error: 401 Unauthorized
⚠️ OPENAI_API_KEY not configured  
❌ Task xxx failed: API error
💓 Health check: Unhealthy
```

---

## Step 6: Fix Common Issues

### Issue 1: Missing API Keys

**Symptoms**: Workers fail immediately, 401/403 errors in logs

**Fix**: Add valid API keys to environment:
```bash
# In api/.env.local
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx

# Restart server
npm run dev
```

### Issue 2: Worker Pool Not Starting

**Symptoms**: "Worker configuration required" errors

**Fix**: The updated worker pool creation should handle this, but verify:
```bash
# Check worker manager initialization
curl http://localhost:3000/api/v2/question-generator/workers/restart
```

### Issue 3: Progress Streaming Issues

**Symptoms**: "Broadcasting to 0 subscribers"

**Fix**: Test SSE connection manually:
```javascript
// In browser console
const eventSource = new EventSource('/api/v2/question-generator/stream/progress/YOUR_PLAN_ID');
eventSource.onmessage = (event) => console.log('Progress:', JSON.parse(event.data));
eventSource.onerror = (error) => console.error('SSE Error:', error);
```

### Issue 4: Database Connection Issues

**Symptoms**: Prisma errors, connection refused

**Fix**: Verify database configuration:
```bash
# Test database connection
npx prisma studio

# Run migrations if needed
npx prisma migrate dev

# Check if pgvector extension is installed
psql -d your_database -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

---

## Step 7: Validate the Complete Flow

### End-to-End Test Script

Create a test script to validate the entire flow:

```bash
#!/bin/bash
# test-question-generation.sh

# 1. Test health
echo "Testing system health..."
curl -s http://localhost:3000/api/v2/question-generator/health | jq .

# 2. Upload test document
echo "Uploading test document..."
DOC_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v2/question-generator/upload \
  -F "document=@test.txt" \
  -F "extractionStrategy=auto")
DOC_ID=$(echo $DOC_RESPONSE | jq -r .document_id)
echo "Document ID: $DOC_ID"

# 3. Create plan
echo "Creating question plan..."
PLAN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v2/question-generator/create-plan \
  -H "Content-Type: application/json" \
  -d "{\"documentId\": \"$DOC_ID\", \"questionTypes\": {\"mcq\": {\"count\": 3}}}")
PLAN_ID=$(echo $PLAN_RESPONSE | jq -r .planId)
echo "Plan ID: $PLAN_ID"

# 4. Start generation
echo "Starting generation..."
curl -s -X POST http://localhost:3000/api/v2/question-generator/start-generation \
  -H "Content-Type: application/json" \
  -d "{\"planId\": \"$PLAN_ID\", \"priority\": 5}"

# 5. Monitor status
echo "Monitoring status..."
for i in {1..10}; do
  sleep 5
  STATUS=$(curl -s http://localhost:3000/api/v2/question-generator/status/$PLAN_ID | jq -r .status)
  echo "Status check $i: $STATUS"
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
    break
  fi
done

# 6. Get results
echo "Getting results..."
curl -s http://localhost:3000/api/v2/question-generator/plan/$PLAN_ID/questions | jq .
```

---

## Step 8: Environment Variable Checklist

Ensure all required environment variables are set:

```bash
# Required for Question Generator
DEEPSEEK_API_KEY=sk-xxxxx        # Primary LLM provider
OPENAI_API_KEY=sk-xxxxx          # Fallback LLM provider
DATABASE_URL=postgresql://...    # PostgreSQL with pgvector
REDIS_URL=redis://localhost:6379 # Redis for job queue

# Optional tuning
WORKER_CONCURRENCY=4             # Number of parallel workers
WORKER_RETRY_ATTEMPTS=3          # Retry failed jobs
WORKER_TIMEOUT=180000            # 3 minutes timeout
AI_REQUEST_TIMEOUT_MS=30000      # 30 seconds LLM timeout

# Debug options
QG_DEBUG=true                    # Enable detailed logging
DEBUG=gabay:*                    # Enable all debug logs
LOG_LEVEL=debug                  # Verbose logging
```

---

## Expected Success Indicators

When everything is working correctly, you should see:

1. **Health Check**: ✅ All services healthy, API keys detected
2. **Worker Logs**: ✅ Workers starting successfully with provider info
3. **Job Processing**: ✅ Jobs moving from pending → processing → completed
4. **Database**: ✅ QuestionItem records being created
5. **Progress Stream**: ✅ Real-time updates with >0 subscribers
6. **Final Result**: ✅ Generated questions returned in API response

If you're still seeing 0 questions after following this guide, the issue is likely in the LLM provider configuration or network connectivity to the AI APIs.

---

## Quick Diagnosis Commands

Run these commands to get immediate feedback on system status:

```bash
# System health
curl -s http://localhost:3000/api/v2/question-generator/health | jq '.environment'

# Worker status  
curl -s http://localhost:3000/api/v2/question-generator/workers/status | jq '.workers'

# Queue stats
curl -s http://localhost:3000/api/v2/question-generator/queue/stats | jq '.queues'

# Recent questions count
psql -d your_db -c "SELECT COUNT(*) as question_count FROM \"QuestionItem\" WHERE \"createdAt\" > NOW() - INTERVAL '1 hour';"

# Recent failed jobs
psql -d your_db -c "SELECT id, \"errorMessage\" FROM \"GenerationJob\" WHERE status = 'failed' ORDER BY \"createdAt\" DESC LIMIT 5;"
```

This should help you identify exactly where the question generation process is failing!