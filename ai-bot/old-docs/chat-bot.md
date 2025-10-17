# Question Generator – System Documentation (Repo Wiki)

Last updated: 2025-09-15

## Executive Summary

The Question Generator is an end-to-end document-to-questions pipeline built on a scalable, retrieval-driven batch architecture. It ingests documents, semantically chunks them, indexes chunks with embeddings, produces a structured generation plan via LLM, orchestrates parallel generation jobs across a worker pool, validates and deduplicates results, and streams real-time progress back to the UI.

Key characteristics:
- Robust multi-tenant architecture with tenant-aware Prisma clients
- Cost-optimized model tiering (DeepSeek for drafting, OpenAI for validation)
- BullMQ-backed job orchestration and queue management (Redis)
- Server-Sent Events (SSE) and WebSocket for progress streaming
- Quality control via validation and deduplication services
- Fully typed interfaces and Prisma schema modeling

Primary entry points:
- Frontend client: `frontend/src/services/question-generator-client.service.ts`
- API endpoints: `api/src/pages/api/v2/question-generator/*`
- Core services: `api/src/services/*`
- Prisma schema: `api/prisma/schema/question-generator.prisma`

## High-level Architecture

```mermaid
graph TB
    subgraph "Frontend"
        UI[AIAssistantChatEnhanced.tsx]
        QGCS[QuestionGeneratorClientService.ts]
    end

    subgraph "API Gateway (Next.js)"
        UP[POST /upload-document]
        PLAN[POST /create-plan]
        START[POST /start-generation]
        STATUS[GET /status/:planId]
        PLAN_D[GET /plan/:planId]
        PLAN_Q[GET /plan/:planId/questions]
        STREAM[GET /stream/progress/:planId]
        S_STATS[GET /stream/stats]
        QUEUE[GET/POST /queue]
        WORKERS[GET/POST /workers]
        DEDUP[POST/DELETE /deduplicate/:planId]
        HEALTH[GET /health]
    end

    subgraph "Core Services"
        ING[DocumentIngestionService]
        CHK[DocumentChunkingService]
        VEC[VectorIndexingService]
        PLN[QuestionPlanningService]
        ORC[QuestionGenerationOrchestrator]
        QM[QuestionGenerationQueueManager]
        WPM[QuestionGenerationWorkerPool]
        VAL[QuestionValidationService]
        DUP[QuestionDeduplicationService]
        STR[StreamingProgressService]
        EMIT[ProgressEmissionUtil]
    end

    subgraph "Infra"
        REDIS[(Redis)]
        PG[(PostgreSQL)]
        PGV[(pgvector)]
    end

    %% Frontend to API
    UI --> QGCS
    QGCS --> UP
    QGCS --> PLAN
    QGCS --> START
    QGCS --> STATUS
    QGCS --> PLAN_Q
    QGCS --> STREAM
    QGCS --> HEALTH

    %% API to Services
    UP --> ING
    ING --> CHK
    CHK --> VEC
    VEC --> PGV

    PLAN --> PLN
    PLN --> PG

    START --> ORC
    ORC --> QM
    QM --> REDIS
    QM --> STR

    %% Workers
    REDIS --> WPM
    WPM --> VEC
    WPM --> PG
    WPM --> STR

    %% QA
    WPM --> VAL
    VAL --> PG
    WPM --> DUP
    DUP --> PG

    %% Observability
    EMIT --> STR
    STR --> STREAM
```

References:
- `frontend/src/services/question-generator-client.service.ts`
- API routes in `api/src/pages/api/v2/question-generator/`
- Services in `api/src/services/`
- Types in `api/src/types/question-generator.types.ts`

## Data Model and Schemas

Core Prisma models (excerpt) in `api/prisma/schema/question-generator.prisma`:
- `DocumentIndex`, `DocumentChunk` (document lifecycle and semantic chunks)
- `QuestionPlan` (planned distribution of question types, constraints, metadata)
- `GenerationJob`, `QuestionGenerationTask` (batched job orchestration)
- `QuestionItem`, `QuestionCitation` (final generated questions with citations)
- `ProcessingProgress` (progress events for SSE/WebSocket replay)
- `EmbeddingCache`, `QuestionGeneratorConfig` (cost optimization and runtime config)

Entity-relationship overview:

