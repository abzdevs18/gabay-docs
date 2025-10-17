# Document Attachment Implementation - Complete Guide

## Implementation Summary

This document provides a complete overview of the document attachment functionality implementation for the Gabay AI Chatbot/Question Generator system, specifically addressing teacher use cases.

## ✅ Implementation Status

All components have been successfully implemented:

### Backend Services (Completed)
- ✅ **Document Pattern Detector Utility** (`api/src/utils/document-pattern-detector.util.ts`)
- ✅ **Teacher Instruction Parser Utility** (`api/src/utils/teacher-instruction-parser.util.ts`)
- ✅ **Document Ingestion Extensions** (`api/src/services/document-ingestion-extensions.service.ts`)
- ✅ **Document Chunking Extensions** (`api/src/services/document-chunking-extensions.service.ts`)
- ✅ **Question Planning Extensions** (`api/src/services/question-planning-extensions.service.ts`)
- ✅ **Worker Pool Extensions** (`api/src/services/question-generation-worker-pool-extensions.service.ts`)

### API Endpoints (Completed)
- ✅ **Analyze Document** (`api/src/pages/api/v2/question-generator/analyze-document.ts`)
- ✅ **Process with Instructions** (`api/src/pages/api/v2/question-generator/process-with-instructions.ts`)
- ✅ **Clarify Instructions** (`api/src/pages/api/v2/question-generator/clarify-instructions.ts`)
- ✅ **Convert Legacy Questionnaire** (`api/src/pages/api/v2/question-generator/convert-legacy-questionnaire.ts`)

### Frontend Components (Completed)
- ✅ **useDocumentAttachment Hook** (`frontend/src/hooks/useDocumentAttachment.ts`)
- ✅ **ClarificationDialog Component** (`frontend/src/components/ClarificationDialog.tsx`)
- ✅ **DocumentAnalysisCard Component** (`frontend/src/components/DocumentAnalysisCard.tsx`)
- ✅ **Integration Example** (`frontend/src/components/AIAssistantChatEnhancedIntegration.tsx`)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                             │
├───────────────────────────────────────────────────────────────┤
│  Components:                                                  │
│  - AIAssistantChatEnhanced (existing, integrate with new)     │
│  - ClarificationDialog (new)                                  │
│  - DocumentAnalysisCard (new)                                 │
│                                                               │
│  Hooks:                                                       │
│  - useDocumentAttachment (new)                                │
└───────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      API Endpoints                            │
├───────────────────────────────────────────────────────────────┤
│  /api/v2/question-generator/                                  │
│  - analyze-document                                           │
│  - process-with-instructions                                  │
│  - clarify-instructions                                       │
│  - convert-legacy-questionnaire                               │
└───────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Backend Services                           │
├───────────────────────────────────────────────────────────────┤
│  Extended Services:                                           │
│  - DocumentIngestionService → DocumentIngestionExtensions     │
│  - DocumentChunkingService → DocumentChunkingExtensions       │
│  - QuestionPlanningService → QuestionPlanningExtensions       │
│  - WorkerPool → WorkerPoolExtensions                          │
│                                                               │
│  Utilities:                                                   │
│  - DocumentPatternDetector                                    │
│  - TeacherInstructionParser                                   │
└───────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                         Database                              │
├───────────────────────────────────────────────────────────────┤
│  Extended Models (already done):                              │
│  - DocumentIndex (added fields)                               │
│  - QuestionPlan (added fields)                                │
└───────────────────────────────────────────────────────────────┘
```

## Key Features Implemented

### 1. Document Type Detection
- **Automatic Classification**: Legacy questionnaire, learning material, lesson planner, mixed, or unknown
- **Pattern Recognition**: MCQ, True/False, Essay, Short Answer, Fill-in-blank questions
- **Confidence Scoring**: Provides confidence level for document type detection
- **Feature Detection**: Identifies objectives, schedules, answer keys, etc.

### 2. Teacher Instruction Processing
- **Natural Language Understanding**: Parses teacher instructions from messages
- **Priority System**: Explicit > Implicit > Inferred > Default
- **Conflict Detection**: Identifies conflicting instructions
- **Clarification Protocol**: Requests clarification when needed

### 3. Format Preservation
- **Structure Maintenance**: Preserves original document structure
- **Numbering Preservation**: Keeps original question numbering
- **Formatting Retention**: Maintains indentation and spacing
- **Selective Enhancement**: Can enhance while preserving key elements

### 4. Adaptive Processing
- **Document-Aware Chunking**: Different strategies for different document types
- **Question-Aware Processing**: Preserves question boundaries
- **Lesson-Aligned Generation**: Creates assessments aligned with objectives

## Usage Examples

### 1. Basic Document Analysis
```typescript
// In your component
const { analyzeDocument } = useDocumentAttachment();

// Analyze uploaded document
const analysis = await analyzeDocument(documentId);
console.log(`Document type: ${analysis.documentType}`);
console.log(`Confidence: ${analysis.confidence}`);
```

### 2. Process with Teacher Instructions
```typescript
const { processWithInstructions } = useDocumentAttachment();

// Process with natural language instruction
const result = await processWithInstructions(
  documentId,
  "Convert this questionnaire to online format while preserving the numbering",
  conversationContext
);

if (result.clarificationNeeded) {
  // Show clarification dialog
  showClarificationDialog(result.clarificationRequest);
}
```

### 3. Convert Legacy Questionnaire
```typescript
const { convertLegacyQuestionnaire } = useDocumentAttachment();

// Convert with specific options
const conversionResult = await convertLegacyQuestionnaire(documentId, {
  preserveFormatting: false,
  preserveNumbering: true,
  enhanceQuestions: true,
  addExplanations: true
});

