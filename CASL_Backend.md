- Gabay Form is structured with a Form Listing Page, Form Builder Page, and a core GabayFormBuilder component.
- State is managed centrally via FormBuilderContext using a reducer and actions for all form modifications.
- Auto-save and manual save transform form state into a backend-compatible schema, using GabayFormService for API calls.
- SectionCard is a draggable container for questions, manages section title/description, and hosts QuestionCard components. It uses props and context for state and actions.
- QuestionCard is a draggable, dual-mode (collapsed/expanded) component for editing questions. It supports single/multiple correct answers, per-option scoring, and type switching. The expanded state is managed by context, not locally.
- Data and event flow: State flows down as props, events flow up via callbacks to context, which dispatches reducer actions.
- Drag-and-drop is implemented with react-beautiful-dnd for both sections and questions.
- GabayFormService abstracts all backend API calls for forms (CRUD, clone, like, etc.) under /api/v1/gabay-forms endpoints.
- UI/UX improvements: Collapsed QuestionCards have a light gray background, and clicking anywhere on them expands for editing.
- All changes and features are orchestrated to maintain robust, scalable, and modern React architecture.

When creating new service classes, they must include JSDoc-style documentation comments at the top of the file. The documentation should be consistent with existing service files and explain the class’s purpose and responsibilities.

When beginning any backend task, the first step is to thoroughly review the relevant Prisma schema files in the api/prisma/schema/ directory. This ensures a complete understanding of the data models and their relationships before writing code.

All permission and authorization checks on the backend must be implemented using the existing CASL (casl.ts) setup, which is located at api/src/lib/casl.ts.

To display the state of frontend requests (such as loading, success, or error), the reusable component located at frontend/src/pages/components/status-request-and-response/index.tsx must be used.

All caching operations should use the project’s centralized caching services. For the backend, the service is located at api/src/services/cache.service.ts. Avoid implementing local or file-specific caching mechanisms.

The notification system’s client-side connection logic must be conditional. In frontend/src/contexts/NotificationContext.tsx, the checkFeature('NOTIFICATION_SYSTEM') function must be used to gate both the initial HTTP fetch for notifications and the establishment of the WebSocket connection. Connections should only be attempted if the feature is enabled for the tenant.