```mermaid
erDiagram
    DocumentIndex ||--o{ DocumentChunk : contains
    DocumentIndex ||--o{ QuestionPlan : generates
    QuestionPlan ||--o{ GenerationJob : executes
    GenerationJob ||--o{ QuestionGenerationTask : contains
    QuestionPlan ||--o{ QuestionItem : produces
    QuestionItem ||--o{ QuestionCitation : cites
    DocumentChunk ||--o{ QuestionCitation : references
    QuestionPlan ||--o{ ProcessingProgress : tracks
    
    DocumentIndex {
        string id PK
        string tenantId
        string filename
        string mimeType
        string contentFingerprint
        string status
        string error
        json metadata
        datetime createdAt
        datetime updatedAt
    }
    
    QuestionPlan {
        string id PK
        string documentIndexId FK
        string status
        json questionTypes
        json constraints
        json metadata
        datetime createdAt
        datetime updatedAt
    }
    
    QuestionItem {
        string id PK
        string planId FK
        string type
        string status
        text questionText
        text answerText
        json metadata
        datetime createdAt
        datetime updatedAt
    }
```

## Core Services

### 1. Document Ingestion Service (`DocumentIngestionService`)
- **Purpose**: Handles file uploads, text extraction, and preprocessing
- **Key Features**:
  - Multi-format support (PDF, DOCX, PPTX, TXT, Markdown)
  - OCR fallback for image-based PDFs
  - Content fingerprinting for deduplication
  - Tenant-aware storage with proper isolation
- **Dependencies**: `multer`, `pdf-parse`, `mammoth`, `textract`
- **Configuration**:
  ```env
  UPLOAD_DIR=./uploads
  MAX_FILE_SIZE=10485760  # 10MB
  ALLOWED_MIME_TYPES=application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ```

### 2. Document Chunking Service (`DocumentChunkingService`)
- **Purpose**: Splits documents into semantically meaningful chunks
- **Key Features**:
  - Semantic chunking with structure preservation
  - Context window optimization for LLM processing
  - Hierarchical chunking (section > paragraph > sentence)
  - Metadata preservation (headings, lists, tables)
- **Configuration**:
  ```typescript
  {
    chunkSize: 1000,           // Target chunk size in tokens
    chunkOverlap: 200,         // Overlap between chunks
    maxChunkLength: 1500,      // Absolute max chunk size
    minChunkLength: 200,       // Minimum chunk size before merging
    paragraphSeparator: '\n\n',
    sectionDelimiters: ['## ', '### ', '#### '],
    tableHandling: 'extract'   // 'extract'|'preserve'|'ignore'
  }
  ```

### 3. Vector Indexing Service (`VectorIndexingService`)
- **Purpose**: Manages document embeddings and semantic search
- **Key Features**:
  - OpenAI/DeepSeek embedding generation with caching
  - pgvector integration for efficient similarity search
  - Batch processing for large document collections
  - Tenant-specific namespacing
- **Dependencies**: `pgvector`, `openai`, `@deepseek/deepseek-ai`
- **Configuration**:
  ```env
  EMBEDDING_MODEL=text-embedding-3-small
  EMBEDDING_DIMENSIONS=1536
  VECTOR_CACHE_TTL=86400  # 24h
  BATCH_SIZE=32
  ```

### 4. Question Planning Service (`QuestionPlanningService`)
- **Purpose**: Generates a structured plan for question generation
- **Key Features**:
  - Analyzes document structure and content
  - Determines optimal question distribution
  - Respects constraints (difficulty, question types, etc.)
  - Estimates token usage and cost
- **LLM Prompt Template**:
  ```
  Analyze the following document and create a question generation plan:
  
  Document: [Document title and metadata]
  Content: [First 2000 chars for context]
  
  Constraints:
  - Total questions: 20
  - Question types: multiple_choice, short_answer, true_false
  - Difficulty: medium
  - Topics: [extracted from document]
  
  Output a JSON array of question specifications with type, count, and focus areas.
  ```

### 5. Question Generation Orchestrator (`QuestionGenerationOrchestrator`)
- **Purpose**: Coordinates the end-to-end question generation process
- **Key Features**:
  - Job decomposition and batching
  - Progress tracking and event emission
  - Error handling and retry logic
  - Resource management
- **Key Methods**:
  ```typescript
  async startGeneration(planId: string, options: GenerationOptions): Promise<void>
  async getStatus(planId: string): Promise<GenerationStatus>
  async cancelGeneration(planId: string): Promise<void>
  async getQuestions(planId: string, options: QuestionQueryOptions): Promise<QuestionItem[]>
  ```

### 6. Question Generation Queue Manager (`QuestionGenerationQueueManager`)
- **Purpose**: Manages the BullMQ queues for distributed processing
- **Key Features**:
  - Priority-based job scheduling
  - Rate limiting and concurrency control
  - Dead letter queue for failed jobs
  - Progress event forwarding
- **Queues**:
  - `question-generation`: Main processing queue
  - `question-validation`: Validation and scoring
  - `question-deduplication`: Duplicate detection

### 7. Worker Pool (`QuestionGenerationWorkerPool`)
- **Purpose**: Executes question generation tasks
- **Key Features**:
  - Dynamic worker allocation
  - Model tiering (DeepSeek draft, OpenAI validation)
  - Context retrieval via vector search
  - Structured output parsing
