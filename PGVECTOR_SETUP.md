# pgvector Setup Guide

This guide will help you enable and configure pgvector for the semantic memory system.

---

## 🔧 Quick Setup

### Step 1: Enable pgvector Extension

Connect to your PostgreSQL database and run:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Verify installation:

```sql
SELECT * FROM pg_extension WHERE extname = 'vector';
```

Expected output:
```
 extname | extowner | extnamespace | extrelocatable | extversion 
---------+----------+--------------+----------------+------------
 vector  |    10    |         2200 | t              | 0.5.0
```

---

### Step 2: Verify Schema

Check that the `ConversationMemory` table has the embedding column:

```sql
\d "ConversationMemory"
```

Look for:
```
embedding | real[] | default '{}'::real[]
```

Or if using vector type:
```
embedding | vector(1536) |
```

---

### Step 3: Create Performance Index

**Option A: HNSW Index (Recommended)**

Best for high-dimensional vectors and fast queries:

```sql
CREATE INDEX IF NOT EXISTS conversation_memory_embedding_hnsw_idx 
ON "ConversationMemory" 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

**Option B: IVFFlat Index (Alternative)**

Good for medium-sized datasets:

```sql
CREATE INDEX IF NOT EXISTS conversation_memory_embedding_ivfflat_idx 
ON "ConversationMemory" 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

**Parameters explained:**
- `m = 16`: Number of connections per layer (higher = better recall, slower build)
- `ef_construction = 64`: Size of dynamic candidate list (higher = better quality, slower build)
- `lists = 100`: Number of inverted lists (rule of thumb: rows / 1000)

---

### Step 4: Test the Setup

Run a test query:

```sql
-- Test cosine similarity
SELECT 
  "conversationId",
  summary,
  1 - (embedding <=> ARRAY[0.1, 0.2, 0.3]::vector) as similarity
FROM "ConversationMemory"
WHERE array_length(embedding, 1) > 0
ORDER BY embedding <=> ARRAY[0.1, 0.2, 0.3]::vector
LIMIT 5;
```

If this works, pgvector is properly configured! ✅

---

## 📊 Performance Tuning

### Adjust HNSW Parameters Based on Data Size

| Data Size | m | ef_construction | ef_search |
|-----------|---|-----------------|-----------|
| < 10,000 | 16 | 64 | 40 |
| 10,000 - 100,000 | 16 | 128 | 64 |
| 100,000 - 1M | 24 | 200 | 100 |
| > 1M | 32 | 400 | 200 |

To set `ef_search` at runtime:

```sql
SET hnsw.ef_search = 100;
```

---

## 🔍 Monitoring & Maintenance

### Check Index Usage

```sql
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE indexname LIKE '%embedding%';
```

### Rebuild Index (If Needed)

```sql
REINDEX INDEX CONCURRENTLY conversation_memory_embedding_hnsw_idx;
```

### Check Index Size

```sql
SELECT 
  pg_size_pretty(pg_relation_size('conversation_memory_embedding_hnsw_idx')) as index_size;
```

---

## ⚙️ Environment Variables

Make sure these are set in your `.env`:

```env
# Required for embeddings
OPENAI_API_KEY=sk-...

# Database connection (should already be configured)
DATABASE_URL=postgresql://user:password@host:port/database
```

---

## 🧪 Testing Semantic Search

### 1. Create Test Data

```typescript
// Run this in your API
const memoryService = new ConversationMemoryService();

await memoryService.saveSummaryWithEmbedding(
  'test_session_1',
  [
    { type: 'user', content: 'Create 4 math questions about addition' },
    { type: 'assistant', content: 'I\'ll create... [Generated 4 questions]' }
  ],
  'test_conv_1'
);

await memoryService.saveSummaryWithEmbedding(
  'test_session_2',
  [
    { type: 'user', content: 'Create 5 science questions about biology' },
    { type: 'assistant', content: 'I\'ll create... [Generated 5 questions]' }
  ],
  'test_conv_2'
);
```

### 2. Test Semantic Search

```typescript
const results = await memoryService.semanticSearch(
  'create math quiz',
  'system',
  3
);

console.log(results);
// Should find the math conversation with high similarity
```

### 3. Test in Chat Endpoint

```bash
curl -X POST http://localhost:3000/api/v2/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "create another math quiz",
    "context": {
      "sessionId": "new_session",
      "enableMemory": true
    }
  }'
```

Look for in logs:
```
[AI Chat] Retrieved 1 semantically relevant memories
```

