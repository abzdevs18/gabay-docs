# AI Artifacts Integration Guide - Complete Implementation

## Overview

This comprehensive guide details the complete implementation of the AI Artifacts system in the Gabay platform. The system provides a ChatGPT/Claude-style experience where AI generates both conversational responses AND structured artifacts (like question previews) that appear in a dedicated preview panel.

## Recent Updates (2025-09-25)

### Fixed Issues:
1. **Preview Panel Timing**: The Artifacts preview panel now only shows when the AI actually calls the `previewQuestions` tool, not immediately after sending a message.
2. **Real-time Streaming**: Questions now stream character-by-character in real-time for a smoother user experience.
3. **UX Improvements**: Loading and completion states now match the expected behavior with proper visual indicators.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI Artifacts System Architecture             │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Components          │  Backend Services               │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐    │
│  │ AIAssistantChatEnhanced │  │  │ /api/v2/ai/chat         │    │
│  │ - Intent Detection      │  │  │ - Tool Definitions      │    │
│  │ - Tool Call Integration │  │  │ - System Prompts        │    │
│  │ - Streaming Handler     │  │  │ - SSE Streaming         │    │
│  │ - Artifact Rendering    │  │  │ - Tool Call Processing  │    │
│  └─────────────────────────┘  │  └─────────────────────────┘    │
│  ┌─────────────────────────┐  │                                 │
│  │ useAIToolCalls Hook     │  │                                 │
│  │ - Tool Call Processing  │  │                                 │
│  │ - State Management      │  │                                 │
│  │ - Question Conversion   │  │                                 │
│  └─────────────────────────┘  │                                 │
│  ┌─────────────────────────┐  │                                 │
│  │ AIStreamingHandler      │  │                                 │
│  │ - SSE Processing        │  │                                 │
│  │ - Tool Call Detection   │  │                                 │
│  │ - Content Streaming     │  │                                 │
│  └─────────────────────────┘  │                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Core Files and Components

### Backend Files

#### 1. `/api/src/pages/api/v2/ai/chat.ts`
**Purpose**: Main AI chat endpoint with tool calling support
**Key Features**:
- Tool definitions for `previewQuestions`
- System prompt configuration
- SSE streaming with tool call processing
- Context management (documents, conversation history)

**Tool Definition**:
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
              question: { type: "string" },
              options: { type: "array", items: { type: "string" } },
              answer: { type: "string" },
              explanation: { type: "string" }
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

**System Prompt Configuration**:
```typescript
Educational Task Behavior:
- When explicitly asked to generate questions/quizzes/tests:
  • Provide a conversational response first (e.g., "I'll create a 5-item math quiz...")
  • THEN call the previewQuestions tool with structured JSON data
  • This creates a ChatGPT/Claude-style experience with both conversation and artifacts
```

### Frontend Files

#### 1. `/frontend/src/components/AIAssistantChatEnhanced.tsx`
**Purpose**: Main chat component with artifacts integration
**Key Features**:
- Natural Language Processing for intent detection
- Tool call integration in `question_generation` case
- Loading states for artifacts
- Message bubble rendering with preview cards

**Intent Detection**:
```typescript
const processNaturalLanguageRequest = useCallback((message: string): NLPResult => {
  const lowerMessage = message.toLowerCase();
  
  // Question generation patterns
  const questionPatterns = [
    /\b(?:generat|creat|make|build|design)\w*\s+(?:\d+\s+)?(?:question|quiz|test|assessment|exam)/i,
    /\b(?:question|quiz|test|assessment|exam)\w*\s+(?:generat|creat|make|build)/i,
    /\b\d+\s+(?:item|question)s?\b/i
  ];
  
  for (const pattern of questionPatterns) {
    if (pattern.test(message)) {
      return {
        intent: 'question_generation',
        parameters: extractGenerationParams(message),
        confidence: 0.9
      };
    }
  }
  // ... other intents
});
```

