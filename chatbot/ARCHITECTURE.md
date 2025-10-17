# 🏗️ Architecture Overview

> Simplified architecture guide for developers

---

## System Layers

```
┌─────────────────────────────────────────┐
│  FRONTEND (React/Next.js)               │
│  - AIAssistantChatEnhanced              │
│  - AIStreamingHandler                   │
│  - useAIToolCalls                       │
└─────────────┬───────────────────────────┘
              │ HTTP/SSE
              ▼
┌─────────────────────────────────────────┐
│  API ROUTES (Next.js)                   │
│  - /api/v2/ai/chat                      │
│  - /api/v2/question-generator/*         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  SERVICES                               │
│  - Context Builder (3-layer memory)     │
│  - Document Ingestion (parallel)        │
│  - Memory Management (pgvector)         │
│  - Vector Indexing (embeddings)         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  DATABASE                               │
│  - PostgreSQL + pgvector                │
│  - Multi-tenant schemas                 │
│  - HNSW indexes                         │
└─────────────────────────────────────────┘
```

---

## Key Design Patterns

### 1. Server-Sent Events (SSE)

**Why:** Real-time streaming without WebSocket complexity

```typescript
// Backend sends
res.write(`data: ${JSON.stringify({ type: 'content', content: 'chunk' })}\n\n`);

// Frontend receives
const reader = response.body.getReader();
// Parse and display in real-time
```

### 2. Tool Calling

**Flow:** LLM decides → Backend streams → Frontend executes → Continue

```typescript
// LLM calls tool
{ type: 'tool_call', name: 'previewQuestions', args: {...} }

// Frontend executes
const questions = convertQuestions(args);
showInUI(questions);

// Send results back for continuation
await fetch('/api/v2/ai/chat', {
  body: JSON.stringify({ toolResults: [...] })
});
```

### 3. Three-Layer Memory

**Immediate Context** (in-memory)
- Current conversation
- Active documents

**Long-term Context** (pgvector)
- Semantic search past conversations
- Related documents

**Synthesized Summary** (LLM-generated)
- AI creates context summary
- Cached in Redis

### 4. Background Processing

**Critical:** Preserve tenant context!

```typescript
// ✅ Capture headers BEFORE async
const headers = { 'x-tenant-tag': req.headers['x-tenant-tag'] };

setImmediate(async () => {
  const bgReq = { headers };
  await process({ req: bgReq });
});
```

---

## Performance Optimizations

### Async Upload (98% faster)
```
Before: Upload → Extract → Chunk → Index → Return (90s)
After:  Upload → Extract → Return (2s) + Background processing
```

### Parallel PDF (75% faster)
```
Before: Page 1 (40s) → Page 2 (40s) → ... (sequential)
After:  Batch [1-6] (40s) → Batch [7-12] (40s) (parallel)
```

### Smart Context (70% smaller)
```
Before: Load full document (50KB)
After:  Load relevant chunks (15KB)
```

---

## Multi-tenant Architecture

**Tenant Identification:**
1. JWT in x-tenant-tag header
2. LRU cache (1ms lookup)
3. Redis fallback (10ms)
4. DB lookup (50ms)

**Schema Isolation:**
```sql
-- Each tenant gets dedicated schema
CREATE SCHEMA "tenant_abc123";

-- Prisma connects to correct schema
?schema=tenant_abc123
```

---

## Data Flow Examples

### Chat Message Flow
```
User message
  → Frontend (AIAssistantChatEnhanced)
  → SSE connection (AIStreamingHandler)
  → Backend (/api/v2/ai/chat)
  → Context Builder (3 layers)
  → LLM (DeepSeek/OpenAI)
  → Stream response (SSE)
  → Frontend displays (real-time)
```

### Document Upload Flow
```
File upload
  → Validation
  → Text extraction (2s)
  → Return to user ✅
  
Background (non-blocking):
  → Chunking (12s)
  → Embedding generation (35s)
  → Vector indexing (HNSW)
  → Memory storage (3s)
```

### Tool Call Flow
```
User: "Create 5 questions"
  → LLM detects intent
  → Calls previewQuestions tool
  → Streams partial questions (isPartial: true)
  → Frontend shows live preview
  → Complete questions (isPartial: false)
  → Send tool results back
  → LLM continues with summary
```

---

## Key Services

### ContextBuilderService
```typescript
buildContext({
  query,
  previousMessages,
  attachments,
  enableMemory: true
}) → {
  immediateContext,    // Recent msgs, docs
  longTermContext,     // Semantic memories
  synthesizedSummary   // AI summary
}
```

### DocumentIngestionService
```typescript
ingestDocument(file, userId, options) → {
  documentId,
  extractedText,
  fingerprintExists
}
```

### MemoryManagementService
```typescript
retrieveRelevantMemories(query, options) → Memory[]
// Uses pgvector cosine similarity
```

### VectorIndexingService
```typescript
indexDocument(documentId, options) → {
  success,
  indexedChunks
}
```

---

## Database Schema (Simplified)

```sql
-- Documents
DocumentIndex {
  id, filename, extracted_text, fingerprint
}

-- Chunks for vector search
DocumentChunk {
  id, document_id, content, embedding vector(1536)
}

-- Conversation memory
ConversationMemory {
  id, summary, embedding vector(1536), metadata
}

-- Indexes
CREATE INDEX embedding_hnsw_idx 
USING hnsw (embedding vector_cosine_ops);
```

---

## Security

- JWT authentication
- Tenant isolation (schemas)
- API key validation
- CORS policies
- Rate limiting (planned)

---

## Monitoring

**Key Metrics:**
- Upload time (target: <5s)
- Chat response time (target: <8s)
- Memory retrieval time (target: <1s)
- Error rate (target: <0.1%)

**Logs:**
```
[Background] Processing for <id>
[Memory] Retrieved X memories (similarity > 0.7)
[PDF] ⚡ Processing X pages with Y concurrent workers
```

---

## Further Reading

- **Complete docs:** [README.md](./README.md)
- **Setup guide:** [QUICK_START.md](./QUICK_START.md)
- **API reference:** In README.md
- **Executive summary:** [SUMMARY.md](./SUMMARY.md)

---

**For detailed architecture, see full README.md documentation.**
