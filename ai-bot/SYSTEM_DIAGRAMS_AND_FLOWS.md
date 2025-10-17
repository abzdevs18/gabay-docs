# Gabay AI Chat System - Diagrams & Flow Charts

> **Version:** 3.0.0 | **Last Updated:** 2025-01-30

## 📊 System Architecture Diagrams

### 1. Complete System Architecture

```mermaid
graph TB
    subgraph "Frontend Layer"
        UI[React Application]
        CHAT[AI Chat Component]
        PREVIEW[Artifact Preview]
        PROMPT[Input Field]
    end
    
    subgraph "API Gateway"
        GATEWAY[Next.js API Routes]
        AUTH[Authentication]
        TENANT[Tenant Context]
        MIDDLEWARE[Rate Limiting]
    end
    
    subgraph "AI Services"
        CHAT_SVC[Chat Service]
        TOOLS[Tool System]
        DOC_SVC[Document Service]
        IMG_SVC[Image Service]
    end
    
    subgraph "Processing Pipeline"
        INGEST[Document Ingestion]
        CHUNK[Semantic Chunking]
        VECTOR[Vector Indexing]
        PLAN[Question Planning]
        QUEUE[Job Queue]
        WORKER[Worker Pool]
    end
    
    subgraph "AI Providers"
        OPENAI[OpenAI API<br/>GPT-4, Vision]
        DEEPSEEK[DeepSeek API<br/>Cost-effective]
    end
    
    subgraph "Data Storage"
        PG[(PostgreSQL<br/>Primary DB)]
        PGVEC[(pgvector<br/>Embeddings)]
        REDIS[(Redis<br/>Cache + Queue)]
        FS[(File System<br/>Documents)]
    end
    
    subgraph "Streaming"
        SSE[Server-Sent Events]
        WS[WebSocket]
    end
    
    UI --> CHAT --> PROMPT
    CHAT --> PREVIEW
    CHAT --> GATEWAY
    
    GATEWAY --> AUTH --> TENANT
    GATEWAY --> MIDDLEWARE
    GATEWAY --> CHAT_SVC
    GATEWAY --> DOC_SVC
    
    CHAT_SVC --> TOOLS
    CHAT_SVC --> OPENAI
    CHAT_SVC --> DEEPSEEK
    
    DOC_SVC --> INGEST
    INGEST --> IMG_SVC
    IMG_SVC --> OPENAI
    INGEST --> CHUNK
    CHUNK --> VECTOR
    VECTOR --> PLAN
    PLAN --> QUEUE
    QUEUE --> WORKER
    
    WORKER --> OPENAI
    WORKER --> DEEPSEEK
    
    INGEST --> FS
    CHUNK --> PGVEC
    VECTOR --> PGVEC
    PLAN --> PG
    WORKER --> PG
    QUEUE --> REDIS
    
    CHAT_SVC --> SSE
    WORKER --> SSE
    CHAT_SVC --> WS
    
    SSE --> UI
    WS --> UI
```

### 2. Frontend Component Architecture

```mermaid
graph LR
    subgraph "Main Chat Component"
        MAIN[AIAssistantChatEnhanced]
    end
    
    subgraph "Input Components"
        PROMPT[AIPromptField]
        ATTACH[Attachment Handler]
        UPLOAD[File Upload]
    end
    
    subgraph "Display Components"
        MESSAGES[Message List]
        BUBBLE[Message Bubble]
        PREVIEW[Preview Panel]
        ARTIFACT[QuestionPreviewArtifact]
    end
    
    subgraph "State Management"
        STATE[Chat State]
        QUESTIONS[Generated Questions]
        ATTACHMENTS[Attachments State]
    end
    
    subgraph "Hooks & Utils"
        TOOL_HOOK[useAIToolCalls]
        STREAM[AIStreamingHandler]
        API[API Client]
    end
    
    MAIN --> PROMPT
    MAIN --> MESSAGES
    MAIN --> PREVIEW
    
    PROMPT --> ATTACH
    ATTACH --> UPLOAD
    
    MESSAGES --> BUBBLE
    PREVIEW --> ARTIFACT
    
    MAIN --> STATE
    STATE --> QUESTIONS
    STATE --> ATTACHMENTS
    
    MAIN --> TOOL_HOOK
    MAIN --> STREAM
    STREAM --> API
```

