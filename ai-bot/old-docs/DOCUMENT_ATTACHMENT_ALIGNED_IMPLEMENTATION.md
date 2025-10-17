# Document Attachment Implementation - Aligned with Existing Architecture

## ✅ Architecture Alignment Confirmation

This implementation plan **extends your existing services** rather than creating new ones. Here's how it aligns with your current backend structure:

## Existing Services to Extend (Not Replace)

### 1. **DocumentIngestionService** (`document-ingestion.service.ts`)
**Current Capability**: Multi-format processing, OCR, fingerprinting
**Extension Needed**:
```typescript
// Add to existing DocumentIngestionService class
class DocumentIngestionService {
  // EXISTING: Your current methods remain unchanged
  async ingestDocument(...) { /* existing */ }
  
  // NEW: Add document type detection
  async detectDocumentType(documentId: string, extractedText: string): Promise<DocumentTypeAnalysis> {
    // Detect if it's a legacy questionnaire, lesson planner, or learning material
    const patterns = await this.detectQuestionPatterns(extractedText);
    const structure = await this.analyzeDocumentStructure(extractedText);
    return this.classifyDocumentType(patterns, structure);
  }
  
  // NEW: Preserve formatting during extraction
  async extractWithFormatPreservation(file: File, options: FormatOptions) {
    // Enhanced extraction that maintains structure
    const extracted = await this.extractText(file, options);
    const formatting = await this.captureFormatting(file);
    return { text: extracted, formatting };
  }
}
```

### 2. **DocumentChunkingService** (`document-chunking.service.ts`)
**Current Capability**: Semantic chunking, token optimization
**Extension Needed**:
```typescript
// Add to existing DocumentChunkingService
class DocumentChunkingService {
  // EXISTING: Current chunking methods
  async chunkDocument(...) { /* existing */ }
  
  // NEW: Question-aware chunking for legacy questionnaires
  async chunkQuestionnaire(documentId: string, questions: QuestionPattern[]) {
    // Special chunking that keeps questions intact
    const chunks = [];
    for (const question of questions) {
      chunks.push(this.createQuestionChunk(question));
    }
    return chunks;
  }
  
  // NEW: Lesson plan aware chunking
  async chunkLessonPlan(documentId: string, sections: LessonSection[]) {
    // Chunk by lesson sections/objectives
    return this.chunkBySections(sections);
  }
}
```

### 3. **QuestionPlanningService** (`question-planning.service.ts`)
**Current Capability**: AI-powered plan generation
**Extension Needed**:
```typescript
// Add to existing QuestionPlanningService
class QuestionPlanningService {
  // EXISTING: Plan creation
  async createQuestionPlan(...) { /* existing */ }
  
  // NEW: Teacher instruction processing
  async createPlanWithTeacherInstructions(
    documentId: string,
    instructions: TeacherInstruction[],
    documentType: DocumentType
  ) {
    // Prioritize teacher instructions
    const prioritized = this.prioritizeInstructions(instructions);
    
    // Route to appropriate processor
    switch (documentType) {
      case 'legacy_questionnaire':
        return this.planFromQuestionnaire(documentId, prioritized);
      case 'lesson_planner':
        return this.planFromLessonPlan(documentId, prioritized);
      case 'learning_material':
        return this.planFromMaterial(documentId, prioritized);
    }
  }
  
  // NEW: Clarification protocol
  async generateClarificationRequest(
    ambiguousInstructions: any[],
    documentAnalysis: any
  ): Promise<ClarificationRequest> {
    // Generate clarification options based on ambiguity
    return this.buildClarificationOptions(ambiguousInstructions, documentAnalysis);
  }
}
```

