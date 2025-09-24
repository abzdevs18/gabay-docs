const memories = {
  data: [
    {
      score: 95,
      Content: `## Gabay Form Service - Core Architecture

### Overview
The Gabay Form Service is a comprehensive form management system built with Next.js and React, designed for educational assessments and general form creation. It features dynamic form building, real-time collaboration, and integration with assessment systems.

### Entry Points
1. **Dynamic Public Route**: \`/forms/[slug].tsx\` - Public form submission interface with server-side rendering
2. **Form Builder**: \`/lms/forms/builder/[id].tsx\` - Interactive form creation/editing interface  
3. **Form Dashboard**: \`/lms/forms/index.tsx\` - Form management and analytics dashboard

### Core Services Architecture

#### GabayFormService (\`gabay-form.service.ts\`)
- **Pattern**: Static methods with instance wrapper for flexibility
- **API Base**: \`\${process.env.BASE_URL}/api/v1/gabay-forms\`
- **Key Methods**:
  - CRUD Operations: \`createForm()\`, \`getForm()\`, \`updateForm()\`, \`deleteForm()\`
  - Response Management: \`submitResponse()\`, \`getResponses()\`
  - Analytics: \`getFormAnalytics()\`, \`getAnalyticsSummary()\`
  - Status Management: \`publishForm()\`, \`unpublishForm()\`
  - Assessment Integration: \`linkFormToAssessments()\`, \`getAssessmentConfigs()\`
  - Form Duplication: \`duplicateForm()\`, \`cloneForm()\`

### API Endpoints
- \`GET /api/v1/gabay-forms/\` - List forms
- \`POST /api/v1/gabay-forms/create\` - Create new form
- \`GET /api/v1/gabay-forms/[id]\` - Get specific form
- \`PUT /api/v1/gabay-forms/[id]\` - Update form
- \`DELETE /api/v1/gabay-forms/[id]\` - Delete form
- \`POST /api/v1/gabay-forms/[id]/publish\` - Publish form
- \`POST /api/v1/gabay-forms/[id]/unpublish\` - Unpublish form
- \`POST /api/v1/gabay-forms/[id]/duplicate\` - Duplicate form
- \`GET /api/v1/gabay-forms/[id]/responses\` - Get form responses
- \`GET /api/v1/gabay-forms/[id]/analytics\` - Get form analytics
- \`GET /api/v1/gabay-forms/public/[slug]\` - Public form access
- \`GET /api/v1/gabay-forms/check-slug/[slug]\` - Check slug availability

### Schema Transformation Pattern
\`\`\`typescript
// API expects nested schema structure
const transformedUpdates = {
  ...otherFields,
  schema: {
    sections: form.sections,
    settings: form.settings,
    theme: form.theme
  },
  theme: form.theme // Keep theme at root level
};
\`\`\``
    },
    {
      score: 90,
      Content: `## AI Chat Question Generator - Enhanced Architecture

### Overview
The AI Chat Question Generator is an advanced system for creating educational questions from various content sources including documents, videos, and existing questionnaires. It features real-time progress tracking and integration with the Gabay Form Service.

### Core Components
1. **AIAssistantChatEnhanced** - Main UI component for question generation
2. **QuestionGeneratorClientService** - Frontend service for API integration
3. **QuestionPlanningService** - Backend service for creating question generation plans
4. **QuestionGenerationWorkerPool** - Backend service for distributed question generation
5. **DocumentChunkingService** - Backend service for document processing and semantic chunking

### Workflow Process
1. **Document Upload**: Users upload content (PDF, DOCX, PPTX, TXT) with progress tracking
2. **Content Processing**: System processes and chunks the document with tenant context preservation
3. **Question Planning**: AI creates a detailed plan based on content and user requirements
4. **Question Generation**: Parallel generation of questions based on the plan using worker pools
5. **Validation**: Questions are validated for quality and accuracy with multiple-tier validation
6. **Integration**: Generated questions can be saved as Gabay Forms with proper metadata

### Supported Question Types
- Multiple Choice Questions (MCQ)
- True/False Questions
- Fill in the Blank
- Short Answer/Identification
- Essay Questions

### Natural Language Commands
The system supports natural language commands for question manipulation:
- Replace/Update: "replace question number 4", "change question 3"
- Remove/Delete: "remove question number 4", "delete question 3"

### Real-time Progress Tracking
- Streaming progress updates using Server-Sent Events (SSE)
- Visual progress indicators in the UI
- Detailed status messages at each stage
- Error handling and recovery mechanisms with tenant context preservation

### API Endpoints
- \`POST /api/v2/question-generator/upload\` - Document upload with progress tracking and duplicate detection
- \`POST /api/v2/question-generator/create-plan\` - Create question generation plan with SSE progress
- \`POST /api/v2/question-generator/start-generation\` - Start question generation with worker pool
- \`GET /api/v2/question-generator/plans/[plan_id]/status\` - Get plan status
- \`GET /api/v2/question-generator/plans/[plan_id]/questions\` - Get generated questions
- \`GET /api/v2/question-generator/stream/stats\` - Get streaming statistics

### Integration with Gabay Forms
Generated questions can be automatically converted to Gabay Form format:
- Questions are structured according to Gabay Form schema
- Metadata is preserved for tracking AI-generated content
- Forms can be directly published or further edited

### Recent Improvements
- **Tenant Context Preservation**: Fixed issues with tenant identification during document processing and progress tracking
- **CUID ID Generation**: Updated all database ID generation to use CUID format for consistency with Prisma schema
- **TypeScript Error Fixes**: Resolved compilation errors in worker pool services and queue management
- **CORS Configuration**: Enhanced CORS middleware to support localhost subdomains for development
- **Error Handling**: Improved error handling and user feedback throughout the pipeline
- **Duplicate Detection**: Enhanced document upload to properly handle existing documents with fingerprint matching`
    },
    {
      score: 85,
      Content: `## Implementation Details - Gabay Form Service

### Form Structure
Forms in the Gabay system have the following structure:
- **ID**: Unique identifier for the form
- **Title**: Form title
- **Description**: Form description
- **Schema**: Contains sections, settings, and theme
- **Settings**: Form behavior configuration
- **Theme**: Visual styling options
- **Metadata**: Additional information (category, school year, AI generation flag)
- **Status**: DRAFT, SCHEDULED, PUBLISHED, CLOSED, etc.
- **Response Count**: Number of form submissions

### Key Features
- **Real-time Collaboration**: Multiple users can work on forms simultaneously
- **Template System**: Support for form templates
- **Assessment Integration**: Link forms to assessment configurations
- **Analytics Dashboard**: Track form performance and responses
- **Public Sharing**: Publish forms with public URLs
- **Clone/Duplicate**: Copy existing forms for reuse
- **Category Management**: Organize forms by categories

### Security and Access Control
- Forms are tenant-isolated
- User authentication required for creation and editing
- Public forms have restricted access to published content only
- Role-based access control for form management`
    },
    {
      score: 80,
      Content: `## Implementation Details - AI Chat Question Generator

### Technical Architecture
The question generator follows a scalable retrieval-driven batch workflow architecture:

1. **Document Processing Pipeline**:
   - Document upload with progress tracking and tenant context preservation
   - Content extraction and text processing with error handling
   - Semantic chunking for optimal context utilization (700-1200 tokens)
   - Vector indexing for efficient retrieval

2. **Question Planning**:
   - AI analysis of document content using DeepSeek/OpenAI models
   - Creation of structured generation plans with proper validation
   - Distribution of question types based on user requirements
   - CUID-based plan ID generation for database consistency

3. **Distributed Generation**:
   - Worker pool for parallel question generation with BullMQ
   - Context-aware question creation using retrieved document chunks
   - Multiple validation passes for quality assurance
   - Proper error handling and retry mechanisms

4. **Streaming Progress**:
   - Server-Sent Events (SSE) for real-time updates
   - Progress tracking at document, planning, and generation stages
   - Detailed status messages for user feedback
   - Tenant context preservation throughout the pipeline

### AI Models and Providers
- **Primary Generation**: DeepSeek (cost-effective) and GPT-4o-mini for question creation
- **Validation**: Multiple-tier validation system with draft and premium models
- **Specialized Models**: Different models for different question types and validation levels

### Quality Assurance
- **Validation Checks**:
  - Answerability: Can the question be answered from the content?
  - Uniqueness: Is the question distinct from others?
  - Clarity: Is the question clearly worded?
  - Relevance: Does the question relate to the content?
  - Difficulty: Is the difficulty level appropriate?

- **Retry Mechanisms**: Automatic retries for failed generations with exponential backoff
- **Fallback Strategies**: Alternative approaches when primary methods fail
- **Error Recovery**: Graceful handling of failures with detailed error reporting

### Recent Technical Improvements
- **CUID ID Generation**: All database records now use CUID format for consistency
- **Tenant Context Fixes**: Proper tenant identification throughout all services
- **TypeScript Compilation**: Fixed all compilation errors in worker pool and queue services
- **CORS Handling**: Enhanced middleware for localhost development support
- **Progress Tracking**: Improved SSE implementation with better error handling`
    },
    {
      score: 75,
      Content: `## Integration Points - Gabay Form Service and AI Chat Question Generator

### Seamless Workflow
1. **Document Upload**: Users upload educational materials with progress tracking
2. **AI Processing**: System generates relevant questions with real-time updates
3. **Review and Edit**: Teachers review and modify AI-generated questions with natural language commands
4. **Form Creation**: Questions are automatically structured into a Gabay Form with proper metadata
5. **Publishing**: Forms can be immediately published or saved as drafts

### Data Flow
- AI-generated questions are automatically mapped to Gabay Form question schema
- Metadata indicating AI generation is preserved with proper tenant context
- Teachers can edit any aspect of the generated forms
- All standard Gabay Form features are available (analytics, responses, sharing)

### User Experience Features
- **Progress Tracking**: Real-time updates during question generation with detailed status
- **Question Replacement**: Natural language commands to replace specific questions
- **Bulk Operations**: Generate multiple question types in one operation
- **Preview Mode**: See how forms will appear to respondents
- **Export Options**: Save forms in various formats

### Error Handling
- Graceful degradation when AI services are unavailable
- Clear error messages for users with detailed technical information
- Recovery mechanisms for interrupted processes
- Fallback to manual form creation when needed

### Recent Enhancements
- **Improved Reliability**: Fixed tenant context issues and TypeScript compilation errors
- **Better User Feedback**: Enhanced progress tracking and error reporting
- **Performance Improvements**: Optimized document processing and question generation
- **Development Experience**: Enhanced CORS support for localhost development`
    }
  ]
};

module.exports = memories;