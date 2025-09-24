# Frontend Integration Guide: Question Generator Architecture

## Overview

This guide demonstrates how to integrate the frontend with our newly implemented question generator architecture (Tasks 1-9). The current frontend uses legacy document processing services, but we've now built a scalable, tenant-aware question generation pipeline.

## Architecture Comparison

### Current Frontend Flow (Legacy)
```
User Upload → /api/documents/parse-chunked → LessonDocumentFormService → Direct AI API → GabayFormService
```

### New Question Generator Architecture Flow
```
User Upload → /api/v2/question-generator/upload-document → Document Processing Pipeline
          ↓
Question Planning → /api/v2/question-generator/create-plan → QuestionPlanningService
          ↓
Question Generation → /api/v2/question-generator/start-generation → BullMQ Job Queue
          ↓
Background Workers → QuestionGenerationWorkerPool → Validation → Results
```

## New Frontend Services

### 1. QuestionGeneratorClientService

**Location:** `frontend/src/services/question-generator-client.service.ts`

This service provides a clean interface to interact with the new backend architecture:

```typescript
// Upload document with real-time progress
const uploadResult = await QuestionGeneratorClient.uploadDocument(file, onProgress);

// Create question plan
const planResult = await QuestionGeneratorClient.createQuestionPlan(planRequest, onProgress);

// Start generation jobs
const genResult = await QuestionGeneratorClient.startQuestionGeneration(request, onProgress);

// Poll for results
const questions = await QuestionGeneratorClient.getGeneratedQuestions(plan_id);
```

**Key Features:**
- **Server-Sent Events (SSE)** for real-time progress tracking
- **Tenant-aware** requests (automatically handled)
- **Robust error handling** with retry logic
- **Type-safe interfaces** for all operations

### 2. Enhanced React Hook

**Location:** `frontend/src/components/QuestionGeneratorIntegration.tsx`

```typescript
const { generateQuestionsFromDocument, progress, isProcessing } = useQuestionGeneratorIntegration();

const result = await generateQuestionsFromDocument(file, {
  subject: "Mathematics",
  topic: "Algebra", 
  grade_level: "Grade 8",
  difficulty_level: "intermediate",
  question_types: {
    multiple_choice: 5,
    true_false: 3,
    short_answer: 2,
    essay: 1,
    fill_blank: 2
  }
});
```

## Integration Steps

### Step 1: Update AIAssistantChat Component

The current `AIAssistantChat.tsx` (4000+ lines) needs to be updated to use the new architecture. Here's how:

#### Current Implementation:
```typescript
// OLD: Legacy document processing
const processFilesSmartly = async (files: File[]) => {
  // Uses EnhancedDocumentParserServiceInstance
  // Direct AI API calls
  // No tenant isolation
};
```

#### New Implementation:
```typescript
// NEW: Question Generator Architecture
const handleFileUpload = async (files: FileList) => {
  const uploadResult = await QuestionGeneratorClient.uploadDocument(
    files[0],
    (progress) => {
      // Real-time progress updates
      setProgress(progress);
    }
  );
  
  // Document is now processed with proper tenant isolation
  // Vector indexing completed
  // Ready for question generation
};
```

### Step 2: Replace Legacy Services

#### Remove Dependencies:
```typescript
// REMOVE these legacy imports
import { EnhancedDocumentParserServiceInstance } from '../services/enhanced-document-parser.service'
import { LessonDocumentFormService } from '../services/lesson-document-form.service'
import { SmartChunkerServiceInstance } from '../utils/smart-chunker.service'
```

#### Add New Dependencies:
```typescript
// ADD these new imports
import { QuestionGeneratorClient } from '../services/question-generator-client.service'
import { useQuestionGeneratorIntegration } from '../components/QuestionGeneratorIntegration'
```

### Step 3: Update Message Handling

#### Enhanced Message Interface:
```typescript
interface EnhancedMessage extends Message {
  questionGeneratorData?: {
    document_id?: string;
    plan_id?: string;
    questions?: any[];
    metadata?: any;
  };
}
```

#### Smart Request Detection:
```typescript
const handleSendMessage = async () => {
  const isQuestionRequest = /generate|create|make.*question|quiz|test|assessment/i.test(currentMessage);
  
  if (isQuestionRequest && hasProcessedDocument) {
    // Use new architecture
    await generateQuestionsFromDocument(file, options);
  } else {
    // Handle as regular chat
    await handleRegularChat();
  }
};
```

### Step 4: Progress Tracking Enhancement

#### Real-time Progress Updates:
```typescript
const [questionGeneratorState, setQuestionGeneratorState] = useState({
  stage: 'idle' | 'uploading' | 'planning' | 'generating' | 'completed' | 'error',
  progress: 0,
  message: '',
  document_id?: string,
  plan_id?: string,
  questions?: any[]
});

// Update UI based on stage
{questionGeneratorState.stage === 'uploading' && <UploadProgress />}
{questionGeneratorState.stage === 'planning' && <PlanningProgress />}
{questionGeneratorState.stage === 'generating' && <GenerationProgress />}
{questionGeneratorState.stage === 'completed' && <ResultsDisplay />}
```