### 4. **QuestionGenerationWorkerPool** (`question-generation-worker-pool.service.ts`)
**Current Capability**: Multi-tier LLM processing
**Extension Needed**:
```typescript
// Add to existing QuestionGenerationWorkerPool
class QuestionGenerationWorkerPool {
  // EXISTING: Worker processing
  async processJob(...) { /* existing */ }
  
  // NEW: Legacy question conversion worker
  async processLegacyConversion(job: Job) {
    const { documentId, questions, preserveFormat } = job.data;
    
    // Convert legacy questions to online format
    const converted = await this.convertQuestions(questions, {
      preserveNumbering: preserveFormat,
      enhanceClarity: !preserveFormat,
      addExplanations: true
    });
    
    // Use existing validation
    return this.validateQuestions(converted);
  }
  
  // NEW: Lesson-aligned generation
  async processLessonAlignedGeneration(job: Job) {
    const { objectives, topics, timeline } = job.data;
    
    // Generate questions aligned with lesson objectives
    const questions = await this.generateFromObjectives(objectives);
    
    // Use existing validation and storage
    return this.validateAndStore(questions);
  }
}
```

### 5. **QuestionGenerationOrchestrator** (`question-generation-orchestrator.service.ts`)
**Current Capability**: Job orchestration and coordination
**Extension Needed**:
```typescript
// Add to existing Orchestrator
class QuestionGenerationOrchestrator {
  // EXISTING: Standard orchestration
  async orchestrateGeneration(...) { /* existing */ }
  
  // NEW: Document-type aware orchestration
  async orchestrateWithDocumentType(
    planId: string,
    documentType: DocumentType,
    instructions: TeacherInstruction[]
  ) {
    // Route to appropriate processing pipeline
    const jobs = await this.createDocumentSpecificJobs(
      planId, 
      documentType,
      instructions
    );
    
    // Use existing queue system
    return this.queueManager.addBulkJobs(jobs);
  }
}
```

### 6. **StreamingProgressService** (`streaming-progress.service.ts`)
**Current Capability**: SSE/WebSocket progress updates
**No Changes Needed** - Works as-is for document processing progress

### 7. **QuestionValidationService** (`question-validation.service.ts`)
**Current Capability**: LLM validation and scoring
**Extension Needed**:
```typescript
// Add to existing ValidationService
class QuestionValidationService {
  // EXISTING: Standard validation
  async validateQuestion(...) { /* existing */ }
  
  // NEW: Format fidelity validation
  async validateFormatPreservation(
    original: OriginalQuestion,
    converted: ConvertedQuestion
  ): Promise<FormatFidelityScore> {
    // Check if formatting was properly preserved
    return {
      numberingPreserved: this.checkNumbering(original, converted),
      structureIntact: this.checkStructure(original, converted),
      contentComplete: this.checkContent(original, converted)
    };
  }
}
```

## New Utility Modules (Not Services)

These are lightweight utilities that support the existing services:

### 1. **Teacher Instruction Parser** (Utility)
```typescript
// api/src/utils/teacher-instruction-parser.util.ts
export class TeacherInstructionParser {
  static parseInstructions(message: string): TeacherInstruction[] {
    // Parse teacher's natural language instructions
  }
  
  static prioritizeInstructions(instructions: TeacherInstruction[]): PrioritizedInstructions {
    // Priority: Explicit > Implicit > Inferred > Default
  }
  
  static detectConflicts(instructions: TeacherInstruction[]): Conflict[] {
    // Detect conflicting instructions
  }
}
```

### 2. **Document Pattern Detector** (Utility)
```typescript
// api/src/utils/document-pattern-detector.util.ts
export class DocumentPatternDetector {
  static detectQuestionPatterns(text: string): QuestionPattern[] {
    // MCQ, T/F, Essay, Fill-blank patterns
  }
  
  static detectLessonPlanElements(text: string): LessonElements {
    // Objectives, timeline, topics
  }
  
  static detectAnswerKey(text: string): AnswerKeyInfo {
    // Answer key patterns
  }
}
```

### 3. **Format Preservator** (Utility)
```typescript
// api/src/utils/format-preservator.util.ts
export class FormatPreservator {
  static captureFormatting(original: string): FormattingMetadata {
    // Capture indentation, numbering, structure
  }
  
  static applyFormatting(content: string, metadata: FormattingMetadata): string {
    // Apply preserved formatting
  }
}
```