- **Worker Configuration**:
  ```typescript
  {
    concurrency: 3,
    lockDuration: 300000,  // 5m
    lockRenewTime: 60000,  // 1m
    stalledInterval: 30000, // 30s
    maxStalledCount: 2,
    retryProcessDelay: 5000,
    settings: {
      guardInterval: 1000,
      drainDelay: 300
    }
  }
  ```

### 8. Question Validation Service (`QuestionValidationService`)
- **Purpose**: Validates and scores generated questions
- **Validation Criteria**:
  - Grammatical correctness
  - Clarity and specificity
  - Answerability from context
  - Difficulty consistency
  - Absence of bias/sensitivity issues
- **Scoring**:
  - 1-5 scale across multiple dimensions
  - Minimum thresholds for acceptance
  - Automated feedback for improvement

### 9. Question Deduplication Service (`QuestionDeduplicationService`)
- **Purpose**: Identifies and removes duplicate/similar questions
- **Algorithms**:
  - Exact matching (normalized text)
  - Semantic similarity (embedding cosine distance)
  - Structural analysis (AST comparison for code questions)
- **Configuration**:
  ```typescript
  {
    similarityThreshold: 0.85,  // 0-1, higher is more strict
    minQuestionLength: 10,     // Skip very short questions
    batchSize: 50,             // Process N questions at once
    crossTypeCheck: false,     // Check across question types
    useSemanticDedup: true,    // Use embeddings for fuzzy matching
    semanticThreshold: 0.92    // Threshold for semantic similarity
  }
  ```

### 10. Streaming Progress Service (`StreamingProgressService`)
- **Purpose**: Manages real-time progress updates
- **Features**:
  - SSE and WebSocket support
  - Event buffering and replay
  - Connection management
  - Heartbeat mechanism
- **Event Types**:
  - `progress`: Generation progress update
  - `status`: System status change
  - `warning`: Non-fatal issues
  - `error`: Processing errors
  - `complete`: Job completion

## API Reference

### 1. Document Upload
```http
POST /api/v2/question-generator/upload-document
Content-Type: multipart/form-data
x-tenant-tag: tenant-123
x-request-id: req-abc123

{
  "file": [binary data],
  "options": {
    "chunkSize": 1000,
    "extractImages": true,
    "language": "en"
  }
}
```

### 2. Create Question Plan
```http
POST /api/v2/question-generator/create-plan
Content-Type: application/json
x-tenant-tag: tenant-123

{
  "documentId": "doc_abc123",
  "options": {
    "questionTypes": ["multiple_choice", "short_answer"],
    "difficulty": "medium",
    "count": 20,
    "constraints": {
      "maxOptionsPerQuestion": 4,
      "requireCitations": true
    }
  }
}
```

### 3. Start Generation
```http
POST /api/v2/question-generator/start-generation
Content-Type: application/json
x-tenant-tag: tenant-123

{
  "planId": "plan_abc123",
  "options": {
    "batchSize": 5,
    "priority": "normal",
    "notifyUrl": "https://webhook.example.com/events"
  }
}
```

### 4. Get Generation Status
```http
GET /api/v2/question-generator/status/plan_abc123
x-tenant-tag: tenant-123
```

### 5. Stream Progress (SSE)
```http
GET /api/v2/question-generator/stream/progress/plan_abc123
Accept: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
x-tenant-tag: tenant-123
```

### 6. Get Generated Questions
```http
GET /api/v2/question-generator/plan/plan_abc123/questions?status=validated&limit=50
x-tenant-tag: tenant-123
```

### 7. Worker Management
```http
POST /api/v2/question-generator/workers
Content-Type: application/json

{
  "action": "restart",
  "max_age_hours": 24
}
```

### 8. Deduplicate Questions
```http
POST /api/v2/question-generator/deduplicate/plan_abc123
Content-Type: application/json
x-tenant-tag: tenant-123

{
  "similarityThreshold": 0.85,
  "includeCrossType": false,
  "semanticAnalysis": true
}
```

## Frontend Integration

### React Hook Example
```typescript
import { useQuestionGenerator } from '@/hooks/useQuestionGenerator';

function DocumentQuestions({ documentId }) {
  const {
    status,
    progress,
    questions,
    error,
    startGeneration,
    cancelGeneration,
    refreshStatus
  } = useQuestionGenerator({
    documentId,
    autoRefresh: true,
    refreshInterval: 5000
  });

  // ... render UI based on status/progress
}
```

### Event Handling
```typescript
const client = new QuestionGeneratorClient({
  baseUrl: '/api/v2/question-generator',
  onProgress: (event) => {
    switch (event.type) {
      case 'progress':
        updateProgress(event.data);
        break;
      case 'status':
        updateStatus(event.data);
        break;
      case 'error':
        showError(event.error);
        break;
    }
  },
  onComplete: (result) => {
    showCompletion(result);
  }
});
```

