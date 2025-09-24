# Gabay Form Service Documentation

## Table of Contents
1.  [Overview](#overview)
2.  [Architecture](#architecture)
    *   [Frontend Architecture](#frontend-architecture)
    *   [State Management](#state-management)
    *   [Backend Abstraction](#backend-abstraction)
3.  [Key Components & Entry Points](#key-components--entry-points)
    *   [`frontend/src/pages/forms/[slug].tsx`](#frontendsrcpagesformsslugtsx)
    *   [`frontend/src/pages/forms/builder/[id].tsx`](#frontendsrcpagesformsbuilderidtsx)
    *   [`GabayFormBuilder` Component](#gabayformbuilder-component)
    *   [`GabayFormService`](#gabayformservice)
4.  [API Endpoint Reference](#api-endpoint-reference)
    *   [Form Management](#form-management)
    *   [Response Handling](#response-handling)
    *   [Analytics](#analytics)
    *   [Utility Endpoints](#utility-endpoints)
5.  [Data Flow](#data-flow)
6.  [Error Handling](#error-handling)
7.  [Code Organization and Maintainability](#code-organization-and-maintainability)

---

## 1. Overview

The Gabay Form service is a comprehensive solution for creating, managing, and analyzing dynamic forms within the Gabay platform. It provides a powerful form builder for administrators and a seamless, user-friendly experience for end-users filling out forms. This document provides a detailed technical overview of the service's architecture, components, and APIs.

## 2. Architecture

The service is built on a modern, decoupled architecture that separates frontend and backend concerns, ensuring scalability and maintainability.

### Frontend Architecture

The frontend is a **Next.js** application that employs a hybrid rendering strategy:

*   **Server-Side Rendering (SSR):** Public-facing forms (rendered by `[slug].tsx`) use SSR to ensure fast initial page loads and optimal SEO performance. The server fetches form data and renders the complete HTML before sending it to the client.
*   **Client-Side Rendering (CSR):** The form builder interface (rendered by `builder/[id].tsx`) is a complex, interactive single-page application (SPA) that relies on CSR.

This dual approach leverages the strengths of both rendering patterns, providing a fast public interface and a rich, responsive administrative experience.

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

*   **Functionality:** Renders a form based on the `slug` parameter in the URL. It handles form display, user input, and submission.
*   **Data Fetching:** Uses `getServerSideProps` to fetch the form schema from the backend before rendering the page. This ensures that the form is fully rendered on the server.
*   **API Interaction:**
    *   Retrieves form data via `GabayFormService.getForm()`.
    *   Submits user responses via `GabayFormService.submitResponse()`.
    *   Increments the form's view count using `GabayFormService.incrementViews()`.

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

*   **Implementation:** It is a TypeScript class with static methods for each API endpoint. It uses `axios` to perform HTTP requests.
*   **Key Methods:**
    *   `createForm(form)`
    *   `getForm(formId)`
    *   `updateForm(formId, updates)`
    *   `deleteForm(formId)`
    *   `listForms(params)`
    *   `submitResponse(formId, answers)`
    *   `getResponses(formId)`
    *   `checkSlugAvailability(slug)`

```typescript
// Snippet from GabayFormService
export class GabayFormServiceClass {
  // ...

  static async getForm(formId: string, userId?: string): Promise<FormState> {
    const params = userId ? { createdBy: userId } : {};
    const response = await axios.get(`${GABAY_FORM_API_URL}/${formId}`, { params });
    return response.data.data.form;
  }

  static async updateForm(formId: string, updates: Partial<FormState>): Promise<FormState> {
    const response = await axios.patch(`${GABAY_FORM_API_URL}/${formId}`, updates);
    return response.data.data.form;
  }

  // ... other methods
}
```

## 4. API Endpoint Reference

The `GabayFormService` interacts with a RESTful API under the base path `/api/v1/gabay-forms`.

### Form Management
*   `POST /api/v1/gabay-forms`: Creates a new form.
*   `GET /api/v1/gabay-forms/:formId`: Retrieves a single form.
*   `PATCH /api/v1/gabay-forms/:formId`: Updates an existing form.
*   `DELETE /api/v1/gabay-forms/:formId`: Deletes a form.
*   `GET /api/v1/gabay-forms/list`: Lists all forms.
*   `POST /api/v1/gabay-forms/:formId/clone`: Clones a form.

### Response Handling
*   `POST /api/v1/gabay-forms/:formId/responses`: Submits a response.
*   `GET /api/v1/gabay-forms/:formId/responses`: Retrieves responses for a form.

### Analytics
*   `GET /api/v1/gabay-forms/:formId/analytics`: Fetches analytics for a form.
*   `GET /api/v1/gabay-forms/analytics/summary`: Retrieves an analytics summary.
*   `POST /api/v1/gabay-forms/:formId/analytics/views`: Increments the view count.

### Utility Endpoints
*   `GET /api/v1/gabay-forms/check-slug/:slug`: Checks slug availability.
*   `POST /api/v2/documents/upload`: Uploads a header image.

## 5. Data Flow

The application follows a unidirectional data flow, which enhances predictability and simplifies debugging.

1.  **State Initialization:** The `FormBuilderProvider` initializes the state, either by fetching data for an existing form or creating a default state for a new one.
2.  **Props Drilling:** The state is passed down from the context provider to child components (e.g., `GabayFormBuilder`, `SectionCard`, `QuestionCard`) via props.
3.  **User Interaction:** A user interacts with a component (e.g., types in a question title).
4.  **Action Dispatch:** The component's event handler calls a function (often from the `useFormBuilder` hook) that dispatches an action with a specific type and payload (e.g., `{ type: 'UPDATE_QUESTION', payload: { ... } }`).
5.  **Reducer Update:** The central reducer function catches the action, updates the state immutably, and returns the new state.
6.  **Re-render:** React detects the state change in the context provider and re-renders all components that consume that state, ensuring the UI reflects the latest data.

## 6. Error Handling

*   **Server-Side:** The `getServerSideProps` function in `[slug].tsx` includes `try...catch` blocks to handle API errors (e.g., form not found). If an error occurs, it can redirect the user to a 404 page or show an error message.
*   **Client-Side:** The `GabayFormService` uses `axios`, which rejects promises on HTTP error statuses. These rejections are handled in the components that call the service, typically within `try...catch` blocks or the `.catch()` method of a promise. UI feedback (e.g., toast notifications) is then provided to the user.

## Name Field Fallback Implementation

The Gabay Form service includes a robust fallback mechanism for student identification when LRN (Learner Reference Number) lookup fails:

### Overview
When a student submits a form with an LRN that cannot be found in the database, the system automatically falls back to using the provided name for identification and reporting purposes.

### Implementation Details

#### Frontend Changes (`[slug].tsx`)
- Added `fallbackName` field to form submission metadata
- Maintains existing form functionality while providing backup identification
- Sends both LRN and full name in submission payload

#### Backend Processing (`responses/index.ts`)
- Enhanced LRN lookup with failure detection
- Automatic fallback to name-based identification when LRN lookup fails
- Metadata enrichment with fallback indicators:
  - `useFallbackName`: Boolean flag indicating fallback usage
  - `displayName`: The fallback name to display in reports
- Comprehensive logging for debugging and monitoring

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
- **LRN Validation**: Frontend validation should check LRN format before submission
- **Duplicate Prevention**: Consider name-based duplicate detection for fallback cases
- **Manual Resolution**: Admin interface needed to link fallback submissions to correct student records
- **Audit Trail**: Comprehensive logging of fallback usage for data quality monitoring

## 7. Code Organization and Maintainability

The project is structured for high maintainability and scalability.

*   **Directory Structure:** The codebase is organized logically into directories for `pages`, `components`, `services`, `contexts`, `hooks`, and `types`. This makes it easy to locate files and understand the project's layout.
*   **TypeScript:** The use of TypeScript enforces type safety, reduces runtime errors, and makes the code more self-documenting.
*   **Modularity:** The application is broken down into small, reusable components, each with a single responsibility. This promotes code reuse and simplifies testing and maintenance.
*   **Consistency:** The code follows consistent naming conventions and formatting, enforced by tools like ESLint and Prettier.

I need you to focus on gabay form implementations, which documentation is available in here @README.md and then update your memory to be filled with the features of gabay form, its features, service, and endpoints its currently utilizing


I'll create a short TODO plan to track the steps, then open the documentation file at `docs/gabay-form/README.md` to extract the features, services, and endpoints so I can update memory accordingly.
I'll open the documentation file at `docs/gabay-form/README.md` to extract the Gabay Form features, services, and endpoints.

# Task Analysis
- Purpose: Update assistant memory with Gabay Form features, service, and utilized endpoints based on [docs/gabay-form/README.md](cci:7://file:///c:/Users/WDAGUtilityAccount/Desktop/Gabay/docs/gabay-form/README.md:0:0-0:0), and provide a concise summary for ongoing focus on form implementations.
- Technical Requirements: Use documentation only; no code changes. Respect project stack (Next.js 13.x, React 18, TS 5.x). Keep summary aligned with the documented architecture and API.
- Implementation Steps: Read the README, extract features/services/endpoints, update memory, and report back.
- Risks: None (read-only operation).
- Quality Standards: Clear, accurate, concise documentation-derived summary.

# Implementation Plan
1. Read [docs/gabay-form/README.md](cci:7://file:///c:/Users/WDAGUtilityAccount/Desktop/Gabay/docs/gabay-form/README.md:0:0-0:0)
   - Extract architecture, key components, features, service methods, and API endpoints.
2. Update assistant memory
   - Persist features, services, and endpoint catalog.
3. Report back
   - Provide a clean summary and confirm memory update.

# Summary of Gabay Form (from [docs/gabay-form/README.md](cci:7://file:///c:/Users/WDAGUtilityAccount/Desktop/Gabay/docs/gabay-form/README.md:0:0-0:0))
- Overview
  - **Architecture**: Next.js frontend with SSR for public forms (`frontend/src/pages/forms/[slug].tsx`) and CSR SPA for builder (`frontend/src/pages/forms/builder/[id].tsx`).
  - **State Management**: **Context API + useReducer** via `FormBuilderContext` and `useFormBuilder`.
  - **Backend Abstraction**: All HTTP handled by `GabayFormService` (TypeScript + axios).

- Key Components & Entry Points
  - **Public Form Page**: `frontend/src/pages/forms/[slug].tsx` (SSR, fetch via `getServerSideProps`, uses `GabayFormService.getForm`, `submitResponse`, `incrementViews`).
  - **Builder Page**: `frontend/src/pages/forms/builder/[id].tsx` (CSR SPA, wraps `GabayFormBuilder` with `FormBuilderProvider`).
  - **GabayFormBuilder**: Orchestrates `FormHeader`, `SectionCard`, `QuestionCard`, `FormSettings`; supports DnD, auto-save, and AI form generation.

- Features
  - **Form Builder**: Drag-and-drop sections/questions, auto-save, AI-assisted form generation.
  - **Form Settings**: Slug, status, theme, confirmation message customization.
  - **Timers**:
    - Form-level time limit with countdown and auto-submit on expiry.
    - Per-question timers with default and per-question overrides (minutes or seconds).
  - **View Tracking**: Increment views for public forms.
  - **Name Fallback for LRN**:
    - Frontend sends LRN + `fallbackName`.
    - Backend flags `useFallbackName`, sets `displayName`, logs extensively.
    - Reports show indicator (e.g., “LRN: [number] (Name-based)”).

- Service Layer
  - **GabayFormService** (TypeScript, axios)
    - Methods: `createForm`, `getForm(formId, userId?)`, `updateForm`, `deleteForm`, `listForms`, `submitResponse`, `getResponses`, `checkSlugAvailability`, `incrementViews`.
    - Example: `getForm` GETs `${GABAY_FORM_API_URL}/${formId}` with optional `createdBy` param.

- API Endpoints (base: `/api/v1/gabay-forms` unless noted)
  - Form Management:
    - **POST** `/api/v1/gabay-forms`
    - **GET** `/api/v1/gabay-forms/:formId`
    - **PATCH** `/api/v1/gabay-forms/:formId`
    - **DELETE** `/api/v1/gabay-forms/:formId`
    - **GET** `/api/v1/gabay-forms/list`
    - **POST** `/api/v1/gabay-forms/:formId/clone`
  - Response Handling:
    - **POST** `/api/v1/gabay-forms/:formId/responses`
    - **GET** `/api/v1/gabay-forms/:formId/responses`
  - Analytics:
    - **GET** `/api/v1/gabay-forms/:formId/analytics`
    - **GET** `/api/v1/gabay-forms/analytics/summary`
    - **POST** `/api/v1/gabay-forms/:formId/analytics/views`
  - Utility:
    - **GET** `/api/v1/gabay-forms/check-slug/:slug`
    - **POST** `/api/v2/documents/upload` (header image upload)

- Error Handling
  - **SSR**: `getServerSideProps` with try/catch handles 404/redirect or error UI.
  - **Client**: axios rejections handled in components with try/catch or `.catch()`, UI feedback via toasts.

# Memory Update
- I have updated my memory with the Gabay Form features, service methods, and endpoints currently in use as documented in [docs/gabay-form/README.md](cci:7://file:///c:/Users/WDAGUtilityAccount/Desktop/Gabay/docs/gabay-form/README.md:0:0-0:0).

# Next Step
- Would you like me to verify that the implementation in `frontend/src/pages/forms/[slug].tsx`, `frontend/src/pages/forms/builder/[id].tsx`, and the `GabayFormService` class matches the documentation and flag any inconsistencies or missing endpoints?