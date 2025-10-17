# AI Chat Artifacts System Documentation

## Overview

The AI Chat Artifacts system implements a Canvas/Artifacts-style workflow for smooth question previewing using OpenAI's tool calling pattern. This system transforms the traditional text-based question generation into a structured, interactive experience with visual artifacts.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI Chat Artifacts System                     │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Components          │  Backend Services               │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐    │
│  │ AIAssistantChatEnhanced │  │  │ /api/v2/ai/chat         │    │
│  │ - Tool Call Integration │  │  │ - Tool Definitions      │    │
│  │ - Streaming Handler     │  │  │ - SSE Streaming         │    │
│  │ - Artifact Rendering    │  │  │ - Tool Call Processing  │    │
│  └─────────────────────────┘  │  └─────────────────────────┘    │
│  ┌─────────────────────────┐  │                                 │
│  │ QuestionPreviewArtifact │  │                                 │
│  │ - Visual Question Cards │  │                                 │
│  │ - Metadata Display      │  │                                 │
│  │ - Auto-conversion       │  │                                 │
│  └─────────────────────────┘  │                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Backend Implementation (`api/src/pages/api/v2/ai/chat.ts`)

#### Tool Definition
The `previewQuestions` tool is defined with a comprehensive JSON schema:

```typescript
const tools = [{
  type: "function",
  function: {
    name: "previewQuestions",
    description: "Preview the generated questions in a structured format",
    parameters: {
      type: "object",
      properties: {
        questions: {
          type: "array",
          items: {
            type: "object",
            properties: {
              type: { 
                type: "string",
                enum: ["multiple_choice", "true_false", "essay", "short_answer", "fill_blank"]
              },
              question: { type: "string", description: "The question text" },
              options: { 
                type: "array", 
                items: { type: "string" },
                description: "Options for multiple choice questions"
              },
              answer: { type: "string", description: "The correct answer" },
              explanation: { type: "string", description: "Explanation of the answer" }
            },
            required: ["type", "question"]
          }
        },
        metadata: {
          type: "object",
          properties: {
            subject: { type: "string" },
            gradeLevel: { type: "string" },
            difficulty: { type: "string" },
            topic: { type: "string" }
          }
        }
      },
      required: ["questions"]
    }
  }
}];
```

#### System Prompt Integration
The AI is instructed to use the tool for question generation:

```
Educational Task Behavior:
- When explicitly asked to generate questions/quizzes/tests:
  • ALWAYS call the previewQuestions tool with structured JSON data
  • Include all questions in a single tool call for better preview experience
  • The tool automatically handles formatting and preview rendering
  • Include metadata (subject, grade level, difficulty, topic) when available
  • Tool call format enables automatic preview panel population
```

#### Tool Call Streaming
Enhanced SSE streaming to handle tool calls alongside content:

```typescript
// Handle tool calls in streaming response
if (delta?.tool_calls) {
  for (const toolCall of delta.tool_calls) {
    if (toolCall.function?.name) {
      currentToolCall = toolCall;
      toolCallBuffer = toolCall.function?.arguments || '';
    } else if (toolCall.function?.arguments) {
      toolCallBuffer += toolCall.function.arguments;
    }
    
    // Try to parse complete tool call
    if (currentToolCall && toolCallBuffer) {
      try {
        const args = JSON.parse(toolCallBuffer);
        flushToolCall({
          ...currentToolCall,
          function: {
            ...currentToolCall.function,
            arguments: JSON.stringify(args)
          }
        });
      } catch {
        // Continue accumulating
      }
    }
  }
}
```

### 2. Frontend Components

#### A. AIAssistantChatEnhanced Integration

**Tool Call Hook Integration:**
```typescript
// Tool call hook for handling AI tool calls
const { handleToolCall, toolCalls } = useAIToolCalls(
  (questions) => {
    // Auto-populate the preview panel
    setGeneratedQuestions(questions);
    setShowPreview(true);
  },
  () => {
    // Show preview panel
    setShowPreview(true);
  }
);
```