## Deployment & Configuration

### Environment Variables
```env
# Required
DATABASE_URL=postgresql://user:pass@localhost:5432/qg_prod?schema=public
REDIS_URL=redis://localhost:6379
DEEPSEEK_API_KEY=sk-xxx
OPENAI_API_KEY=sk-yyy
UPLOAD_DIR=./uploads

# Optional
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
MAX_CONCURRENT_JOBS=10
JOB_TIMEOUT_MS=300000
EMBEDDING_MODEL=text-embedding-3-small
```

### Docker Compose
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/qg_prod
      - REDIS_URL=redis://redis:6379
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  postgres:
    image: ankane/pgvector:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: qg_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

## Monitoring & Observability

### Key Metrics
- **Document Processing**:
  - `documents_processed_total`
  - `document_processing_duration_seconds`
  - `document_chunks_created_total`
  
- **Question Generation**:
  - `questions_generated_total`
  - `question_generation_duration_seconds`
  - `questions_validated_total`
  - `questions_rejected_total`
  
- **Queue Metrics**:
  - `queue_jobs_waiting`
  - `queue_jobs_active`
  - `queue_jobs_completed`
  - `queue_jobs_failed`
  - `queue_processing_duration_seconds`

### Logging
Structured JSON logs with correlation IDs:
```json
{
  "level": "info",
  "time": "2025-09-15T12:00:00Z",
  "requestId": "req-abc123",
  "planId": "plan_abc123",
  "tenantId": "tenant-123",
  "message": "Started question generation",
  "jobId": "job_abc123",
  "metrics": {
    "chunkCount": 42,
    "estimatedQuestions": 25,
    "model": "deepseek"
  }
}
```

## Performance Considerations

### Caching Strategy
- **Embedding Cache**:
  - Redis cache for frequently accessed embeddings
  - 24-hour TTL with LRU eviction
  - Key format: `embedding:${model}:${textHash}`

- **Question Cache**:
  - In-memory cache for validated questions
  - 1-hour TTL or until invalidation
  - Keyed by plan ID and filter criteria

### Scaling
- **Horizontal Scaling**:
  - Stateless API servers behind load balancer
  - Worker pool auto-scaling based on queue depth
  - Database read replicas for high-traffic deployments

- **Resource Limits**:
  ```typescript
  // Per-tenant rate limiting
  const rateLimiter = new RateLimiter({
    tokensPerInterval: 100,  // 100 requests
    interval: 'minute',
    fireImmediately: true
  });
  
  // Per-document size limits
  const MAX_DOCUMENT_SIZE = 50 * 1024 * 1024; // 50MB
  const MAX_PAGES = 500;
  ```

## Security Considerations

### Authentication & Authorization
- JWT-based authentication with tenant context
- Role-based access control (RBAC)
- API key rotation for LLM providers

### Data Protection
- Encryption at rest for document storage
- TLS for all external communications
- Input validation and sanitization
- Rate limiting and DDoS protection

### Compliance
- GDPR/CCPA data subject requests
- Audit logging for all operations
- Data retention policies

## Troubleshooting

### Common Issues
1. **Upload Failures**:
   - Check file size and type restrictions
   - Verify storage permissions
   - Review extraction logs for format-specific issues

2. **Generation Stalls**:
   - Check worker logs for errors
   - Verify Redis connection and queue status
   - Monitor API key rate limits

3. **Poor Quality Questions**:
   - Review document chunking strategy
   - Adjust validation thresholds
   - Check model temperature and prompt templates

### Debugging Tools
```bash
# Check queue status
curl -X GET "$API_URL/api/v2/question-generator/queue"

# Get worker status
curl -X GET "$API_URL/api/v2/question-generator/workers"

# Check system health
curl -X GET "$API_URL/api/v2/question-generator/health"
```

## Future Enhancements

### Short-term
- [ ] Support for more document formats (ePub, ODF)
- [ ] Multi-language question generation
- [ ] Interactive question refinement

### Medium-term
- [ ] Question difficulty calibration
- [ ] Automated test generation from questions
- [ ] Integration with LMS platforms

### Long-term
- [ ] Adaptive learning paths
- [ ] Question personalization
- [ ] Voice-based question answering

## Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `npm install`
3. Set up environment variables (copy `.env.example` to `.env`)
4. Run migrations: `npx prisma migrate dev`
5. Start dev server: `npm run dev`

### Testing
```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e
```

### Code Style
- TypeScript strict mode
- ESLint + Prettier
- Conventional commits
- PR template with checklist

## License

[Your License Here]

---

*Documentation generated on 2025-09-15*
