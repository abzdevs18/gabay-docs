# Gabay AI Chatbot - Detailed Flow Diagrams

## 1. Complete System Flow

```mermaid
graph TB
    subgraph "User Interaction"
        U1[User Types Message]
        U2[User Attaches Document]
        U3[User Requests Questions]
    end
    
    subgraph "Frontend Processing"
        F1[AIAssistantChatEnhanced]
        F2[Message State Management]
        F3[Attachment Processing]
        F4[Stream Handler]
        F5[Tool Call Detection]
        F6[Question Preview]
    end
    
    subgraph "API Layer"
        A1[Chat API Endpoint]
        A2[Document Upload API]
        A3[Question Plan API]
        A4[Generation API]
        A5[Progress SSE]
    end
    
    subgraph "Backend Services"
        B1[Chat Service]
        B2[Document Ingestion]
        B3[Document Chunking]
        B4[Question Planning]
        B5[Orchestrator]
        B6[Worker Pool]
    end
    
    subgraph "AI Providers"
        AI1[DeepSeek LLM]
        AI2[OpenAI GPT]
        AI3[Embedding Model]
    end
    
    subgraph "Data Storage"
        D1[PostgreSQL]
        D2[Redis Cache]
        D3[File System]
        D4[pgvector]
    end
    
    U1 --> F1
    U2 --> F3
    U3 --> F1
    
    F1 --> F2
    F1 --> F4
    F3 --> A2
    F4 --> F5
    F5 --> F6
    
    F1 --> A1
    A1 --> B1
    A2 --> B2
    A3 --> B4
    A4 --> B5
    
    B1 --> AI1
    B2 --> B3
    B3 --> D4
    B4 --> AI1
    B5 --> B6
    B6 --> AI1
    B6 --> AI2
    
    B2 --> D3
    B4 --> D1
    B5 --> D2
    B6 --> D1
    
    A5 --> F4
```

## 2. Document Attachment Flow

```mermaid
sequenceDiagram
    participant U as User
    participant FE as Frontend
    participant API as Upload API
    participant DI as Document Ingestion
    participant DC as Document Chunking
    participant VP as Vector Processing
    participant DB as Database
    
    U->>FE: Select file to attach
    FE->>FE: Validate file type/size
    FE->>API: POST /upload with file
    API->>DI: ingestDocument(file)
    
    DI->>DI: Extract file content
    DI->>DI: Generate fingerprint
    DI->>DB: Check for duplicate
    
    alt Duplicate exists
        DB-->>DI: Return existing document
        DI-->>API: Return cached result
    else New document
        DI->>DC: Process for chunking
        DC->>DC: Detect document type
        DC->>DC: Apply chunking strategy
        DC->>VP: Generate embeddings
        VP->>DB: Store vectors
        DB-->>DI: Confirm storage
    end
    
    DI-->>API: Return document_id
    API-->>FE: Update attachment status
    FE-->>U: Show ready indicator
```

## 3. Question Generation from Chat

```mermaid
flowchart TD
    subgraph "Detection Phase"
        A[User Message] --> B{Contains Generation Request?}
        B -->|No| C[Normal Chat Flow]
        B -->|Yes| D[Extract Parameters]
        D --> E[Count & Type Preferences]
        E --> F[Build Instructions]
    end
    
    subgraph "Planning Phase"
        F --> G{Has Attachment?}
        G -->|Yes| H[Document-based Planning]
        G -->|No| I[Text-based Planning]
        H --> J[Retrieve Document Content]
        J --> K[Analyze Document Type]
        K --> L{Document Type}
        L -->|Questionnaire| M[Preserve Format Plan]
        L -->|Lesson Plan| N[Objective-based Plan]
        L -->|Learning Material| O[Topic-based Plan]
        M --> P[Create Question Plan]
        N --> P
        O --> P
        I --> P
    end
    
    subgraph "Generation Phase"
        P --> Q[Queue Generation Jobs]
        Q --> R[Worker Pool Processing]
        R --> S[Context Retrieval]
        S --> T[LLM Generation]
        T --> U[Quality Validation]
        U --> V{Pass Validation?}
        V -->|No| W[Regenerate]
        V -->|Yes| X[Store Questions]
        W --> T
    end
    
    subgraph "Delivery Phase"
        X --> Y[Stream to Frontend]
        Y --> Z[Tool Call Detection]
        Z --> AA[Parse Questions]
        AA --> AB[Update Preview]
        AB --> AC[Show to User]
    end
```