**Enhanced Streaming Handler:**
```typescript
// Use new tool calling streaming handler
await AIStreamingHandler.streamWithTools({
  endpoint: `/api/v2/ai/chat?query=${encodeURIComponent(originalMessage)}`,
  onContent: (content) => {
    // Handle regular content streaming
  },
  onToolCall: handleToolCall, // Handle previewQuestions tool
  onComplete: () => {
    setStreamingMessageId(null);
  },
  onError: (error) => {
    console.error('Streaming error:', error);
  }
});
```

#### B. QuestionPreviewArtifact Component

A specialized React component that renders questions as interactive cards:

**Features:**
- **Visual Question Cards**: Each question is displayed in a styled card format
- **Metadata Badges**: Shows subject, grade level, difficulty as badges
- **Type Indicators**: Color-coded badges for different question types
- **Answer Highlighting**: Correct answers are visually highlighted
- **Expandable/Collapsible**: Users can expand or collapse the artifact
- **Auto-conversion**: Automatically converts tool call data to preview format

**Example Usage:**
```typescript
<QuestionPreviewArtifact
  questions={toolCall.arguments.questions}
  metadata={toolCall.arguments.metadata}
  onQuestionsConverted={(questions) => {
    setGeneratedQuestions(questions);
  }}
/>
```

#### C. useAIToolCalls Hook

A React hook that manages tool call processing:

```typescript
export const useAIToolCalls = (
  onQuestionsGenerated?: (questions: Question[]) => void,
  onPreviewShow?: () => void
) => {
  const [toolCalls, setToolCalls] = useState<ToolCallResult[]>([]);
  
  const handleToolCall = useCallback((toolName: string, args: any) => {
    if (toolName === 'previewQuestions' && args) {
      const questions = convertToQuestions(args);
      onQuestionsGenerated?.(questions);
      onPreviewShow?.();
    }
  }, []);
  
  return { toolCalls, handleToolCall };
};
```

#### D. AIStreamingHandler Utility

Enhanced streaming handler with tool call support:

```typescript
export class AIStreamingHandler {
  static async streamWithTools(options: StreamHandlerOptions): Promise<void> {
    // Handle SSE streaming with tool call parsing
    // Accumulate partial JSON for tool arguments
    // Trigger callbacks for content and tool calls
  }
}
```

## Data Flow

### 1. Question Generation Request Flow

```
User Request → NLP Processing → AI Chat Endpoint → Tool Call → Artifact Rendering
     ↓              ↓               ↓              ↓            ↓
"Generate 5     Extract params   AI generates   Tool call    Question cards
 math questions" → count=5,       structured     with JSON   → displayed in
                   type=math      questions      data        → preview panel
```

### 2. Tool Call Processing Flow

```
AI Response Stream → Tool Call Detection → JSON Accumulation → Tool Execution → UI Update
        ↓                    ↓                   ↓                ↓             ↓
SSE chunks with    Parse tool call      Build complete      Execute         Update preview
tool_calls data → name & arguments   → JSON arguments   → handleToolCall → panel with cards
```

## Benefits Achieved

### ✅ **Structured Data Output**
- **Before**: AI generated plain text that required complex parsing
- **After**: AI outputs structured JSON via tool calls, eliminating parsing errors

### ✅ **Visual Artifact Rendering**
- **Before**: Questions appeared as plain text in chat
- **After**: Questions render as beautiful, interactive cards with metadata

### ✅ **Automatic Preview Population**
- **Before**: Manual preview generation with potential parsing failures  
- **After**: Automatic preview panel population when tool is called

### ✅ **Type Safety**
- **Before**: String parsing with potential runtime errors
- **After**: TypeScript interfaces ensure data consistency

### ✅ **Enhanced User Experience**
- **Before**: Static text-based interaction
- **After**: Canvas/Artifacts-style interactive experience

### ✅ **Extensibility**
- **Before**: Hard to add new question formats
- **After**: Easy to extend with new tools and artifact types

## Usage Examples