**Tool Call Integration**:
```typescript
case 'question_generation': {
  // ... configuration logic ...
  
  // Use AI tool calling for question generation
  const assistantId = `msg_${Date.now() + 1}`;
  const assistantMessage: EnhancedMessage = {
    id: assistantId,
    type: 'assistant',
    timestamp: new Date()
  };
  setMessages(prev => [...prev, assistantMessage]);
  setStreamingMessageId(assistantId);

        // DO NOT show preview panel immediately - wait for tool call
        // The preview panel will be shown when the AI calls the previewQuestions tool

  const readyDocs = attachments.filter(att => att.processing_status === 'ready' && att.document_id);
  
  // Use enhanced streaming with tool support for question generation
  await AIStreamingHandler.streamWithTools({
{{ ... }}
      }
    }),
    onContent: (content) => {
      console.log('[Component Debug] Streaming content:', content);
      setMessages(prev => prev.map(m => m.id === assistantId ? { ...m, content: m.content + content } : m));
    },
    onToolCall: (toolName, args, isPartial) => { 
      console.log('[Component Debug] Tool call received:', toolName, 'isPartial:', isPartial); 
      if (toolName === 'previewQuestions') {
        // Only set preview source when tool is actually called
        setPreviewSourceMessageId(assistantId);
      }
      handleToolCall(toolName, args, isPartial); 
    },
    onComplete: () => {
      setStreamingMessageId(null);
    },
    onError: (error) => {
      console.error('Streaming error with tools:', error);
      setStreamingMessageId(null);
    }
  });

  break;
}
```

**Loading State Implementation**:
```typescript
const MessageBubble = memo(({ message, isStreaming, hideQuestions, onTogglePreview }) => {
  const isAssistant = message.type === 'assistant';
  const { hasStructuredContent, beforeStructured, afterStructured } = detectAndSplitContent(message.content);
  const shouldShowSplit = isAssistant && (hasStructuredContent || generatedQuestions.length > 0 || (isStreaming && showPreview)) && hideQuestions;

  return (
    // ... message structure ...
    {shouldShowSplit && (
      <div className="bg-green-50 border border-green-200 rounded-lg p-2 sm:p-3 cursor-pointer hover:bg-green-100 transition-colors"
           onClick={onTogglePreview}>
        <div className="flex items-center gap-2 sm:gap-3">
          {!isStreaming ? (
            <div className="w-5 h-5 sm:w-6 sm:h-6 bg-green-500 rounded-full flex items-center justify-center">
              <Check className="w-3 h-3 sm:w-4 sm:h-4 text-white" />
            </div>
          ) : (
            <div className="w-5 h-5 sm:w-6 sm:h-6 border-2 border-green-500 border-t-transparent rounded-full animate-spin"></div>
          )}
          <div className="flex-1">
            <div className="text-xs sm:text-sm font-medium text-green-900">
              {!isStreaming ? 'Worksheet Preview Available' : 'Generating Worksheet Preview'}
            </div>
            <div className="text-xs text-green-700">
              {!isStreaming ? 'Click to toggle preview panel!' : 'Processing questions...'}
            </div>
          </div>
        </div>
      </div>
    )}
  );
});
```

#### 2. `/frontend/src/hooks/useAIToolCalls.tsx`
**Purpose**: React hook for managing AI tool calls
**Key Features**:
- Tool call processing and state management
- Question format conversion
- Callback handling for UI updates