## 4. Real-time Streaming Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant SSE as SSE Connection
    participant API as Chat API
    participant LLM as AI Provider
    participant TC as Tool Call Parser
    
    C->>API: POST /api/v2/ai/chat
    API->>API: Prepare context
    API->>SSE: Initialize stream
    SSE-->>C: Headers (text/event-stream)
    
    API->>LLM: Stream completion request
    
    loop Streaming
        LLM-->>API: Delta chunk
        API->>API: Process chunk
        
        alt Content Delta
            API-->>SSE: data: {content: "..."}
            SSE-->>C: Update message
        else Tool Call Delta
            API-->>TC: Parse tool call
            TC-->>API: Structured data
            API-->>SSE: data: {tool_calls: [...]}
            SSE-->>C: Process tool call
        end
    end
    
    LLM-->>API: Stream complete
    API-->>SSE: data: [DONE]
    SSE-->>C: Finalize message
    C->>C: Show preview if questions
```

## 5. Question Preview & Tool Call Flow

```mermaid
flowchart LR
    subgraph "Tool Call Detection"
        A[AI Response Stream] --> B[Parse Delta]
        B --> C{Has tool_calls?}
        C -->|Yes| D[Extract Function Name]
        C -->|No| E[Regular Content]
        D --> F{preview_questions?}
        F -->|Yes| G[Parse Arguments]
        F -->|No| H[Other Tool]
    end
    
    subgraph "Question Processing"
        G --> I[Extract Questions Array]
        I --> J[Convert Format]
        J --> K[Map Types]
        K --> L[Add Metadata]
        L --> M[Build Preview Data]
    end
    
    subgraph "UI Updates"
        M --> N[Update State]
        N --> O[Show Preview Panel]
        O --> P[Render Questions]
        P --> Q[Enable Actions]
        Q --> R[Save/Print Options]
    end
    
    E --> S[Update Chat Message]
    H --> T[Handle Other Tools]
```

## 6. Worker Pool Processing

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> JobReceived: New job from queue
    JobReceived --> ValidateJob: Check job data
    
    ValidateJob --> ContextRetrieval: Valid
    ValidateJob --> ErrorState: Invalid
    
    ContextRetrieval --> PreparePrompt: Retrieved chunks
    PreparePrompt --> SelectModel: Build LLM prompt
    
    SelectModel --> DeepSeekGen: Cost-effective
    SelectModel --> OpenAIGen: Complex task
    
    DeepSeekGen --> ParseResponse
    OpenAIGen --> ParseResponse
    
    ParseResponse --> ValidateOutput: Parse JSON
    ParseResponse --> RetryGeneration: Parse failed
    
    ValidateOutput --> QualityCheck: Structured data
    QualityCheck --> StoreResult: Pass
    QualityCheck --> RetryGeneration: Fail
    
    RetryGeneration --> SelectModel: Retry < 3
    RetryGeneration --> ErrorState: Max retries
    
    StoreResult --> UpdateProgress
    UpdateProgress --> Idle: Complete
    
    ErrorState --> LogError
    LogError --> Idle: Continue
```

## 7. Document Type Detection Flow