### 3. Backend Service Architecture

```mermaid
graph TB
    subgraph "API Endpoints"
        CHAT_API[/api/v2/ai/chat]
        UPLOAD_API[/api/v2/question-generator/upload-document]
        PLAN_API[/api/v2/question-generator/create-plan]
        GEN_API[/api/v2/question-generator/start-generation]
        STATUS_API[/api/v2/question-generator/status/[planId]]
    end
    
    subgraph "Core Services"
        INGEST[DocumentIngestionService]
        CHUNK[DocumentChunkingService]
        VECTOR[VectorIndexingService]
        PLANNING[QuestionPlanningService]
        ORCHESTRATOR[OrchestrationService]
        QUEUE_MGR[QueueManagerService]
        WORKER_POOL[WorkerPoolService]
        VALIDATION[ValidationService]
    end
    
    subgraph "External Services"
        OPENAI_SVC[OpenAI Service]
        DEEPSEEK_SVC[DeepSeek Service]
        VISION_SVC[Vision Service]
        OCR_SVC[OCR Service]
    end
    
    CHAT_API --> OPENAI_SVC
    CHAT_API --> DEEPSEEK_SVC
    
    UPLOAD_API --> INGEST
    INGEST --> VISION_SVC
    INGEST --> OCR_SVC
    INGEST --> CHUNK
    
    CHUNK --> VECTOR
    VECTOR --> OPENAI_SVC
    VECTOR --> DEEPSEEK_SVC
    
    PLAN_API --> PLANNING
    PLANNING --> VECTOR
    PLANNING --> OPENAI_SVC
    
    GEN_API --> ORCHESTRATOR
    ORCHESTRATOR --> QUEUE_MGR
    QUEUE_MGR --> WORKER_POOL
    
    WORKER_POOL --> VECTOR
    WORKER_POOL --> OPENAI_SVC
    WORKER_POOL --> DEEPSEEK_SVC
    WORKER_POOL --> VALIDATION
    
    STATUS_API --> WORKER_POOL
```

## 🔄 Data Flow Diagrams

### 4. Complete User Journey

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Gateway
    participant ChatAPI
    participant DocService
    participant LLM
    participant DB
    
    Note over User,DB: Phase 1: Document Upload
    User->>Frontend: Upload document
    Frontend->>Gateway: POST /upload-document
    Gateway->>DocService: Process file
    
    DocService->>DocService: Extract text
    DocService->>DocService: OCR if needed
    DocService->>DocService: Chunk content
    DocService->>LLM: Generate embeddings
    LLM-->>DocService: Return vectors
    DocService->>DB: Store chunks + vectors
    DocService-->>Frontend: SSE: Document ready
    Frontend-->>User: Show success
    
    Note over User,DB: Phase 2: Chat Request
    User->>Frontend: Type message
    Frontend->>Gateway: POST /ai/chat
    Gateway->>ChatAPI: Process request
    
    ChatAPI->>ChatAPI: Build context
    ChatAPI->>DB: Get document content
    ChatAPI->>LLM: Generate response
    
    Note over User,DB: Phase 3: Streaming Response
    loop Streaming
        LLM-->>ChatAPI: Stream chunk
        ChatAPI-->>Frontend: SSE: Content chunk
        Frontend-->>User: Display update
    end
    
    Note over User,DB: Phase 4: Tool Call
    LLM-->>ChatAPI: Tool call: previewQuestions
    ChatAPI-->>Frontend: SSE: Tool call data
    Frontend->>Frontend: Parse & convert
    Frontend-->>User: Show artifact preview
    
    Note over User,DB: Phase 5: Full Generation (Optional)
    User->>Frontend: Generate full set
    Frontend->>Gateway: POST /start-generation
    Gateway->>DocService: Create plan + jobs
    DocService->>DB: Store jobs
    DocService-->>Frontend: SSE: Progress updates
    Frontend-->>User: Real-time progress