```typescript
export const useAIToolCalls = (
  onQuestionsGenerated?: (questions: Question[]) => void,
  onPreviewShow?: () => void
) => {
  const [toolCalls, setToolCalls] = useState<ToolCallResult[]>([]);
  const [isProcessingTool, setIsProcessingTool] = useState(false);

  const convertToQuestions = useCallback((args: PreviewQuestionsArgs): Question[] => {
    return args.questions.map((q, idx) => {
      const typeMap: Record<string, Question['type']> = {
        'multiple_choice': 'MULTIPLE_CHOICE',
        'true_false': 'TRUE_OR_FALSE',
        'essay': 'ESSAY',
        'short_answer': 'IDENTIFICATION',
        'fill_blank': 'FILLINBLANK'
      };

      const type = typeMap[q.type] || 'MULTIPLE_CHOICE';
      
      let choices: Array<{ id: string; value: string; isCorrect?: boolean }> | undefined;
      
      if (q.options && q.options.length > 0) {
        choices = q.options.map((opt, i) => ({
          id: String.fromCharCode(97 + i),
          value: opt,
          isCorrect: q.answer === opt || q.answer === String.fromCharCode(65 + i)
        }));
      } else if (type === 'TRUE_OR_FALSE') {
        choices = [
          { id: 'a', value: 'True', isCorrect: q.answer?.toLowerCase() === 'true' },
          { id: 'b', value: 'False', isCorrect: q.answer?.toLowerCase() === 'false' }
        ];
      }

      return {
        id: `q_${idx + 1}`,
        type,
        title: q.question,
        choices,
        correctAnswer: q.answer,
        explanation: q.explanation
      };
    });
  }, []);

  const handleToolCall = useCallback((toolName: string, args: any) => {
    console.log('[AI Tool Call]', toolName, args);
    
    const toolCall: ToolCallResult = {
      name: toolName,
      arguments: args,
      timestamp: new Date()
    };
    
    setToolCalls(prev => [...prev, toolCall]);
    setIsProcessingTool(true);

    // Handle specific tool
    if (toolName === 'previewQuestions' && args) {
      const questionsArgs = args as PreviewQuestionsArgs;
      
      // Convert to Question format
      const questions = convertToQuestions(questionsArgs);
      
      // Notify parent component
      if (onQuestionsGenerated) {
        onQuestionsGenerated(questions);
      }
      
      // Show preview
      if (onPreviewShow) {
        onPreviewShow();
      }
      
      console.log('[Preview Questions Generated]', questions.length, 'questions');
    }
    
    setIsProcessingTool(false);
  }, [convertToQuestions, onQuestionsGenerated, onPreviewShow]);

  return {
    toolCalls,
    isProcessingTool,
    handleToolCall,
    clearToolCalls: useCallback(() => setToolCalls([]), [])
  };
};
```

#### 3. `/frontend/src/utils/ai-streaming-handler.ts`
**Purpose**: Enhanced streaming handler with tool call support
**Key Features**:
- SSE stream processing
- Tool call detection and parsing
- Content and tool call separation

```typescript
export interface StreamHandlerOptions {
  endpoint: string;
  method?: 'GET' | 'POST';
  body?: string;
  headers?: Record<string, string>;
  onContent: (content: string) => void;
  onToolCall?: (toolName: string, args: any) => void;
  onComplete?: () => void;
  onError?: (error: Error) => void;
}

export class AIStreamingHandler {
  private static parseSSEData(line: string): any | null {
    if (!line.startsWith('data: ')) return null;
    
    const dataStr = line.slice(6).trim();
    if (dataStr === '[DONE]') return { done: true };
    
    try {
      return JSON.parse(dataStr);
    } catch (e) {
      console.warn('Failed to parse SSE data:', dataStr);
      return null;
    }
  }

  static async streamWithTools(options: StreamHandlerOptions): Promise<void> {
    const { endpoint, method = 'GET', body, headers = {}, onContent, onToolCall, onComplete, onError } = options;
    
    try {
      const fetchOptions: RequestInit = {
        method,
        headers: {
          'Accept': 'text/event-stream',
          ...headers,
        },
      };
      
      if (body && method === 'POST') {
        fetchOptions.body = body;
        fetchOptions.headers = {
          ...fetchOptions.headers,
          'Content-Type': 'application/json',
        };
      }
      
      const response = await fetch(endpoint, fetchOptions);

      if (!response.ok || !response.body) {
        throw new Error(`Stream error: ${response.status} ${response.statusText}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      let currentToolCall: any = null;
      let toolCallBuffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;

          const data = this.parseSSEData(trimmed);
          console.log("[SSE Debug] Parsed data:", data);
          if (!data) continue;
          if (data.done) {
            onComplete?.();
            return;
          }

          const delta = data.choices?.[0]?.delta;
          if (!delta) continue;

          // Handle regular content
          if (delta.content) {
            onContent(delta.content);
          }

          // Handle tool calls
          if (delta.tool_calls && onToolCall) {
            console.log("[Tool Call Debug] Received tool calls:", delta.tool_calls);
            for (const toolCall of delta.tool_calls) {
              if (toolCall.function?.name) {
                // New tool call starting
                currentToolCall = {
                  id: toolCall.id,
                  name: toolCall.function.name
                };
                toolCallBuffer = toolCall.function.arguments || '';
              } else if (toolCall.function?.arguments) {
                // Accumulate arguments
                toolCallBuffer += toolCall.function.arguments;
              }

              // Try to parse complete tool call
              if (currentToolCall && toolCallBuffer) {
                try {
                  const args = JSON.parse(toolCallBuffer);
                  console.log("[Tool Call Debug] Executing tool call:", currentToolCall.name, args);
                  onToolCall(currentToolCall.name, args);
                  currentToolCall = null;
                  toolCallBuffer = '';
                } catch {
                  // Not complete yet, continue accumulating
                }
              }
            }
          }
        }
      }

      // Handle any remaining tool call
      if (currentToolCall && toolCallBuffer && onToolCall) {
        try {
          const args = JSON.parse(toolCallBuffer);
          console.log("[Tool Call Debug] Executing tool call:", currentToolCall.name, args);
          onToolCall(currentToolCall.name, args);
        } catch (e) {
          console.warn('Failed to parse final tool call:', e);
        }
      }

      onComplete?.();
    } catch (error) {
      onError?.(error as Error);
    }
  }
}
```

## Data Flow and Process

### 1. User Request Flow
```
User Input → Intent Detection → Question Generation Case → Tool Call Setup → AI Processing
     ↓              ↓                    ↓                    ↓              ↓