## API Endpoints (Using Existing Pattern)

### Extend Existing Endpoints
```typescript
// api/src/pages/api/v2/question-generator/upload-document.ts
// EXTEND existing endpoint to include document type detection

// api/src/pages/api/v2/question-generator/create-plan.ts
// EXTEND to handle teacher instructions and clarifications

// NEW endpoint following existing pattern:
// api/src/pages/api/v2/question-generator/clarify-instructions.ts
export default async function handler(req, res) {
  const { planId, selection } = req.body;
  const planningService = QuestionPlanningService.getInstance();
  const result = await planningService.resolveClarification(planId, selection);
  return res.json(result);
}
```

## Frontend Integration (Using Existing Components)

### Extend AIAssistantChatEnhanced
```typescript
// frontend/src/components/AIAssistantChatEnhanced.tsx

// Use existing hooks and services
import { useAIToolCalls } from '../hooks/useAIToolCalls';
import { QuestionGeneratorClient } from '../services/question-generator-client.service';

// Add document type handling to existing flow
const processDocumentWithType = async (file: File) => {
  // Use existing upload with type detection
  const uploadResult = await QuestionGeneratorClient.uploadDocument(
    file,
    (progress) => {
      // Existing progress handling
      setProgress(progress);
    }
  );
  
  // New: Check document type
  if (uploadResult.documentType === 'legacy_questionnaire') {
    // Show conversion options using existing UI patterns
    setShowConversionOptions(true);
  }
  
  // Continue with existing flow
  await handleQuestionGeneration(uploadResult);
};
```

## Database Schema (Using Existing Prisma Models)

No new tables needed! Extend existing models:

```prisma
// api/prisma/schema/question-generator.prisma

model DocumentIndex {
  // EXISTING fields remain
  
  // ADD these fields
  documentType        String?    @default("unknown")
  detectedPatterns    Json?      // Store pattern analysis
  formatMetadata      Json?      // Store formatting info
  teacherInstructions Json?      // Store instructions
}

model QuestionPlan {
  // EXISTING fields remain
  
  // ADD these fields
  sourceDocumentType  String?
  preserveFormatting  Boolean    @default(false)
  clarificationData   Json?
}
```

## Worker Queue Jobs (Using Existing BullMQ)

```typescript
// Use existing queue, add new job types
enum JobType {
  // EXISTING job types
  GENERATE_MCQ = 'generate_mcq',
  GENERATE_ESSAY = 'generate_essay',
  
  // NEW job types
  CONVERT_LEGACY = 'convert_legacy',
  PROCESS_LESSON_PLAN = 'process_lesson_plan',
  EXTRACT_OBJECTIVES = 'extract_objectives'
}

// Jobs flow through existing queue system
queueManager.addJob({
  type: JobType.CONVERT_LEGACY,
  data: { documentId, questions, preserveFormat: true },
  priority: 8
});
```

## Summary of Alignment

✅ **Uses Existing Services**: Extends rather than replaces
✅ **Follows Existing Patterns**: Same service structure, API patterns
✅ **Leverages Existing Infrastructure**: BullMQ, Redis, PostgreSQL, pgvector
✅ **Compatible with Worker Pool**: Adds job types, not new workers
✅ **Maintains Existing Flow**: Document → Chunks → Plan → Jobs → Questions
✅ **Uses Existing Progress System**: SSE/WebSocket unchanged
✅ **Database Compatible**: Extends existing Prisma models

## Implementation Priority

1. **Phase 1**: Extend existing services with new methods
2. **Phase 2**: Add utility functions for pattern detection
3. **Phase 3**: Update API endpoints with new parameters
4. **Phase 4**: Enhance frontend with clarification UI

This approach ensures **zero disruption** to existing functionality while adding the new teacher-focused features.