```

### 5. Document Processing Flow

```mermaid
flowchart TD
    START([User Uploads File]) --> VALIDATE{Valid File?}
    
    VALIDATE -->|No| ERROR1[Show Error]
    VALIDATE -->|Yes| STORE[Store File]
    
    STORE --> TYPE{File Type?}
    
    TYPE -->|PDF| PDF_CHECK{Has Text?}
    TYPE -->|DOCX| DOCX_PARSE[Mammoth Parser]
    TYPE -->|PPTX| PPTX_PARSE[Office Parser]
    TYPE -->|Image| IMG_VISION[Vision API]
    TYPE -->|Text| TXT_READ[Direct Read]
    
    PDF_CHECK -->|Yes| PDF_PARSE[PDF Parser]
    PDF_CHECK -->|No| OCR[OCR Processing]
    
    PDF_PARSE --> FINGER[Content Fingerprint]
    DOCX_PARSE --> FINGER
    PPTX_PARSE --> FINGER
    TXT_READ --> FINGER
    OCR --> FINGER
    
    IMG_VISION --> VISION_CHECK{Success?}
    VISION_CHECK -->|Yes| FINGER
    VISION_CHECK -->|No| OCR
    
    FINGER --> DUP{Duplicate?}
    
    DUP -->|Yes| EXISTING[Return Existing Doc]
    DUP -->|No| CHUNK[Semantic Chunking]
    
    CHUNK --> EMBED[Generate Embeddings]
    EMBED --> CACHE{In Cache?}
    
    CACHE -->|Yes| GET_CACHE[Use Cached]
    CACHE -->|No| GEN_EMBED[Generate New]
    
    GEN_EMBED --> SAVE_CACHE[Save to Cache]
    GET_CACHE --> INDEX[Vector Indexing]
    SAVE_CACHE --> INDEX
    
    INDEX --> STORE_DB[(Store in Database)]
    STORE_DB --> DONE([Document Ready])
    
    ERROR1 --> END([End])
    EXISTING --> END
    DONE --> END
```

### 6. Tool Call Processing Flow

```mermaid
flowchart LR
    subgraph "AI Response"
        RESPONSE[LLM Response Stream]
        CONTENT[Text Content Chunks]
        TOOL[Tool Call Chunks]
    end
    
    subgraph "Stream Handler"
        BUFFER[SSE Buffer]
        PARSER[JSON Parser]
        PARTIAL[Partial Parser]
        ROUTER[Content Router]
    end
    
    subgraph "Processing"
        MSG_UPDATE[Message Update]
        TOOL_PROCESS[Tool Processor]
        CONVERT[Format Converter]
        VALIDATE_FMT[Format Validator]
    end
    
    subgraph "UI Update"
        TEXT_UI[Message Display]
        ARTIFACT_UI[Artifact Renderer]
        PROGRESS_UI[Progress Indicator]
    end
    
    RESPONSE --> BUFFER
    BUFFER --> PARSER
    
    PARSER --> CONTENT
    PARSER --> TOOL
    
    CONTENT --> ROUTER
    TOOL --> ROUTER
    
    ROUTER --> MSG_UPDATE
    ROUTER --> TOOL_PROCESS
    
    MSG_UPDATE --> TEXT_UI
    TOOL_PROCESS --> PARTIAL
    PARTIAL --> PROGRESS_UI
    
    TOOL_PROCESS --> CONVERT
    CONVERT --> VALIDATE_FMT
    VALIDATE_FMT --> ARTIFACT_UI
