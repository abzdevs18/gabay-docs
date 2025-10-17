# Gabay Form Service Documentation

> **Comprehensive guide** to the Gabay Form system - from form creation to AI-powered feedback

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/gabay)
[![Documentation](https://img.shields.io/badge/docs-complete-green.svg)](./)
[![Multi-Tenant](https://img.shields.io/badge/multi--tenant-supported-orange.svg)](./multi-tenancy.md)
[![AI-Powered](https://img.shields.io/badge/AI-powered%20feedback-purple.svg)](./ai-feedback-system.md)

---

## Table of Contents

### 📚 Core Documentation
1.  [Overview](#1-overview)
2.  [Architecture](#2-architecture)
    *   [System Architecture](#system-architecture)
    *   [Frontend Architecture](#frontend-architecture)
    *   [Backend Architecture](#backend-architecture)
    *   [State Management](#state-management)
    *   [Backend Abstraction](#backend-abstraction)
3.  [Key Components & Entry Points](#3-key-components--entry-points)
    *   [`frontend/src/pages/forms/[slug].tsx`](#frontendsrcpagesformsslugtsx)
    *   [`frontend/src/pages/forms/builder/[id].tsx`](#frontendsrcpagesformsbuilderidtsx)
    *   [`GabayFormBuilder` Component](#gabayformbuilder-component)
    *   [Form Settings and Configuration](#form-settings-and-configuration)
    *   [`GabayFormService`](#gabayformservice)
4.  [API Endpoint Reference](#4-api-endpoint-reference)
    *   [Form Management](#form-management)
    *   [Status Management](#status-management)
    *   [Response Handling](#response-handling)
    *   [Assessment Integration](#assessment-integration)
    *   [Analytics](#analytics)
    *   [Engagement & Social](#engagement--social)
    *   [Sections & Materials](#sections--materials)
    *   [Utility Endpoints](#utility-endpoints)
    *   [Reports](#reports)
5.  [Data Flow](#5-data-flow)
6.  [Error Handling](#6-error-handling)

### 🚀 Advanced Features
7.  [AI-Powered Feedback System](#7-ai-powered-feedback-system) ⭐ NEW
    *   [Overview](#overview-2)
    *   [How It Works](#how-it-works)
    *   [Worker Architecture](#worker-architecture)
    *   [Email Delivery](#email-delivery)
8.  [Name Field Fallback Implementation](#8-name-field-fallback-implementation)
9.  [Advanced Features](#9-advanced-features)
    *   [Real-Time Notifications](#real-time-notifications)
    *   [Assessment Automation](#assessment-automation)
    *   [Caching Strategy](#caching-strategy)
    *   [Form Status Lifecycle](#form-status-lifecycle)
    *   [Game Integration](#game-integration)
    *   [Usage Tracking & Limits](#usage-tracking--limits)
10. [Security & Multi-Tenancy](#10-security--multi-tenancy)
    *   [Tenant Isolation](#tenant-isolation)
    *   [Multi-Tenant Worker Support](#multi-tenant-worker-support) ⭐ NEW
    *   [Authentication & Authorization](#authentication--authorization)
    *   [Rate Limiting & Validation](#rate-limiting--validation)
11. [Integration Points](#11-integration-points)
12. [Performance Optimizations](#12-performance-optimizations)
13. [Monitoring & Logging](#13-monitoring--logging)
14. [Deployment Guide](#14-deployment-guide) ⭐ NEW
15. [Future Enhancements & Roadmap](#15-future-enhancements--roadmap)

### 📖 Supporting Documentation
- [Architecture Diagrams](./architecture-diagrams.md)
- [Data Flow Diagrams](./data-flow-diagrams.md)
- [AI Feedback System](./ai-feedback-system.md)
- [Multi-Tenancy Guide](./multi-tenancy.md)
- [Worker System Guide](./worker-system.md)
- [API Request Flows](./api-flows.md)
- [Exam Attempt Tracking System](./EXAM_ATTEMPT_GUIDE.md) ⭐ NEW

---

## 1. Overview

The **Gabay Form Service** is an enterprise-grade, AI-powered form and assessment platform designed for educational institutions. It provides:

### ✨ Key Features

- **🎨 Visual Form Builder**: Drag-and-drop interface for creating dynamic forms and assessments
- **🤖 AI-Powered Feedback**: Automatic personalized feedback generation using GPT models
- **📊 Real-Time Analytics**: Comprehensive analytics dashboard with live metrics
- **🏢 Multi-Tenancy**: Complete data isolation for multiple schools/organizations
- **📝 Assessment Integration**: Seamless integration with LMS grading systems
- **⚡ Background Processing**: Async workers for email delivery and feedback generation
- **🔒 Enterprise Security**: Role-based access control and data encryption
- **📱 Responsive Design**: Mobile-first responsive interface
- **🎯 Smart Validation**: Real-time validation with LRN lookup and fallback
- **📧 Email Notifications**: Automated email delivery with beautiful HTML templates

### 🎯 Use Cases

1. **Academic Assessments**: Quizzes, exams, and tests with automatic grading
2. **Surveys & Feedback**: Student feedback forms and course evaluations  
3. **Admissions**: Application forms with file uploads and validation
4. **Registration**: Event and course registration with capacity limits
5. **Data Collection**: Research surveys and data gathering

### 📊 Statistics

- **Forms Created**: Unlimited (plan-based)
- **Response Processing**: ~10-20 feedbacks/minute
- **Concurrent Users**: Scalable with load balancing
- **Uptime**: 99.9% availability target
- **Response Time**: <200ms average API response

## 2. Architecture

The service is built on a modern, decoupled architecture that separates frontend and backend concerns, ensuring scalability and maintainability.

> 📊 **See detailed diagrams**: [Architecture Diagrams](./architecture-diagrams.md)

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Gabay Form System                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐      ┌──────────────┐     ┌──────────────┐  │
│  │   Frontend   │◄────►│   API Server │◄───►│   Database   │  │
│  │   (Next.js)  │      │   (Node.js)  │     │ (PostgreSQL) │  │
│  └──────────────┘      └──────┬───────┘     └──────────────┘  │
│                                │                                 │
│                    ┌───────────┴───────────┐                    │
│                    │                       │                     │
│           ┌────────▼────────┐    ┌────────▼────────┐           │
│           │  Redis Cache    │    │  Worker System  │           │
│           │  (BullMQ Queue) │    │  (AI Feedback)  │           │
│           └─────────────────┘    └─────────────────┘           │
│                                                                  │
│  ┌──────────────┐      ┌──────────────┐     ┌──────────────┐  │
│  │ Email Service│      │  AI Provider │     │   MinIO      │  │
│  │   (Brevo)    │      │  (OpenAI)    │     │  (Storage)   │  │
│  └──────────────┘      └──────────────┘     └──────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Frontend Architecture

The frontend is a **Next.js** application that employs a hybrid rendering strategy:

*   **Server-Side Rendering (SSR):** Public-facing forms (rendered by `[slug].tsx`) use SSR to ensure fast initial page loads and optimal SEO performance. The server uses `axios` to fetch form data from `/api/v1/gabay-forms/public/{slug}` with required tenant authentication headers (`x-tenant-tag` cookie). If the tenant cookie is unavailable during SSR, the component falls back to client-side fetching to maintain availability.
*   **Client-Side Rendering (CSR):** The form builder interface (rendered by `builder/[id].tsx`) is a complex, interactive single-page application (SPA) that relies on CSR.

This dual approach leverages the strengths of both rendering patterns, providing a fast public interface and a rich, responsive administrative experience.

**Important:** The public form endpoint requires tenant identification via the `x-tenant-tag` cookie for proper multi-tenant data isolation.

### State Management

State management within the `GabayFormBuilder` is centralized using **React's Context API** (`FormBuilderContext`) combined with a `useReducer` hook.

*   **Single Source of Truth:** The context provides a single, consistent source of truth for the entire form structure and its settings.
*   **Predictable State Transitions:** All state modifications are handled by a central reducer function, which processes dispatched actions. This ensures that state changes are predictable, traceable, and easy to debug.

```javascript
// Example of the reducer pattern in FormBuilderContext
const formBuilderReducer = (state: FormState, action: Action): FormState => {
  switch (action.type) {
    case 'UPDATE_FORM_TITLE':
      return { ...state, title: action.payload };
    case 'ADD_SECTION':
      // ... logic to add a section
    // ... other actions
    default:
      return state;
  }
};
```

### Backend Abstraction

All communication with the backend is encapsulated within the `GabayFormService`. This service acts as a dedicated data layer, abstracting away the complexities of HTTP requests, authentication, and endpoint management.

*   **Separation of Concerns:** Frontend components are not directly responsible for making API calls. They interact with the `GabayFormService`, which handles the communication.
*   **Maintainability:** If API endpoints or data structures change, updates only need to be made in the `GabayFormService`, not in every component that consumes the data.
*   **Testability:** The service can be easily mocked during testing, allowing for isolated unit tests of UI components.

## 3. Key Components & Entry Points

### `frontend/src/pages/forms/[slug].tsx`

This file is the entry point for public-facing forms.

*   **Functionality:** Renders a form based on the `slug` parameter in the URL using the `AssessmentExam` component (`shad/components/gabay-form/new-preview`). It handles form display, user input, validation, and submission.
*   **Data Fetching:** Uses `getServerSideProps` to fetch the form schema from `/api/v1/gabay-forms/public/{slug}` via direct `axios` calls with tenant headers. If the tenant cookie is missing during SSR, the component performs client-side fetching as a fallback.
*   **API Interaction:**
    *   Retrieves form data via `axios.get('${process.env.BASE_URL}/api/v1/gabay-forms/public/${slug}')`
    *   Submits user responses with extended metadata including `studentName`, `respondentEmail`, `respondentLrn`, `fallbackName`, and `timeTaken` to `/api/v1/gabay-forms/{formId}/responses`
    *   View count is automatically incremented on the backend when the form is accessed via the public slug endpoint

### `frontend/src/pages/forms/builder/[id].tsx`

This file serves as the entry point for the form builder interface.

*   **Functionality:** Renders the `GabayFormBuilder` component, providing the complete form creation and editing environment. It fetches the form data if an `id` is provided, or initializes a new form for creation.
*   **Context Provider:** This page wraps the `GabayFormBuilder` with the `FormBuilderProvider`, making the form state and dispatch function available to all child components.

### `GabayFormBuilder` Component

This is the core component for creating and editing forms.

*   **Structure:** It is a large, feature-rich component that orchestrates various sub-components, including:
    *   `FormHeader`: For editing the form title, description, and header image.
    *   `SectionCard`: A draggable container for a group of questions.
    *   `QuestionCard`: A component for creating and editing individual questions (e.g., text input, multiple choice, etc.).
    *   `FormSettings`: A sidebar or modal for configuring form-level settings like slug, status, and theme.
*   **State and Logic:** It utilizes the `useFormBuilder` custom hook to access the form state and dispatch actions to the reducer. It handles complex logic such as auto-saving, drag-and-drop reordering of sections and questions, and AI-powered form generation.

### Form Settings and Configuration

The `GabayFormBuilder` provides a rich set of options through the `FormSettings` component, allowing for detailed control over form behavior.

#### Timer and Deadline Settings

Gabay Form supports granular time limits to create time-sensitive assessments.

*   **Form Time Limit:**
    *   Allows setting a total time limit for completing the entire form.
    *   When enabled, a countdown timer is displayed to the user.
    *   The form will automatically submit when the time limit is reached.

*   **Per-Question Timer:**
    *   This feature allows setting individual time limits for each question, overriding the global form time limit.
    *   A default time can be set for all questions, specified in **minutes or seconds**.
    *   The time for individual questions can be further customized in the question settings.
    *   This is ideal for quick-fire quizzes or assessments where speed is a factor.

#### Confirmation Message

*   Administrators can customize the confirmation message displayed to users after they submit a form.
*   This allows for personalized thank-you messages, instructions for next steps, or links to other resources.

### `GabayFormService`

This service class centralizes all API interactions related to forms.

*   **Implementation:** It is a TypeScript class with static methods for each API endpoint. It uses `axios` to perform HTTP requests with automatic authentication headers.
*   **Key Methods:**
    *   **Form Management:** `createForm(form)`, `getForm(formId, userId?)`, `updateForm(formId, updates)`, `deleteForm(formId)`, `listForms(params)`, `cloneForm(formId)`, `duplicateForm(formId)`
    *   **Response Handling:** `submitResponse(formId, answers)`, `getResponses(formId, params)`, `evaluateResponse(formId, responseId, evaluationData)`, `getResponseEvaluation(formId, responseId)`
    *   **Analytics:** `getFormAnalytics(formId)`, `getAnalyticsSummary()`, `incrementViews(formId)`
    *   **Status Management:** `publishForm(formId)`, `unpublishForm(formId)`
    *   **Assessment Integration:** `getAssessmentConfigs(filters)`, `getSubjectLoads()`, `createAssessmentConfig(data)`, `linkFormToAssessments(formId, assessmentConfigIds)`, `unlinkFormFromAssessment(formId, assessmentConfigId)`, `getFormAssessmentLinks(formId)`
    *   **Utilities:** `checkSlugAvailability(slug)`, `uploadHeaderImage(formId, file)`, `toggleLike(formId)`, `listSections()`, `listMaterialsForSection(sectionId)`

```typescript
// Snippet from GabayFormService
export class GabayFormServiceClass {
  static async getForm(formId: string, userId?: string): Promise<FormState> {
    const params = userId ? { createdBy: userId } : {};
    const response = await axios.get(`${GABAY_FORM_API_URL}/${formId}`, { params });
    return response.data.data.form;
  }

  static async updateForm(formId: string, updates: Partial<FormState>): Promise<FormState> {
    const { sections, settings, theme, ...otherFields } = updates;
    const transformedUpdates = {
      ...otherFields,
      theme: theme
    };
    const response = await axios.patch(`${GABAY_FORM_API_URL}/${formId}`, transformedUpdates, {
      headers: { 'Cache-Control': 'no-cache', 'Pragma': 'no-cache' }
    });
    return response.data.data.form;
  }

  static async submitResponse(formId: string, answers: Record<string, any>): Promise<FormResponse> {
    // Note: Frontend typically sends { answers, metadata } where metadata includes
    // studentName, respondentEmail, respondentLrn, fallbackName, timeTaken
    const response = await axios.post(`${GABAY_FORM_API_URL}/${formId}/responses`, { answers });
    return response.data.data.responses[0];
  }
}
```

## 4. API Endpoint Reference

The `GabayFormService` interacts with a RESTful API under the base path `/api/v1/gabay-forms`.

### Form Management
*   `POST /api/v1/gabay-forms`: Creates a new form (also available at `/api/v1/gabay-forms/create`).
*   `GET /api/v1/gabay-forms/:formId`: Retrieves a single form with related data (user, categories, assessment links).
*   `GET /api/v1/gabay-forms/public/:slug`: Retrieves a published form by slug (auto-increments views).
*   `PATCH /api/v1/gabay-forms/:formId`: Updates an existing form (invalidates caches).
*   `DELETE /api/v1/gabay-forms/:formId`: Deletes a form and decrements usage tracking.
*   `GET /api/v1/gabay-forms/list`: Lists all forms with filtering (search, status, createdBy).
*   `POST /api/v1/gabay-forms/:formId/clone`: Clones a public form to a new owner.
*   `POST /api/v1/gabay-forms/:formId/duplicate`: Duplicates a form (owner's own form).

### Status Management
*   `POST /api/v1/gabay-forms/:formId/publish`: Publishes a form.
*   `POST /api/v1/gabay-forms/:formId/unpublish`: Unpublishes a form.

### Response Handling
*   `POST /api/v1/gabay-forms/:formId/responses`: Submits a response with answers and metadata (LRN lookup, fallback name support, notification triggers).
*   `GET /api/v1/gabay-forms/:formId/responses`: Retrieves responses with pagination (offset or cursor-based) and date filtering.
*   `GET /api/v1/gabay-forms/:formId/responses/:responseId/evaluate`: Retrieves evaluation data for a response.
*   `POST /api/v1/gabay-forms/:formId/responses/:responseId/evaluate`: Manually evaluates a response with scores and feedback.

### Assessment Integration
*   `POST /api/v1/gabay-forms/:formId/assessment-links`: Links form to multiple assessment configs.
*   `GET /api/v1/gabay-forms/:formId/assessment-links`: Retrieves all assessment links for a form.
*   `DELETE /api/v1/gabay-forms/:formId/assessment-links/:assessmentConfigId`: Unlinks a specific assessment.

### Analytics
*   `GET /api/v1/gabay-forms/:formId/analytics`: Fetches analytics for a form (views, responses, timing).
*   `GET /api/v1/gabay-forms/analytics/summary`: Retrieves an analytics summary across all forms.
*   `POST /api/v1/gabay-forms/:formId/analytics/views`: Manually increments the view count.

### Engagement & Social
*   `POST /api/v1/gabay-forms/:formId/like`: Toggles like status for a form.

### Sections & Materials
*   `GET /api/v1/gabay-forms/sections`: Lists available sections.
*   `GET /api/v1/gabay-forms/sections/:sectionId/materials`: Lists materials for a section.

### Utility Endpoints
*   `GET /api/v1/gabay-forms/check-slug/:slug`: Checks slug availability.
*   `POST /api/v2/documents/upload`: Uploads a header image (requires saved formId, returns document metadata).
*   `GET /api/v1/gabay-forms/:formId/thumbnail`: Generates Open Graph thumbnail image for social sharing.
*   `POST /api/v1/gabay-forms/:formId/game-callback`: Webhook for game integration callbacks.

### Reports
*   `GET /api/v1/gabay-forms/reports`: Retrieves form reports with response statistics and assessment data.

## 5. Data Flow

The application follows a unidirectional data flow, which enhances predictability and simplifies debugging.

1.  **State Initialization:** The `FormBuilderProvider` initializes the state, either by fetching data for an existing form or creating a default state for a new one.
2.  **Props Drilling:** The state is passed down from the context provider to child components (e.g., `GabayFormBuilder`, `SectionCard`, `QuestionCard`) via props.
3.  **User Interaction:** A user interacts with a component (e.g., types in a question title).
4.  **Action Dispatch:** The component's event handler calls a function (often from the `useFormBuilder` hook) that dispatches an action with a specific type and payload (e.g., `{ type: 'UPDATE_QUESTION', payload: { ... } }`).
5.  **Reducer Update:** The central reducer function catches the action, updates the state immutably, and returns the new state.
6.  **Re-render:** React detects the state change in the context provider and re-renders all components that consume that state, ensuring the UI reflects the latest data.

## 6. Error Handling

*   **Server-Side:** The `getServerSideProps` function in `[slug].tsx` includes `try...catch` blocks to handle API errors (e.g., form not found, authentication failures, permission issues). Errors are returned as props with appropriate HTTP status codes (401, 403, 404, 500) and descriptive error messages. The component renders user-friendly error states based on these codes.
*   **Client-Side:** The `GabayFormService` uses `axios`, which rejects promises on HTTP error statuses. These rejections are handled in the components that call the service, typically within `try...catch` blocks. UI feedback (e.g., toast notifications from `react-hot-toast`) is provided to the user with context-specific error messages.
*   **Fallback Mechanisms:** When tenant identification fails during SSR (missing `x-tenant-tag` cookie), the component gracefully falls back to client-side data fetching to maintain form accessibility.

---

## 7. AI-Powered Feedback System ⭐

> **Automatic personalized feedback** for every form submission using GPT models

The Gabay Form system includes an advanced AI-powered feedback engine that automatically generates personalized, constructive feedback for students after completing assessments.

### Overview

When a student submits a form/assessment, the system:
1. **Analyzes** their responses and answers
2. **Generates** personalized AI feedback using GPT models
3. **Sends** a beautiful HTML email with feedback and statistics
4. **Notifies** the teacher of suspicious activity (if detected)

> 📖 **Detailed Guide**: [AI Feedback System Documentation](./ai-feedback-system.md)

### How It Works

```
Student Submits Form
        ↓
API Receives Submission
        ↓
Save Response to Database
        ↓
Queue Job for AI Processing ━━━━━━━━━┓
        ↓                             ┃
Return Success to Student             ┃
        ↓                             ┃
Display Confirmation                  ┃
                                      ┃
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
        ┃ (Async Background Processing)
        ↓
Worker Picks Up Job
        ↓
Fetch Form Questions & Answers
        ↓
Generate AI Feedback (GPT)
        ↓
Create HTML Email Template
        ↓
Send Email to Student
        ↓
[Optional] Notify Teacher
        ↓
Mark Job Complete
```

### Worker Architecture

The system uses a **unified worker manager** that processes jobs asynchronously:

```typescript
┌─────────────────────────────────────────┐
│         Worker Manager Service          │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Question Generation Workers    │   │
│  │  (AI-powered form creation)     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Form Response Worker          │   │
│  │  (AI feedback & emails)        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
         ↓              ↓
    BullMQ Queue    Redis Cache
```

**Key Features:**
- **Single Process**: Both worker types run in one unified process
- **Graceful Shutdown**: Waits for active jobs before stopping
- **Auto-Restart**: Automatic recovery from failures
- **Rate Limiting**: 10 jobs/minute to respect API limits
- **Multi-Tenant**: Respects tenant boundaries automatically

### Email Delivery

Students receive beautiful HTML emails with:

**Content Includes:**
- ✅ Personalized greeting
- 📊 Completion statistics (questions answered, time taken, completion %)
- 🤖 AI-generated personalized feedback (250-350 words)
- 📝 Specific strengths and areas for improvement
- 💡 Study tips related to the exam content
- 🎓 Encouraging closing message

**Email Template Features:**
- Modern, responsive design
- Mobile-optimized layout
- Branded with school colors (multi-tenant)
- Clear typography and spacing
- Professional appearance

### AI Models Supported

| Model | Provider | Use Case | Cost |
|-------|----------|----------|------|
| `gpt-4o-mini` | OpenAI | Default (recommended) | $0.15/1M tokens |
| `gpt-5-nano` | OpenAI | Budget-friendly | $0.10/1M tokens |
| `deepseek-chat` | DeepSeek | Fallback/alternative | Varies |

**Configuration:**
```bash
# .env
OPENAI_API_KEY=sk-...
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_FEEDBACK_MODEL=gpt-4o-mini  # Optional override
DEEPSEEK_API_KEY=sk-...  # Fallback provider
```

### Performance Metrics

**Processing Speed:**
- Form Response → Job Queue: ~50ms
- AI Feedback Generation: ~3-5 seconds
- Email Delivery: ~1-2 seconds
- **Total Time**: ~5-8 seconds per feedback

**Throughput:**
- **Rate Limit**: 10 feedbacks/minute (configurable)
- **Concurrency**: 3 simultaneous jobs
- **Daily Capacity**: ~14,400 feedbacks/day

**Reliability:**
- **Retry Logic**: 3 attempts with exponential backoff
- **Error Handling**: Graceful fallbacks for API failures
- **Job Persistence**: Survives worker restarts

### Cost Estimation

**Average Costs (using gpt-4o-mini):**
- **Input**: ~800 tokens (exam context) = $0.0001
- **Output**: ~400 tokens (feedback) = $0.0001
- **Total per feedback**: ~$0.0002 (< $0.001)

**Monthly Estimates:**
- 1,000 submissions: ~$0.20
- 10,000 submissions: ~$2.00  
- 100,000 submissions: ~$20.00

> 💰 **Cost-effective**: Less than $0.001 per student feedback

### Configuration Options

```typescript
// Disable AI feedback (if needed)
const workerManager = WorkerManager.getInstance({
  enableFormResponseWorker: false
});

// Adjust concurrency
// In form-response-worker.service.ts
concurrency: 5  // Process 5 jobs simultaneously

// Change rate limit
// In form-response-queue.service.ts
limiter: {
  max: 20,        // 20 jobs
  duration: 60000 // per minute
}
```

### Monitoring

**Log Output:**
```bash
📧 Form Response - Active: 2, Waiting: 5, Completed: 1,234, Failed: 0
🔄 [FormResponse] Processing response abc-123 for form xyz-789
📧 [FormResponse] Student email: student@school.com, Name: John Doe
🏢 [FormResponse] Tenant: school_alpha
[FormResponse] Using openai provider with model: gpt-4o-mini
[FormResponse] AI feedback generated successfully (1,958 chars)
📤 [FormResponse] Sending email to student@school.com...
✅ [FormResponse] Feedback email sent to student@school.com
✅ [FormResponse] Response abc-123 processed successfully
```

### Security & Privacy

**Data Protection:**
- ✅ Email addresses validated before sending
- ✅ Student data never logged to external services
- ✅ AI prompts contain only necessary context
- ✅ Tenant isolation maintained throughout process
- ✅ GDPR/FERPA compliant email delivery

**Multi-Tenant Support:**
- Each tenant's data is completely isolated
- Worker respects tenant boundaries
- Emails sent with correct tenant branding
- No cross-tenant data leakage

### Troubleshooting

**Common Issues:**

| Issue | Cause | Solution |
|-------|-------|----------|
| No email received | Missing `respondentEmail` | Ensure form collects email |
| Generic feedback | API key invalid | Check `OPENAI_API_KEY` in `.env` |
| Worker not processing | Redis connection | Verify Redis is running |
| Rate limit errors | Too many jobs | Reduce concurrency or rate limit |

**Debug Checklist:**
1. ✅ Check worker is running: `npm run start:workers`
2. ✅ Verify Redis is accessible: `redis-cli ping`
3. ✅ Confirm API keys in `.env`
4. ✅ Check logs for errors: `tail -f logs/worker.log`
5. ✅ Monitor queue stats in Redis

---

## 8. Name Field Fallback Implementation

The Gabay Form service includes a robust fallback mechanism for student identification when LRN (Learner Reference Number) lookup fails:

### Overview
When a student submits a form with an LRN that cannot be found in the database, the system automatically falls back to using the provided name for identification and reporting purposes.

### Implementation Details

#### Frontend Changes (`[slug].tsx`)
- Added `fallbackName` field to form submission metadata (set to `userInfo.fullName`)
- Maintains existing form functionality while providing backup identification
- Sends comprehensive metadata: `studentName`, `respondentEmail`, `respondentLrn`, `fallbackName`, and `timeTaken` in submission payload
- Uses the `AssessmentExam` component for rendering which handles user input collection

#### Backend Processing (`api/src/pages/api/v1/gabay-forms/[id]/responses/index.ts`)
- Enhanced LRN lookup with failure detection using `prisma.student.findFirst({ where: { lrn } })`
- Resolves submitter ID by prioritizing: (1) Student's `userId` from LRN lookup → (2) Authenticated user ID → (3) 'anonymous'
- Automatic fallback to name-based identification when LRN lookup fails (`studentLookupFailed` flag)
- Metadata enrichment with fallback indicators:
  - `useFallbackName`: Boolean flag indicating fallback usage
  - `displayName`: The fallback name to display in reports
- Comprehensive logging for debugging and monitoring
- Triggers real-time notifications to form creator upon submission
- Automatically processes assessment scoring if assessment links are configured

#### Reports Integration (`[formId].tsx`)
- Smart name resolution prioritizing student database records
- Fallback to metadata-provided names when student records unavailable
- Clear indication in secondary info when name-based identification is used
- Format: "LRN: [number] (Name-based)" for fallback cases

### Data Flow
1. **Form Submission**: User provides LRN and name
2. **LRN Lookup**: Backend attempts to find student by LRN
3. **Fallback Activation**: If lookup fails, system flags for name-based identification
4. **Metadata Storage**: Fallback name and flags stored in response metadata
5. **Report Display**: Reports show appropriate name with fallback indicators

### Benefits
- **Continuity**: Forms remain functional even with incomplete student databases
- **Identification**: Students can still be identified by name when LRN fails
- **Transparency**: Clear indication when fallback identification is used
- **Data Integrity**: Maintains all submission data regardless of lookup success

### Critical Requirements Identified
- **Database Synchronization**: Regular updates needed between form system and student database
- **LRN Validation**: Frontend should validate LRN format (12-digit numeric) before submission
- **Duplicate Prevention**: The backend enforces `limitOneResponse` and `allowMultipleSubmissions` settings using the resolved `submitterId`
- **Manual Resolution**: Admin interface needed to link fallback submissions to correct student records
- **Audit Trail**: Comprehensive logging of fallback usage for data quality monitoring
- **Multi-Assessment Support**: Forms can now be linked to multiple assessment configs via `GabayFormAssessmentLink` junction table
- **Automated Scoring**: Assessment automation service processes responses in background when assessment links exist

## 7. Code Organization and Maintainability

The project is structured for high maintainability and scalability.

*   **Directory Structure:** The codebase is organized logically into directories for `pages`, `components`, `services`, `contexts`, `hooks`, and `types`. This makes it easy to locate files and understand the project's layout.
*   **TypeScript:** The use of TypeScript enforces type safety, reduces runtime errors, and makes the code more self-documenting.
*   **Modularity:** The application is broken down into small, reusable components, each with a single responsibility. This promotes code reuse and simplifies testing and maintenance.
*   **Consistency:** The code follows consistent naming conventions and formatting, enforced by tools like ESLint and Prettier.

## 8. Advanced Features

### Real-Time Notifications

When a form response is submitted, the system automatically:
- Sends a real-time notification to the form creator (teacher)
- Includes submitter information (name, LRN if available)
- Uses Socket.IO for instant delivery
- Queues notifications via Bull queue for reliable processing with retry logic
- Invalidates notification caches to ensure fresh data

### Assessment Automation

Forms linked to assessment configurations trigger automated scoring:
- Background processing via `AssessmentAutomationService`
- Automatic grade calculation and storage in assessment records
- Cache invalidation for all linked assessment configs
- Supports multiple assessment links per form (multi-class deployment)
- Integrates with the Gabay LMS grading system

### Automatic Scoring System

The system automatically evaluates student responses based on predefined correct answers:

**Supported Question Types:**
- **Multiple Choice/True-False/Dropdown**: Uses `correctAnswerIds` (array of choice IDs)
  - Single-select: Checks if student's answer ID is in the array
  - Multi-select (checkbox): All selected IDs must match all correct IDs
- **Text-Based Questions** (Fill-in-blank, Short Answer, Identification): Uses `correctAnswers` (array of acceptable strings)
  - Case-insensitive string matching with whitespace trimming
  - Supports multiple acceptable answers (e.g., "photosynthesis" or "photo synthesis")
- **Essay Questions**: Marked for manual grading (no auto-scoring)

**Correct Answer Detection:**
The system intelligently detects correct answers from multiple possible field locations:
- `correctAnswerIds` - Primary field for choice-based questions
- `correctAnswers` - Primary field for text-based questions  
- `correctAnswer`, `answer`, `correct_answer` - Legacy field names
- `options[].isCorrect` or `choices[].isCorrect` - Embedded in choice definitions
- `validation.correctAnswer` - Validation rules object
- `settings.correctAnswer` - Settings object

**Scoring Process:**
1. Each response is analyzed in a background worker (`form-response-worker.service.ts`)
2. Correct answers are detected from question schema
3. Student answers are compared using type-specific logic
4. Score is calculated: `(correctCount / totalQuestions) × 100`
5. Results are used for AI feedback generation and grade posting
6. Detailed logs show scoring summary: `correctCount`, `incorrectCount`, `scorePercentage`

**Assignment Integration:**
When forms are linked to assignments, the calculated scores are automatically:
- Posted to `AssignmentSubmission` records
- Updated in the LMS grading system
- Available in teacher gradebooks
- Displayed in student reports

### Caching Strategy

The service implements a comprehensive caching layer using Redis:
- **Form data caching:** 5-minute TTL for form details
- **Response caching:** Cached for traditional pagination, real-time for cursor-based
- **List caching:** 1-minute TTL for form lists with query-specific keys
- **Analytics caching:** Cached until invalidated by new responses
- **Automatic invalidation:** Updates, deletions, and new responses trigger cache clearing
- **Pattern-based clearing:** Uses Redis key patterns for bulk invalidation

### Form Status Lifecycle

Forms progress through multiple status states:
- **DRAFT:** Initial state, not accessible to respondents
- **SCHEDULED:** Set for future release with a `releaseDate`
- **PUBLISHED:** Actively accepting responses
- **PLAYING:** Live game/quiz mode (used with game integration)
- **ENDED:** Game session completed but form still exists
- **COMPLETED:** Form successfully completed its purpose
- **CLOSED:** No longer accepting responses
- **ARCHIVED:** Historical record, not visible in active lists

### Game Integration

Forms support real-time quiz/game functionality:
- **Game callback endpoint:** `/api/v1/gabay-forms/:formId/game-callback`
- **Live sessions:** Status transitions between PUBLISHED → PLAYING → ENDED
- **Real-time updates:** Socket.IO integration for live leaderboards
- **Score tracking:** Real-time score updates during gameplay

### Usage Tracking & Limits

The service integrates with the freemium model:
- **Assessment form limits:** Checks usage limits before creation
- **Usage tracking:** Increments/decrements form counts via `UsageTrackingService`
- **Exam credits:** Tracks form creation and deletion
- **Plan enforcement:** Returns 403 when limits exceeded

## 9. Security & Multi-Tenancy

### Tenant Isolation
- All API requests require `x-tenant-tag` header for proper data isolation
- Prisma client automatically scoped to tenant via middleware
- Cache keys include tenant ID to prevent cross-tenant data leaks

### Authentication & Authorization
- Forms support optional authentication requirement (`requireAuthentication` setting)
- Response submission respects user permissions
- Builder interface protected by ACL (Faculty Pages permission)

### Rate Limiting & Validation
- LRN format validation (12-digit numeric)
- Duplicate submission prevention based on `limitOneResponse` setting
- Deadline enforcement with automatic closure
- Form status validation before accepting responses

## 10. Integration Points

### LMS Grading System Integration
- Forms can be linked to assessment configurations in the LMS
- Automatic grade posting to student records
- Support for multiple class sections per form
- MAPEH component-specific grading support
- Quarter-based assessment tracking

### Document Management
- Header image uploads via document service (`/api/v2/documents/upload`)
- MinIO storage integration for images
- Presigned URLs for secure image access
- Automatic thumbnail generation for social sharing

### Notification System
- Real-time notifications via Socket.IO
- Notification queuing with Bull/Redis
- Configurable notification preferences
- Support for multiple notification types (TOAST, BANNER, MODAL)
- Priority-based delivery

## 11. Performance Optimizations

### Database Query Optimization
- Selective field inclusion to reduce payload size
- Batch queries for related data (students, sections)
- Cursor-based pagination for large response sets
- Indexed queries on frequently accessed fields

### Frontend Performance
- Server-side rendering for public forms (SEO, initial load speed)
- Client-side caching with React Query/TanStack Query
- Lazy loading of form builder components
- Optimized bundle splitting

### Response Time Improvements
- Redis caching layer reduces database load
- Background processing for non-critical operations (scoring, notifications)
- Async assessment automation
- Debounced auto-save in form builder

## 12. Monitoring & Logging

The service includes comprehensive logging:
- **Request/Response logging:** All API endpoints log entry/exit
- **Error tracking:** Detailed error logs with stack traces
- **Performance metrics:** Via MetricsService and Redis
- **Cache operations:** Log hits/misses for optimization
- **Business events:** Form creation, submissions, status changes
- **Notification delivery:** Success/failure tracking

## 14. Deployment Guide

### Development Setup

```bash
# 1. Clone repository
git clone https://github.com/yourusername/gabay.git
cd gabay

# 2. Install dependencies
cd api && npm install
cd ../frontend && npm install

# 3. Setup environment variables
cp api/.env.example api/.env
cp frontend/.env.example frontend/.env

# 4. Start PostgreSQL & Redis
docker-compose up -d postgres redis

# 5. Run migrations
cd api && npx prisma migrate deploy

# 6. Start development servers
npm run dev:api        # Terminal 1
npm run dev:frontend   # Terminal 2
npm run dev:workers    # Terminal 3
```

### Production Deployment

#### Option 1: PM2 (Recommended)

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'gabay-api',
      script: 'npm',
      args: 'start',
      cwd: './api',
      instances: 2,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      }
    },
    {
      name: 'gabay-frontend',
      script: 'npm',
      args: 'start',
      cwd: './frontend',
      instances: 2,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'gabay-workers',
      script: 'npm',
      args: 'run start:workers',
      cwd: './api',
      instances: 1,  // Always 1 for BullMQ
      env: {
        NODE_ENV: 'production',
        WORKER_PROCESS: 'true'
      }
    }
  ]
};
```

Start:
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### Option 2: Docker

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: gabay
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

  api:
    build: ./api
    environment:
      DATABASE_URL: ${DATABASE_URL}
      REDIS_HOST: redis
      NODE_ENV: production
    ports:
      - "3001:3001"
    depends_on:
      - postgres
      - redis

  frontend:
    build: ./frontend
    environment:
      NEXT_PUBLIC_API_URL: ${API_URL}
      NODE_ENV: production
    ports:
      - "3000:3000"
    depends_on:
      - api

  workers:
    build: ./api
    command: npm run start:workers
    environment:
      DATABASE_URL: ${DATABASE_URL}
      REDIS_HOST: redis
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      BREVO_API_KEY: ${BREVO_API_KEY}
      WORKER_PROCESS: "true"
    depends_on:
      - redis
      - postgres

volumes:
  postgres_data:
  redis_data:
```

Start:
```bash
docker-compose up -d
```

#### Option 3: Kubernetes

See [kubernetes/README.md](../deployment/kubernetes/README.md) for full Kubernetes deployment guide.

### Environment Variables

**Required:**
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/gabay
DIRECT_URL=postgresql://user:pass@host:5432/gabay

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# API Keys
OPENAI_API_KEY=sk-...
BREVO_API_KEY=...

# Application
BASE_URL=https://yourdomain.com
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

**Optional:**
```bash
# AI Models
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_FEEDBACK_MODEL=gpt-4o-mini
DEEPSEEK_API_KEY=sk-...

# Email Configuration
SMTP_HOST=smtp.brevo.com
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...

# File Storage
MINIO_ENDPOINT=localhost
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
```

### Health Checks

```bash
# API Health
curl http://localhost:3001/health

# Worker Status
curl http://localhost:3001/api/workers/status

# Database
psql $DATABASE_URL -c "SELECT 1"

# Redis
redis-cli ping
```

### Monitoring

**Recommended Tools:**
- **Logs**: PM2 logs, Docker logs, or ELK stack
- **Metrics**: Prometheus + Grafana
- **APM**: New Relic or Datadog
- **Uptime**: Uptime Robot or Pingdom

**Key Metrics to Monitor:**
- API response times
- Worker queue depth
- Database connections
- Redis memory usage
- Email delivery rate
- Form submission rate

---

## 15. Future Enhancements & Roadmap

Based on the current implementation, potential areas for enhancement:
- **Analytics dashboard:** Rich visualization of form performance
- **Advanced question types:** File uploads, signature fields
- **Conditional logic:** Show/hide questions based on answers
- **Collaboration features:** Multi-user form editing
- **Version control:** Restore previous form versions
- **A/B testing:** Test different form variations
- **Export functionality:** CSV, Excel, PDF exports of responses
- **Template marketplace:** Share and discover form templates

---

## 📚 Additional Resources

### Core Documentation
- [Architecture Diagrams](./architecture-diagrams.md) - Visual system architecture
- [Data Flow Diagrams](./data-flow-diagrams.md) - Request/response flows
- [AI Feedback System](./ai-feedback-system.md) - AI-powered feedback guide
- [Worker System](./worker-system.md) - Background processing
- [Multi-Tenancy Guide](./multi-tenancy.md) - Tenant isolation

### Root Documentation
- [Unified Worker System](../../UNIFIED_WORKER_SYSTEM.md) - Complete worker guide
- [Multi-Tenant Worker Support](../../MULTI_TENANT_WORKER_SUPPORT.md) - Worker multi-tenancy
- [Form Response Worker System](../../FORM_RESPONSE_WORKER_SYSTEM.md) - Email feedback system

### External Links
- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [BullMQ Documentation](https://docs.bullmq.io)
- [OpenAI API Documentation](https://platform.openai.com/docs)

---

## 🤝 Support & Contributing

### Getting Help

**For Issues:**
1. Check [troubleshooting sections](#troubleshooting) in relevant docs
2. Search [existing issues](https://github.com/yourusername/gabay/issues)
3. Create a new issue with detailed description

**For Questions:**
1. Review this documentation thoroughly
2. Check supporting documentation files
3. Contact development team

### Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

---

## 📄 License

This project is proprietary software developed for educational institutions.

© 2025 Gabay. All rights reserved.

---

## 🎉 Conclusion

The **Gabay Form Service** is a production-ready, enterprise-grade form and assessment platform with:

✅ **Modern Architecture** - Next.js, React, Node.js, PostgreSQL, Redis  
✅ **AI-Powered** - Automatic personalized feedback using GPT models  
✅ **Multi-Tenant** - Complete data isolation for multiple organizations  
✅ **Scalable** - Background workers, caching, and optimized queries  
✅ **Secure** - Role-based access, data encryption, GDPR/FERPA compliant  
✅ **Well-Documented** - Comprehensive guides and diagrams  

**Ready to deploy and scale!** 🚀

---

**Last Updated:** January 2025  
**Version:** 2.0.0  
**Status:** ✅ Production Ready  
**Maintained by:** Gabay Development Team