"Create 5 math    question_generation   Show loading        POST to        AI generates
questions"        intent detected       state immediately   /api/v2/ai/chat response + tool call
```

### 2. AI Response Flow
```
AI Response → SSE Stream → Content + Tool Call → Frontend Processing → UI Update
     ↓           ↓              ↓                    ↓                ↓
Conversational  Streaming    Content goes to      Tool call        Preview panel
response +      chunks       message bubble       processed by     shows questions
tool call                                         handleToolCall   with loading states
```

### 3. Tool Call Processing Flow
```
Tool Call Received → JSON Parsing → Question Conversion → State Update → UI Rendering
        ↓                ↓               ↓                  ↓             ↓
previewQuestions    Parse arguments   Convert to internal  Update        Show artifact
tool detected       JSON structure    Question format      generated     with questions
                                                          questions
```

## Configuration and Setup

### Environment Variables
```bash
# Backend
OPENAI_API_KEY=your_openai_key
DEEPSEEK_API_KEY=your_deepseek_key  # Alternative provider
OPENAI_CHAT_MODEL=gpt-4o-mini       # Optional, defaults to gpt-4o-mini

# Frontend
BASE_URL=http://localhost:3001       # Backend URL
```

### System Prompt Configuration
The system prompt in `/api/v2/ai/chat.ts` is configured to:
1. Detect question generation requests
2. Provide conversational responses first
3. Call the `previewQuestions` tool with structured data
4. Handle both document-based and text-based question generation

### Tool Call Triggers
The AI is instructed to use tool calls when:
- User explicitly asks to generate questions/quizzes/tests
- Request contains patterns like "create X questions", "generate quiz", etc.
- Context includes uploaded documents for question generation

## Integration Steps

### Step 1: Backend Setup
1. Ensure `/api/src/pages/api/v2/ai/chat.ts` has the `previewQuestions` tool definition
2. Configure system prompt for tool calling behavior
3. Set up environment variables for AI providers

### Step 2: Frontend Integration
1. Import required components and hooks in `AIAssistantChatEnhanced.tsx`
2. Add the `useAIToolCalls` hook with proper callbacks
3. Integrate tool calling in the `question_generation` case
4. Ensure loading states are properly configured

### Step 3: Message Rendering
1. Update `MessageBubble` component to show loading/completion states
2. Loading state shows spinning indicator with "Generating Worksheet Preview"
3. Completion state shows checkmark with "Worksheet Preview Available"
4. Eye icon appears only in completion state

### Step 4: State Management
1. Configure `showPreview` state to show immediately on question requests
2. Clear `generatedQuestions` to show loading state
3. Update questions when tool call completes

## User Experience Flow

### 1. Question Request
```
User: "Create a 5 item quiz for Grade 8 chemistry"
```

### 2. Immediate Response
- Intent detected as `question_generation`
- AI response begins streaming
- Preview panel ONLY appears when AI calls the `previewQuestions` tool
- Loading card shows "Generating Worksheet Preview - Processing questions..."

### 3. AI Streaming Response
- Conversational text streams first
- When AI decides to generate questions, it calls the `previewQuestions` tool
- Tool call triggers preview panel appearance with loading state
- Questions stream character-by-character in real-time

### 4. Completion State
- Loading spinner changes to green checkmark
- Message shows "Worksheet Preview Available - Click to toggle preview panel!"
- Questions populate the preview panel
- User can save, print, or modify questions

## Debugging and Troubleshooting

### Console Logs to Monitor
```javascript
// Tool call detection
[AI Tool Call] previewQuestions {questions: [...], metadata: {...}}