---

## ❌ Troubleshooting

### Error: "extension vector does not exist"

**Solution:**
```sql
-- Check if pgvector is installed
SELECT * FROM pg_available_extensions WHERE name = 'vector';

-- If not available, install it (requires superuser)
-- On Ubuntu/Debian:
sudo apt-get install postgresql-14-pgvector

-- On Mac with Homebrew:
brew install pgvector
```

### Error: "operator does not exist: real[] <=> vector"

**Solution:** The embedding column type doesn't match. Fix schema:

```sql
-- Change column type
ALTER TABLE "ConversationMemory" 
ALTER COLUMN embedding TYPE vector(1536) 
USING embedding::vector(1536);
```

### Error: "array_length is null"

**Solution:** Some records have empty embeddings. Filter them:

```sql
-- Update query to handle NULL
WHERE embedding IS NOT NULL AND array_length(embedding, 1) > 0
```

### Slow Queries Without Index

**Solution:** Create the HNSW index (see Step 3 above)

### High Memory Usage

**Solution:** Adjust PostgreSQL settings:

```sql
-- In postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
```

---

## 📈 Migration Strategy

If you have existing `ConversationMemory` records without embeddings:

### Backfill Embeddings

```typescript
// Create a migration script
import ConversationMemoryService from './services/conversation-memory.service';
import { PrismaClient } from '@prisma/client';

async function backfillEmbeddings() {
  const prisma = new PrismaClient();
  const memoryService = new ConversationMemoryService(prisma);
  
  // Get all conversations without embeddings
  const conversations = await prisma.conversationMemory.findMany({
    where: {
      OR: [
        { embedding: { equals: [] } },
        { embedding: null }
      ]
    }
  });
  
  console.log(`Found ${conversations.length} conversations to backfill`);
  
  for (const conv of conversations) {
    try {
      // Generate embedding from summary and key points
      const text = `${conv.summary} ${(conv.keyPoints as string[]).join(' ')}`;
      const embedding = await memoryService.generateEmbedding(text);
      
      if (embedding.length > 0) {
        await prisma.conversationMemory.update({
          where: { id: conv.id },
          data: { embedding }
        });
        
        console.log(`✅ Backfilled embedding for ${conv.conversationId}`);
      }
      
      // Rate limit: 3 requests per second
      await new Promise(resolve => setTimeout(resolve, 350));
    } catch (error) {
      console.error(`❌ Failed to backfill ${conv.conversationId}:`, error);
    }
  }
  
  console.log('Backfill complete!');
}

backfillEmbeddings();
```

Run with:
```bash
npx ts-node scripts/backfill-embeddings.ts
```

---

## 🔐 Security Notes

### API Key Protection

Never commit `OPENAI_API_KEY` to git:

```bash
# Add to .gitignore
.env
.env.local
.env.production
```

### Rate Limiting

OpenAI has rate limits:
- **Free tier:** 3 requests/minute
- **Paid tier:** 3,000 requests/minute

Implement rate limiting in production:

```typescript
import rateLimit from 'express-rate-limit';

const embeddingLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100 // 100 requests per minute
});

app.use('/api/v2/ai/chat', embeddingLimiter);
```

---

## 📊 Cost Monitoring

### Track Embedding Costs

Add to your monitoring:

```typescript
let embeddingTokensUsed = 0;

async function generateEmbedding(text: string) {
  const tokens = estimateTokens(text); // ~text.length / 4
  embeddingTokensUsed += tokens;
  
  // Log weekly
  if (embeddingTokensUsed > 1000000) {
    logger.info(`Embedding cost this week: $${embeddingTokensUsed / 1000000 * 0.02}`);
    embeddingTokensUsed = 0;
  }
  
  // ... generate embedding
}
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `vector` extension enabled
- [ ] `ConversationMemory` table has `embedding` column
- [ ] HNSW or IVFFlat index created
- [ ] `OPENAI_API_KEY` configured
- [ ] Test query returns results
- [ ] Semantic search works in chat endpoint
- [ ] Logs show "Retrieved X semantically relevant memories"
- [ ] Embedding costs are acceptable

---

## 🚀 You're Ready!

Once all checks pass, the semantic memory system is fully operational.

**Next steps:**
1. Test with real user conversations
2. Monitor performance and costs
3. Tune similarity threshold based on results
4. Consider backfilling existing conversations

---

**Questions?** Check the detailed documentation in `docs/ai-chat-system/PHASE_3_PGVECTOR_IMPLEMENTATION.md`