```

### 7. Question Generation Pipeline

```mermaid
flowchart TB
    START([Start Generation]) --> LOAD_PLAN[Load Question Plan]
    
    LOAD_PLAN --> DECOMPOSE[Decompose to Jobs]
    DECOMPOSE --> CREATE_JOBS[Create Job Records]
    CREATE_JOBS --> ENQUEUE[Enqueue to Redis]
    
    ENQUEUE --> BATCH1[Batch 1: MCQ]
    ENQUEUE --> BATCH2[Batch 2: True/False]
    ENQUEUE --> BATCH3[Batch 3: Essay]
    
    BATCH1 --> WORKER1[Worker 1]
    BATCH2 --> WORKER2[Worker 2]
    BATCH3 --> WORKER3[Worker 3]
    
    WORKER1 --> RETRIEVE1[Retrieve Context]
    WORKER2 --> RETRIEVE2[Retrieve Context]
    WORKER3 --> RETRIEVE3[Retrieve Context]
    
    RETRIEVE1 --> VECTOR1[Vector Search]
    RETRIEVE2 --> VECTOR2[Vector Search]
    RETRIEVE3 --> VECTOR3[Vector Search]
    
    VECTOR1 --> GEN1[Generate Questions]
    VECTOR2 --> GEN2[Generate Questions]
    VECTOR3 --> GEN3[Generate Questions]
    
    GEN1 --> LLM1[DeepSeek LLM]
    GEN2 --> LLM2[DeepSeek LLM]
    GEN3 --> LLM3[DeepSeek LLM]
    
    LLM1 --> VAL1[Validate Quality]
    LLM2 --> VAL2[Validate Quality]
    LLM3 --> VAL3[Validate Quality]
    
    VAL1 --> CHECK1{Valid?}
    VAL2 --> CHECK2{Valid?}
    VAL3 --> CHECK3{Valid?}
    
    CHECK1 -->|Yes| STORE1[(Store Question)]
    CHECK1 -->|No| RETRY1[Retry/Skip]
    CHECK2 -->|Yes| STORE2[(Store Question)]
    CHECK2 -->|No| RETRY2[Retry/Skip]
    CHECK3 -->|Yes| STORE3[(Store Question)]
    CHECK3 -->|No| RETRY3[Retry/Skip]
    
    STORE1 --> PROGRESS1[Emit Progress]
    STORE2 --> PROGRESS2[Emit Progress]
    STORE3 --> PROGRESS3[Emit Progress]
    
    PROGRESS1 --> SSE1[SSE Stream]
    PROGRESS2 --> SSE2[SSE Stream]
    PROGRESS3 --> SSE3[SSE Stream]
    
    SSE1 --> FRONTEND[Frontend UI]
    SSE2 --> FRONTEND
    SSE3 --> FRONTEND
    
    FRONTEND --> DONE([Generation Complete])
```

## 🔀 State Diagrams

### 8. Document State Machine

```mermaid
stateDiagram-v2
    [*] --> Uploading: User uploads file
    
    Uploading --> Validating: File received
    Validating --> Error: Invalid file
    Validating --> Processing: Valid file
    
    Processing --> Extracting: Store file
    Extracting --> OCRFallback: Low quality
    Extracting --> Fingerprinting: Good quality
    OCRFallback --> Fingerprinting: OCR complete
    
    Fingerprinting --> Duplicate: Hash match
    Fingerprinting --> Chunking: New document
    
    Chunking --> Embedding: Chunks created
    Embedding --> Indexing: Embeddings ready
    Indexing --> Ready: Index complete
    
    Duplicate --> Ready: Return existing
    Ready --> [*]: Document available
    Error --> [*]: Process failed
```

### 9. Question Generation State Machine

```mermaid
stateDiagram-v2
    [*] --> Planning: User requests questions
    
    Planning --> Analyzing: Load document
    Analyzing --> PlanCreated: Analysis complete
    PlanCreated --> Orchestrating: Plan stored
    
    Orchestrating --> Queued: Jobs created
    Queued --> Processing: Worker picks up
    
    Processing --> Retrieving: Load task
    Retrieving --> Generating: Context ready
    Generating --> Validating: Question draft
    
    Validating --> Valid: Passes checks
    Validating --> Invalid: Fails checks
    
    Invalid --> Retry: Retry available
    Invalid --> Failed: Max retries
    Retry --> Generating: Retry generation
    
    Valid --> Stored: Save to DB
    Stored --> MoreTasks: Check queue
    
    MoreTasks --> Processing: More tasks
    MoreTasks --> Completed: All done
    
    Completed --> [*]: Success
    Failed --> [*]: Partial success