## Key Benefits of New Architecture

### 1. **Tenant Isolation**
- Each request properly includes tenant headers
- Database queries are tenant-scoped
- Complete data isolation between tenants

### 2. **Scalable Processing**
- Documents processed in optimized chunks (700-1200 tokens)
- Vector embeddings cached and reused
- Background job processing with BullMQ

### 3. **Real-time Feedback**
- Server-Sent Events for live progress
- Detailed stage tracking
- Error handling with recovery options

### 4. **Quality Control**
- AI validation of generated questions
- Automatic deduplication
- Difficulty level verification

### 5. **Performance Optimization**
- Model tiering (DeepSeek for text, GPT Vision for images)
- Intelligent caching strategies
- Cost-effective processing

## Migration Strategy

### Phase 1: Parallel Implementation
1. Keep existing legacy services running
2. Add new QuestionGeneratorClient service
3. Create feature flag to switch between old/new

### Phase 2: Gradual Migration
1. Update AIAssistantChat to use new architecture for new uploads
2. Migrate existing processed documents to new format
3. Test thoroughly with real user data

### Phase 3: Legacy Removal
1. Remove old document processing services
2. Clean up unused dependencies
3. Update all references to new architecture

## Code Examples

### Complete Document Upload Flow:
```typescript
const handleCompleteFlow = async (file: File) => {
  try {
    // Step 1: Upload Document
    const uploadResult = await QuestionGeneratorClient.uploadDocument(file, onProgress);
    
    // Step 2: Create Plan
    const planResult = await QuestionGeneratorClient.createQuestionPlan({
      document_id: uploadResult.document_id,
      subject: "Mathematics",
      topic: "Algebra",
      grade_level: "Grade 8",
      difficulty_level: "intermediate",
      question_types: {
        multiple_choice: 5,
        true_false: 3,
        short_answer: 2,
        essay: 1,
        fill_blank: 2
      }
    }, onProgress);
    
    // Step 3: Generate Questions
    const genResult = await QuestionGeneratorClient.startQuestionGeneration({
      plan_id: planResult.plan_id,
      priority: 8
    }, onProgress);
    
    // Step 4: Poll for Results
    let attempts = 0;
    while (attempts < 60) {
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      const status = await QuestionGeneratorClient.getPlanStatus(planResult.plan_id);
      if (status.status === 'completed') {
        const questions = await QuestionGeneratorClient.getGeneratedQuestions(planResult.plan_id);
        onQuestionGenerated(questions.questions, questions.metadata);
        break;
      }
      attempts++;
    }
    
  } catch (error) {
    console.error('Question generation failed:', error);
    onError(error);
  }
};
```

### Error Handling:
```typescript
const handleError = (error: Error, stage: string) => {
  setQuestionGeneratorState({
    stage: 'error',
    progress: 0,
    message: error.message
  });

  toast({
    variant: "destructive",
    title: `${stage} Failed`,
    description: error.message
  });
};
```

## Testing

### Unit Tests:
```typescript
describe('QuestionGeneratorClient', () => {
  it('should upload document with progress tracking', async () => {
    const progressSpy = jest.fn();
    const result = await QuestionGeneratorClient.uploadDocument(mockFile, progressSpy);
    
    expect(result.success).toBe(true);
    expect(result.document_id).toBeDefined();
    expect(progressSpy).toHaveBeenCalled();
  });
});
```

### Integration Tests:
```typescript
describe('Complete Question Generation Flow', () => {
  it('should generate questions from document end-to-end', async () => {
    const file = new File(['test content'], 'test.txt', { type: 'text/plain' });
    
    const result = await generateQuestionsFromDocument(file, {
      subject: 'Math',
      topic: 'Algebra',
      grade_level: 'Grade 8',
      difficulty_level: 'intermediate',
      question_types: { multiple_choice: 5, true_false: 3, short_answer: 2, essay: 1, fill_blank: 2 }
    });
    
    expect(result.success).toBe(true);
    expect(result.questions).toHaveLength(13);
  });
});
```

## Performance Monitoring

### Metrics to Track:
- Document upload time
- Processing pipeline duration
- Question generation success rate
- User experience metrics (time to first question)

### Monitoring Implementation:
```typescript
const trackMetrics = (stage: string, duration: number, success: boolean) => {
  analytics.track('question_generator_stage', {
    stage,
    duration,
    success,
    timestamp: Date.now()
  });
};
```

## Conclusion

The new question generator architecture provides a much more robust, scalable, and maintainable solution compared to the legacy approach. The frontend integration maintains a familiar user experience while leveraging the powerful backend pipeline we've built.

The key to successful migration is implementing the new services alongside the existing ones, then gradually transitioning users to the new experience with proper monitoring and feedback collection.