console.log(`Converted ${conversionResult.questionsConverted} questions`);
```

### 4. Handle Clarification
```typescript
// When clarification is needed
<ClarificationDialog
  clarificationRequest={clarificationRequest}
  onSelection={(selection) => {
    // Resolve clarification
    resolveClarification(clarificationRequest.id, selection);
  }}
/>
```

## API Reference

### POST /api/v2/question-generator/analyze-document
Analyzes document type and suggests processing actions.

**Request:**
```json
{
  "documentId": "string",
  "extractedText": "string (optional)",
  "includePatterns": true
}
```

**Response:**
```json
{
  "success": true,
  "documentId": "string",
  "analysis": {
    "documentType": "legacy_questionnaire",
    "confidence": 0.92,
    "detectedFeatures": {...},
    "suggestedActions": [...]
  }
}
```

### POST /api/v2/question-generator/process-with-instructions
Processes document based on teacher instructions.

**Request:**
```json
{
  "documentId": "string",
  "userMessage": "string",
  "conversationContext": [],
  "preserveFormatting": false,
  "autoProcess": true
}
```

**Response:**
```json
{
  "success": true,
  "plan": {...},
  "clarificationNeeded": false,
  "clarificationRequest": {...}
}
```

### POST /api/v2/question-generator/clarify-instructions
Resolves clarification requests.

**Request:**
```json
{
  "clarificationId": "string",
  "selection": {
    "id": "string",
    "action": "string",
    "parameters": {}
  }
}
```

### POST /api/v2/question-generator/convert-legacy-questionnaire
Specifically converts legacy questionnaires.

**Request:**
```json
{
  "documentId": "string",
  "options": {
    "preserveFormatting": false,
    "preserveNumbering": true,
    "enhanceQuestions": true,
    "addExplanations": true
  }
}
```

## Integration Steps

### Step 1: Database Migration
The Prisma models have already been updated. Run migration:
```bash
cd api
npx prisma migrate dev --name add_document_attachment_fields
```

### Step 2: Import Extensions in Main Services
In your existing services, import the extensions:

```typescript
// In your existing document processing flow
import { DocumentIngestionExtensionsInstance } from './document-ingestion-extensions.service';

// Use the extensions
const analysis = await DocumentIngestionExtensionsInstance.detectDocumentType(
  documentId,
  extractedText,
  req
);
```

### Step 3: Integrate Frontend Components
In your existing AIAssistantChatEnhanced component:

```typescript
import { useDocumentAttachment } from '@/hooks/useDocumentAttachment';
import { ClarificationDialog } from '@/components/ClarificationDialog';
import { DocumentAnalysisCard } from '@/components/DocumentAnalysisCard';

// Use the hook
const {
  documentAnalysis,
  clarificationRequest,
  analyzeDocument,
  processWithInstructions,
  resolveClarification
} = useDocumentAttachment();

// Add to your component JSX
{documentAnalysis && (
  <DocumentAnalysisCard
    analysis={documentAnalysis}
    onActionClick={handleActionClick}
  />
)}

{clarificationRequest && (
  <ClarificationDialog
    clarificationRequest={clarificationRequest}
    onSelection={handleClarificationSelection}
  />
)}
```

## Testing the Implementation

### 1. Test Document Type Detection
```typescript
// Test with a sample questionnaire
const testText = `
1. What is the capital of France?
   a) London
   b) Paris
   c) Berlin
   d) Madrid
   
2. True or False: The Earth is flat.

Answer Key:
1. B
2. False
`;

const patterns = DocumentPatternDetector.detectQuestionPatterns(testText);
console.log(`Found ${patterns.length} questions`);
```

### 2. Test Teacher Instruction Parsing
```typescript
const instructions = TeacherInstructionParser.parseInstructions(
  "Convert this to an online quiz with 10 multiple choice questions"
);

const prioritized = TeacherInstructionParser.prioritizeInstructions(instructions);
console.log(`Primary instruction: ${prioritized.primary.instruction}`);
```

### 3. Test Clarification Flow
```typescript
// Simulate conflicting instructions
const result = await processWithInstructions(
  documentId,
  "Convert to online but preserve the format", // Conflicting!
  []
);

if (result.clarificationNeeded) {
  console.log("Clarification options:", result.clarificationRequest.options);
}
```

## Performance Considerations

1. **Caching**: Document analysis results are stored in database
2. **Chunking**: Adaptive chunking based on document type
3. **Progress Tracking**: Uses existing SSE/WebSocket infrastructure
4. **Queue Management**: Uses existing BullMQ system

## Security Considerations

1. **Input Validation**: All endpoints validate input with Zod
2. **Tenant Isolation**: Uses existing tenant-aware Prisma client
3. **File Security**: Leverages existing document security measures
4. **Rate Limiting**: Should use existing rate limiting infrastructure

## Troubleshooting

### Issue: Document type not detected correctly
**Solution**: Check if the document has clear patterns. May need manual specification.

### Issue: Clarification dialog appears too often
**Solution**: Provide clearer instructions or use suggested actions.

### Issue: Questions not preserving format
**Solution**: Explicitly set `preserveFormatting: true` in options.

### Issue: Processing takes too long
**Solution**: Document is queued in existing system. Check worker pool status.

## Next Steps

1. **Testing**: Comprehensive testing with real teacher documents
2. **Optimization**: Fine-tune pattern detection algorithms
3. **ML Enhancement**: Add ML-based document classification
4. **User Feedback**: Collect teacher feedback for improvements
5. **Documentation**: Create user-facing documentation

## Support

For issues or questions about the implementation:
1. Check the individual service files for detailed comments
2. Review the API endpoint documentation
3. Test with the provided example components
4. Check existing Gabay documentation for context

---

**Implementation Complete**: All components are ready for integration and testing.
