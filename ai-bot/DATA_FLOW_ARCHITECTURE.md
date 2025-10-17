# Gabay AI Chatbot - Data Flow Architecture

## 📊 Data Flow Overview

The Gabay AI Chatbot system processes data through multiple stages, transforming user inputs into structured educational assessments. This document details the complete data flow from input to output.

## 1. Main Data Flow Pipeline

```mermaid
graph LR
    subgraph "Input Sources"
        I1[Text Messages]
        I2[Document Files]
        I3[Teacher Instructions]
        I4[YouTube URLs]
    end
    
    subgraph "Processing Stages"
        P1[Input Validation]
        P2[Content Extraction]
        P3[Context Building]
        P4[AI Processing]
        P5[Output Generation]
    end
    
    subgraph "Data Stores"
        D1[PostgreSQL]
        D2[Redis Cache]
        D3[File System]
        D4[Vector DB]
    end
    
    subgraph "Output Formats"
        O1[Chat Messages]
        O2[Questions JSON]
        O3[Preview HTML]
        O4[Progress Events]
    end
    
    I1 --> P1
    I2 --> P1
    I3 --> P1
    I4 --> P1
    
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5
    
    P2 --> D3
    P3 --> D1
    P3 --> D2
    P4 --> D4
    
    P5 --> O1
    P5 --> O2
    P5 --> O3
    P5 --> O4
```

## 2. Document Processing Data Flow

```mermaid
flowchart TD
    subgraph "Input Layer"
        FILE[File Upload]
        META[File Metadata]
    end
    
    subgraph "Extraction Layer"
        EXT[Text Extraction]
        OCR[OCR Processing]
        PARSE[Format Parser]
    end
    
    subgraph "Analysis Layer"
        FINGER[Fingerprinting]
        TYPE[Type Detection]
        STRUCT[Structure Analysis]
    end
    
    subgraph "Transformation Layer"
        CHUNK[Chunking Engine]
        EMBED[Embedding Generator]
        INDEX[Vector Indexer]
    end
    
    subgraph "Storage Layer"
        DOC[Document Record]
        TEXT[Extracted Text]
        VECT[Vector Embeddings]
        CACHE[Redis Cache]
    end
    
    FILE --> EXT
    META --> DOC
    
    EXT --> PARSE
    EXT --> OCR
    PARSE --> FINGER
    OCR --> FINGER
    
    FINGER --> TYPE
    TYPE --> STRUCT
    STRUCT --> CHUNK
    
    CHUNK --> EMBED
    EMBED --> INDEX
    INDEX --> VECT
    
    FINGER --> DOC
    PARSE --> TEXT
    CHUNK --> CACHE
```

## 3. Question Generation Data Flow

```mermaid
graph TB
    subgraph "Request Data"
        REQ[User Request]
        DOC_ID[Document ID]
        CONFIG[Generation Config]
        INST[Instructions]
    end
    
    subgraph "Planning Data"
        PLAN[Question Plan]
        TASKS[Task List]
        BATCH[Batch Jobs]
    end
    
    subgraph "Generation Data"
        PROMPT[LLM Prompt]
        CONTEXT[Retrieved Context]
        RESPONSE[AI Response]
    end
    
    subgraph "Output Data"
        QUESTIONS[Question Objects]
        METADATA[Question Metadata]
        SCORES[Quality Scores]
    end
    
    REQ --> PLAN
    DOC_ID --> CONTEXT
    CONFIG --> PLAN
    INST --> PLAN
    
    PLAN --> TASKS
    TASKS --> BATCH
    
    BATCH --> PROMPT
    CONTEXT --> PROMPT
    PROMPT --> RESPONSE
    
    RESPONSE --> QUESTIONS
    RESPONSE --> METADATA
    QUESTIONS --> SCORES
```

## 4. Real-time Streaming Data Flow

```mermaid
sequenceDiagram
    participant Client
    participant SSE as SSE Stream
    participant Buffer
    participant Parser
    participant State
    participant UI
    
    Client->>SSE: Open connection
    SSE->>Buffer: Initialize buffer
    
    loop Streaming
        SSE->>Buffer: Receive chunk
        Buffer->>Parser: Parse JSON
        
        alt Content Update
            Parser->>State: Update message
            State->>UI: Render text
        else Tool Call
            Parser->>State: Update tools
            State->>UI: Show preview
        else Progress Event
            Parser->>State: Update progress
            State->>UI: Update bar
        end
    end
    
    SSE->>Client: Close connection
    Client->>State: Finalize
    State->>UI: Complete render
```