### Basic Question Generation
```
User: "Generate 5 multiple choice questions about algebra"

AI Response:
1. Regular chat content: "I'll create 5 algebra questions for you..."
2. Tool Call: previewQuestions({
     questions: [
       {
         type: "multiple_choice",
         question: "What is the value of x in 2x + 5 = 15?",
         options: ["5", "10", "7.5", "15"],
         answer: "5",
         explanation: "Subtract 5 from both sides: 2x = 10, then divide by 2: x = 5"
       },
       // ... more questions
     ],
     metadata: {
       subject: "Mathematics",
       topic: "Algebra", 
       gradeLevel: "Grade 8",
       difficulty: "intermediate"
     }
   })
3. Artifact Rendering: Questions appear as interactive cards
4. Preview Panel: Auto-populates with formatted questions
```

### Document-Based Generation
```
User uploads document + "Create questions from this document"

AI Response:
1. Analyzes document content
2. Calls previewQuestions tool with document-based questions
3. Includes metadata extracted from document
4. Renders artifact with source attribution
```

## Technical Implementation Details

### Tool Call Detection
The system detects tool calls in the SSE stream:

```typescript
if (delta?.tool_calls) {
  for (const toolCall of delta.tool_calls) {
    if (toolCall.function?.name === 'previewQuestions') {
      // Process the tool call
      const args = JSON.parse(toolCall.function.arguments);
      handleToolCall('previewQuestions', args);
    }
  }
}
```

### Question Type Mapping
Tool call question types are mapped to internal formats:

```typescript
const typeMap: Record<string, Question['type']> = {
  'multiple_choice': 'MULTIPLE_CHOICE',
  'true_false': 'TRUE_OR_FALSE',
  'essay': 'ESSAY',
  'short_answer': 'IDENTIFICATION',
  'fill_blank': 'FILLINBLANK'
};
```

### Artifact Rendering Logic
Questions are rendered with appropriate UI components based on type:

```typescript
// Multiple choice questions show options with correct answer highlighting
// Essay questions show text areas
// True/false questions show binary options
// Fill-in-blank questions show input fields
```

## Configuration

### Environment Variables
- `OPENAI_API_KEY`: Required for OpenAI provider
- `DEEPSEEK_API_KEY`: Required for DeepSeek provider

### Tool Configuration
Tools are automatically registered in the chat endpoint. No additional configuration needed.

### Frontend Integration
Import and use the components:

```typescript
import QuestionPreviewArtifact from './QuestionPreviewArtifact';
import { useAIToolCalls } from '../hooks/useAIToolCalls';
import { AIStreamingHandler } from '../utils/ai-streaming-handler';
```

## Troubleshooting

### Common Issues

1. **Tool calls not working**
   - Check console for `[AI Tool Call]` logs
   - Verify backend tool definition is correct
   - Ensure `ackOnly: false` for question generation

2. **Artifacts not rendering**
   - Verify `QuestionPreviewArtifact` is imported
   - Check tool call handler is connected
   - Ensure questions array is properly formatted

3. **Preview panel not updating**
   - Verify `onQuestionsGenerated` callback is working
   - Check `setGeneratedQuestions` is being called
   - Ensure `setShowPreview(true)` is triggered

### Debug Logging
Enable debug logging to trace tool call flow:

```typescript
console.log('[AI Tool Call]', toolName, args);
console.log('[Preview Questions Generated]', questions.length, 'questions');
```

## Future Enhancements

### Planned Features
1. **Multiple Tool Support**: Add tools for different content types
2. **Real-time Collaboration**: Share artifacts between users
3. **Export Functionality**: Export artifacts to various formats
4. **Template System**: Predefined question templates
5. **Analytics Integration**: Track artifact usage and effectiveness

### Extension Points
- **New Artifact Types**: Add support for diagrams, charts, etc.
- **Custom Renderers**: Create specialized renderers for different domains
- **Integration APIs**: Connect with external assessment platforms
- **AI Model Support**: Add support for additional AI providers

## Conclusion

The AI Chat Artifacts system successfully transforms traditional text-based AI interactions into rich, interactive experiences. By leveraging OpenAI's tool calling pattern, we've created a robust, extensible system that provides immediate visual feedback and structured data handling.

The system eliminates the complexity of text parsing while providing a modern, Canvas-like user experience that scales well for educational applications and beyond.