// Content streaming
[Component Debug] Streaming content: "I'll create a 5-item chemistry quiz..."

// Tool call processing
[Component Debug] Tool call received: previewQuestions {...}

// Question generation
[Preview Questions Generated] 5 questions

// SSE debugging
[SSE Debug] Parsed data: {choices: [...]}
[Tool Call Debug] Received tool calls: [...]
```

### Common Issues and Solutions

1. **Tool calls not working**
   - Check console for `[AI Tool Call]` logs
   - Verify `ackOnly: false` in request context
   - Ensure backend has tool definitions

2. **Preview showing too early**
   - Ensure preview panel is only shown when tool call is received
   - Check that `setPreviewSourceMessageId` is called in the `onToolCall` callback
   - Verify that `setShowPreview(true)` is called in the `handleToolCall` function

2. **Duplicate messages**
   - Verify tool calling logic is only in `question_generation` case
   - Remove duplicate streaming calls from `default` case

3. **Loading states not showing**
   - Check that `isToolCallActive` state is properly managed
   - Ensure tool call handler sets this state correctly
   - Verify the MessageBubble checks both `isToolCallActive` and question count

4. **Questions not populating preview**
   - Check `handleToolCall` is connected to streaming handler
   - Verify question conversion logic in `useAIToolCalls`
   - Ensure `onQuestionsGenerated` callback is working

### Performance Considerations

1. **Memory Management**
   - Tool calls are stored in component state
   - Clear tool calls when appropriate using `clearToolCalls()`
   - Limit conversation history to last 8 messages

2. **Network Optimization**
   - Use SSE streaming for real-time updates
   - Throttle content updates to avoid excessive re-renders
   - Implement proper error handling and timeouts

3. **UI Responsiveness**
   - Show loading states immediately
   - Use proper React memo for message components
   - Implement smooth transitions for state changes

## Future Enhancements

### Planned Features
1. **Multiple Tool Support**: Add tools for different content types (diagrams, charts, etc.)
2. **Real-time Collaboration**: Share artifacts between users
3. **Export Functionality**: Export artifacts to various formats (PDF, Word, etc.)
4. **Template System**: Predefined question templates and formats
5. **Analytics Integration**: Track artifact usage and effectiveness

### Extension Points
- **New Artifact Types**: Add support for different educational content
- **Custom Renderers**: Create specialized renderers for different domains
- **Integration APIs**: Connect with external assessment platforms
- **AI Model Support**: Add support for additional AI providers (Claude, Gemini, etc.)

## Conclusion

The AI Artifacts system provides a modern, ChatGPT/Claude-style experience for educational content generation. By leveraging OpenAI's tool calling capabilities, structured data handling, and real-time streaming, the system delivers an intuitive and powerful interface for creating educational assessments.

The implementation is designed to be extensible, maintainable, and performant, providing a solid foundation for future enhancements and integrations.