## 5. Context Building Data Flow

```yaml
Input Sources:
  - Current Message:
      type: string
      processing: direct
      
  - Previous Messages:
      type: array
      processing: sliding_window
      limit: 10
      
  - Document Attachments:
      type: array
      processing: extract_content
      max_size: 8000_chars
      
  - YouTube Context:
      type: object
      processing: fetch_metadata
      fields: [title, channel, description]

Context Assembly:
  System_Prompt:
    - Base_Instructions
    - Feature_Flags
    - Model_Configuration
    
  User_Context:
    - Message_History
    - Document_Content
    - External_Resources
    
  Enrichments:
    - Tenant_Information
    - User_Preferences
    - Session_State

Output Format:
  messages:
    - role: system
      content: <assembled_system_prompt>
    - role: user
      content: <enriched_user_message>
    - role: assistant
      content: <previous_responses>
```

## 6. Worker Pool Data Distribution

```mermaid
flowchart LR
    subgraph "Queue Data"
        Q1[Job Queue]
        Q2[Priority Queue]
        Q3[Retry Queue]
    end
    
    subgraph "Worker Pool"
        W1[Worker 1]
        W2[Worker 2]
        W3[Worker 3]
        WN[Worker N]
    end
    
    subgraph "Processing Data"
        P1[Job Data]
        P2[Context Data]
        P3[LLM Request]
        P4[Response Data]
    end
    
    subgraph "Result Aggregation"
        R1[Question Buffer]
        R2[Validation Results]
        R3[Final Output]
    end
    
    Q1 --> W1
    Q2 --> W2
    Q3 --> W3
    
    W1 --> P1
    W2 --> P2
    W3 --> P3
    WN --> P4
    
    P1 --> R1
    P2 --> R1
    P3 --> R1
    P4 --> R1
    
    R1 --> R2
    R2 --> R3
```

## 7. Cache Layer Data Flow

```mermaid
graph TD
    subgraph "Cache Keys"
        K1[document:fingerprint:hash]
        K2[embedding:chunk:id]
        K3[plan:user:session]
        K4[progress:plan:id]
    end
    
    subgraph "Cache Operations"
        GET[Cache Get]
        SET[Cache Set]
        DEL[Cache Delete]
        TTL[TTL Management]
    end
    
    subgraph "Data Types"
        STRING[String Values]
        HASH[Hash Maps]
        LIST[Lists]
        STREAM[Streams]
    end
    
    K1 --> GET
    K2 --> GET
    K3 --> SET
    K4 --> STREAM
    
    GET --> STRING
    SET --> HASH
    DEL --> LIST
    TTL --> STREAM
```

## 8. Database Transaction Flow

```sql
-- Document Processing Transaction
BEGIN;
  -- 1. Insert document record
  INSERT INTO DocumentIndex (id, userId, fileName, fingerprint, status)
  VALUES ($1, $2, $3, $4, 'processing');
  
  -- 2. Store extracted text
  UPDATE DocumentIndex 
  SET extractedText = $5, metadata = $6
  WHERE id = $1;
  
  -- 3. Insert chunks with vectors
  INSERT INTO DocumentChunk (documentId, chunkIndex, content, embedding)
  SELECT $1, index, content, vector
  FROM unnest($7::chunk_data[]);
  
  -- 4. Update status
  UPDATE DocumentIndex 
  SET status = 'ready'
  WHERE id = $1;
COMMIT;

-- Question Generation Transaction  
BEGIN;
  -- 1. Create plan
  INSERT INTO QuestionPlan (id, documentId, userId, planDetails, status)
  VALUES ($1, $2, $3, $4, 'processing');
  
  -- 2. Create jobs
  INSERT INTO GenerationJob (planId, batchIndex, status, priority)
  SELECT $1, index, 'queued', $5
  FROM generate_series(1, $6) as index;
  
  -- 3. Store questions
  INSERT INTO GeneratedQuestion (planId, jobId, questionType, stem, options, answer)
  SELECT $1, $2, type, question, choices, correct
  FROM unnest($7::question_data[]);
  
  -- 4. Update plan status
  UPDATE QuestionPlan 
  SET status = 'completed', questionCount = $8
  WHERE id = $1;
COMMIT;
```