```

## 📈 Deployment Architecture

### 10. Production Deployment

```mermaid
graph TB
    subgraph "Load Balancer"
        LB[NGINX Load Balancer]
    end
    
    subgraph "Application Servers"
        APP1[Next.js Server 1]
        APP2[Next.js Server 2]
        APP3[Next.js Server 3]
    end
    
    subgraph "Worker Pool"
        WORKER1[Worker Node 1]
        WORKER2[Worker Node 2]
        WORKER3[Worker Node 3]
    end
    
    subgraph "Data Layer"
        PG_PRIMARY[(PostgreSQL Primary)]
        PG_REPLICA1[(PostgreSQL Replica 1)]
        PG_REPLICA2[(PostgreSQL Replica 2)]
        REDIS_CLUSTER[(Redis Cluster)]
    end
    
    subgraph "Storage"
        S3[Object Storage<br/>Documents]
    end
    
    subgraph "External Services"
        OPENAI[OpenAI API]
        DEEPSEEK[DeepSeek API]
    end
    
    subgraph "Monitoring"
        LOGS[Log Aggregator]
        METRICS[Metrics Collector]
        ALERTS[Alert Manager]
    end
    
    LB --> APP1
    LB --> APP2
    LB --> APP3
    
    APP1 --> PG_PRIMARY
    APP2 --> PG_REPLICA1
    APP3 --> PG_REPLICA2
    
    APP1 --> REDIS_CLUSTER
    APP2 --> REDIS_CLUSTER
    APP3 --> REDIS_CLUSTER
    
    REDIS_CLUSTER --> WORKER1
    REDIS_CLUSTER --> WORKER2
    REDIS_CLUSTER --> WORKER3
    
    WORKER1 --> PG_PRIMARY
    WORKER2 --> PG_PRIMARY
    WORKER3 --> PG_PRIMARY
    
    APP1 --> S3
    APP2 --> S3
    APP3 --> S3
    
    WORKER1 --> OPENAI
    WORKER1 --> DEEPSEEK
    WORKER2 --> OPENAI
    WORKER2 --> DEEPSEEK
    WORKER3 --> OPENAI
    WORKER3 --> DEEPSEEK
    
    APP1 --> LOGS
    APP2 --> LOGS
    APP3 --> LOGS
    WORKER1 --> LOGS
    WORKER2 --> LOGS
    WORKER3 --> LOGS
    
    APP1 --> METRICS
    METRICS --> ALERTS
```

### 11. Data Persistence Layer

```mermaid
erDiagram
    DocumentIndex ||--o{ DocumentChunk : contains
    DocumentIndex {
        string id PK
        string userId
        string filename
        string contentFingerprint UK
        string status
        datetime createdAt
    }
    
    DocumentChunk ||--o{ QuestionCitation : referenced_by
    DocumentChunk {
        string id PK
        string documentId FK
        int chunkIndex
        text content
        float[] embedding
        string sectionPath
        datetime createdAt
    }
    
    QuestionPlan ||--o{ GenerationJob : executes
    QuestionPlan {
        string id PK
        string documentId FK
        string userId FK
        json questionTypes
        int totalQuestions
        string status
        datetime createdAt
    }
    
    GenerationJob ||--o{ QuestionGenerationTask : contains
    GenerationJob {
        string id PK
        string planId FK
        string type
        string status
        int priority
        datetime createdAt
    }
    
    QuestionGenerationTask ||--o{ QuestionItem : produces
    QuestionGenerationTask {
        string id PK
        string jobId FK
        string questionType
        string status
        datetime createdAt
    }
    
    QuestionItem ||--o{ QuestionCitation : cites
    QuestionItem {
        string id PK
        string planId FK
        string taskId FK
        string type
        text stem
        json options
        json answer
        float validationScore
        datetime createdAt
    }
    
    QuestionCitation {
        string id PK
        string questionId FK
        string chunkId FK
        string citedText
    }
```

## 🎯 Integration Patterns

### 12. Frontend-Backend Integration

```mermaid
sequenceDiagram
    participant Component as React Component
    participant Hook as useAIToolCalls
    participant Handler as AIStreamingHandler
    participant API as Backend API
    participant Service as AI Service
    participant LLM as LLM Provider
    
    Component->>Handler: streamWithTools()
    Handler->>API: GET /api/v2/ai/chat
    API->>Service: Process request
    Service->>LLM: Generate response
    
    loop Streaming
        LLM-->>Service: Stream chunk
        Service-->>API: SSE chunk
        API-->>Handler: SSE event
        Handler->>Handler: Parse SSE
        
        alt Content chunk
            Handler-->>Component: onContent(text)
            Component->>Component: Update message
        else Tool call chunk
            Handler-->>Hook: onToolCall(name, args)
            Hook->>Hook: Convert format
            Hook-->>Component: Callback with questions
            Component->>Component: Render artifact
        end
    end
    
    LLM-->>Service: Stream complete
    Service-->>API: [DONE]
    API-->>Handler: Complete event
    Handler-->>Component: onComplete()
```

---

**Document Version:** 3.0.0  
**Last Updated:** 2025-01-30  
**Format:** Mermaid Diagrams