```mermaid
flowchart TD
    A[Document Text] --> B[Pattern Analysis]
    
    B --> C[Question Patterns]
    C --> C1[MCQ Detection]
    C --> C2[True/False Detection]
    C --> C3[Essay Detection]
    C --> C4[Fill-in-blank Detection]
    
    B --> D[Structure Patterns]
    D --> D1[Lesson Plan Markers]
    D --> D2[Learning Objectives]
    D --> D3[Schedule/Timeline]
    D --> D4[Answer Keys]
    
    B --> E[Content Patterns]
    E --> E1[Educational Terms]
    E --> E2[Grade Level Indicators]
    E --> E3[Subject Keywords]
    
    C1 --> F[Calculate Scores]
    C2 --> F
    C3 --> F
    C4 --> F
    D1 --> F
    D2 --> F
    D3 --> F
    D4 --> F
    E1 --> F
    E2 --> F
    E3 --> F
    
    F --> G{Confidence Score}
    G -->|> 0.8| H[Questionnaire]
    G -->|> 0.6| I[Lesson Planner]
    G -->|> 0.4| J[Learning Material]
    G -->|<= 0.4| K[Unknown/Mixed]
    
    H --> L[Apply Specific Strategy]
    I --> L
    J --> L
    K --> M[Apply Generic Strategy]
```

## 8. Auto-Preview Detection Flow

```mermaid
sequenceDiagram
    participant AI as AI Response
    participant D as Detector
    participant P as Parser
    participant B as Backend API
    participant UI as Preview UI
    
    AI->>D: Stream content
    D->>D: Check for markers
    
    alt Structured Content Detected
        D->>P: Parse questions
        P->>P: Extract Q&A format
        
        opt Complex Format
            P->>B: POST /auto-preview
            B->>B: AI-powered parsing
            B-->>P: Structured questions
        end
        
        P->>UI: Update preview
        UI->>UI: Show questions
    else Normal Content
        D->>UI: Update chat only
    end
    
    Note over D: Markers include:
    Note over D: - Numbered questions
    Note over D: - Multiple choice format
    Note over D: - Answer indicators
    Note over D: - Subject/Topic headers
```

## 9. Progress Tracking Flow

```mermaid
flowchart TD
    subgraph "Progress Events"
        E1[Job Started]
        E2[Document Processing]
        E3[Plan Created]
        E4[Item Generating]
        E5[Item Complete]
        E6[Job Complete]
        E7[Job Failed]
    end
    
    subgraph "SSE Stream"
        S1[Open Connection]
        S2[Send Event]
        S3[Update Progress %]
        S4[Send Message]
        S5[Close on Complete]
    end
    
    subgraph "Frontend Updates"
        U1[Progress Bar]
        U2[Status Message]
        U3[Estimated Time]
        U4[Generated Count]
        U5[Error Display]
    end
    
    E1 --> S2
    E2 --> S2
    E3 --> S2
    E4 --> S2
    E5 --> S2
    E6 --> S5
    E7 --> S5
    
    S2 --> S3
    S3 --> S4
    
    S4 --> U1
    S4 --> U2
    S4 --> U3
    S4 --> U4
    
    E7 --> U5
```

## 10. Error Recovery Flow

```mermaid
stateDiagram-v2
    [*] --> Processing
    
    Processing --> Error: Exception occurs
    
    Error --> AnalyzeError: Capture details
    
    AnalyzeError --> NetworkError: Network timeout
    AnalyzeError --> RateLimitError: API limit
    AnalyzeError --> ParseError: Invalid response
    AnalyzeError --> ValidationError: Failed QA
    
    NetworkError --> RetryWithBackoff: Retry < 3
    NetworkError --> FailJob: Max retries
    
    RateLimitError --> QueueForLater: Add delay
    QueueForLater --> Processing: After delay
    
    ParseError --> FallbackModel: Switch provider
    FallbackModel --> Processing: Retry with OpenAI
    
    ValidationError --> RegeneratePrompt: Adjust params
    RegeneratePrompt --> Processing: Retry generation
    
    RetryWithBackoff --> Processing: After backoff
    
    FailJob --> NotifyUser: Send error
    NotifyUser --> LogError: Record details
    LogError --> [*]
    
    Processing --> Success: Complete
    Success --> [*]
```

---

**Note:** These flow diagrams represent the actual implementation as found in the codebase. The system uses a hybrid approach combining real-time chat capabilities with asynchronous question generation processing, optimized for educational assessment creation.

**Last Updated:** January 26, 2025