## 9. Event Stream Data Flow

```mermaid
sequenceDiagram
    participant Producer
    participant EventBus
    participant SSE
    participant WebSocket
    participant Consumer
    
    Producer->>EventBus: Emit event
    EventBus->>EventBus: Route by type
    
    par SSE Clients
        EventBus->>SSE: Progress event
        SSE->>Consumer: Stream update
    and WebSocket Clients  
        EventBus->>WebSocket: Real-time event
        WebSocket->>Consumer: Push update
    end
    
    Consumer->>Consumer: Update UI
    
    Note over EventBus: Event Types:
    Note over EventBus: - progress_update
    Note over EventBus: - question_generated
    Note over EventBus: - document_ready
    Note over EventBus: - error_occurred
```

## 10. Data Transformation Pipeline

```yaml
Pipeline Stages:
  1. Input Normalization:
     - Sanitize HTML/Scripts
     - Normalize encoding
     - Validate structure
     
  2. Content Enrichment:
     - Add metadata
     - Extract entities
     - Tag categories
     
  3. Format Conversion:
     - Parse document formats
     - Convert to common structure
     - Preserve formatting hints
     
  4. Chunking Strategy:
     - Semantic boundaries
     - Token limits (700-1200)
     - Overlap windows (80-120)
     
  5. Embedding Generation:
     - Batch processing
     - Model selection
     - Dimension optimization
     
  6. Index Optimization:
     - Vector quantization
     - Similarity metrics
     - Query optimization
     
  7. Output Formatting:
     - JSON structuring
     - Type mapping
     - Validation schemas
```

## 11. Data Security Flow

```mermaid
graph TB
    subgraph "Input Security"
        I1[Input Validation]
        I2[Sanitization]
        I3[Size Limits]
        I4[Type Checks]
    end
    
    subgraph "Processing Security"
        P1[Tenant Isolation]
        P2[Access Control]
        P3[Rate Limiting]
        P4[Audit Logging]
    end
    
    subgraph "Storage Security"
        S1[Encryption at Rest]
        S2[Secure File Storage]
        S3[Database Security]
        S4[Cache Security]
    end
    
    subgraph "Output Security"
        O1[Response Filtering]
        O2[PII Masking]
        O3[CORS Headers]
        O4[Content Security]
    end
    
    I1 --> P1
    I2 --> P2
    I3 --> P3
    I4 --> P4
    
    P1 --> S1
    P2 --> S2
    P3 --> S3
    P4 --> S4
    
    S1 --> O1
    S2 --> O2
    S3 --> O3
    S4 --> O4
```

## 12. Performance Monitoring Data

```yaml
Metrics Collection:
  Request_Metrics:
    - latency_ms
    - status_code
    - error_rate
    - throughput_rps
    
  Processing_Metrics:
    - document_processing_time
    - question_generation_time
    - embedding_generation_time
    - cache_hit_rate
    
  Resource_Metrics:
    - cpu_usage_percent
    - memory_usage_mb
    - queue_depth
    - worker_utilization
    
  Business_Metrics:
    - questions_generated_per_hour
    - documents_processed_per_day
    - user_satisfaction_score
    - cost_per_operation

Data Aggregation:
  Time_Windows:
    - 1_minute
    - 5_minutes
    - 1_hour
    - 1_day
    
  Aggregation_Types:
    - average
    - percentiles: [50, 90, 95, 99]
    - max
    - min
    - count
    - sum
```

---

**Key Data Characteristics:**

| Aspect | Description |
|--------|-------------|
| **Volume** | ~10K documents/day, ~100K questions/day |
| **Velocity** | Real-time streaming, <200ms latency |
| **Variety** | Text, PDF, DOCX, structured JSON |
| **Veracity** | Quality scoring, validation checks |
| **Value** | Educational assessment automation |

**Data Retention Policies:**

- **Documents**: 90 days active, archive afterward
- **Questions**: Permanent (user ownership)
- **Logs**: 30 days standard, 1 year audit
- **Cache**: TTL-based (5min - 24hr)
- **Vectors**: Permanent with document

---

**Last Updated:** January 26, 2025  
**Architecture Version:** 2.0
