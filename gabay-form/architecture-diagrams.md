# Gabay Form - Architecture Diagrams

> Visual representation of system architecture and component interactions

---

## Table of Contents

1. [High-Level System Architecture](#high-level-system-architecture)
2. [Frontend Architecture](#frontend-architecture)
3. [Backend Architecture](#backend-architecture)
4. [Database Schema](#database-schema)
5. [Worker System Architecture](#worker-system-architecture)
6. [Multi-Tenant Architecture](#multi-tenant-architecture)

---

## High-Level System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                     Gabay Form System                              │
│               (Multi-Tenant SaaS Platform)                         │
└────────────────────────────────────────────────────────────────────┘
                              │
                              │
            ┌─────────────────┴─────────────────┐
            │                                   │
    ┌───────▼────────┐                 ┌────────▼───────┐
    │   End Users    │                 │ Administrators │
    │   (Students)   │                 │   (Teachers)   │
    └───────┬────────┘                 └────────┬────────┘
            │                                   │
            │  HTTP/HTTPS                       │
            │                                   │
    ┌───────▼────────────────────────────────────▼────────┐
    │        Next.js Frontend Application                 │
    │      (Hybrid SSR/CSR Architecture)                  │
    │                                                      │
    │  ┌──────────────┐         ┌──────────────────┐     │
    │  │Public Forms  │         │  Form Builder    │     │
    │  │   [slug]     │         │    [id].tsx      │     │
    │  │   (SSR)      │         │     (CSR)        │     │
    │  └──────────────┘         └──────────────────┘     │
    └───────────────────────┬──────────────────────────────┘
                            │
                            │ REST API
                            │
    ┌───────────────────────▼──────────────────────────────┐
    │          Node.js API Server                          │
    │      (Express + Next.js API Routes)                  │
    │                                                       │
    │  ┌────────────────────────────────────────┐          │
    │  │  API Endpoints (/api/v1/gabay-forms)   │          │
    │  │  - Form CRUD    - Response Submission  │          │
    │  │  - Analytics    - Assessment Links     │          │
    │  └────────────────────────────────────────┘          │
    │                                                       │
    │  ┌────────────────────────────────────────┐          │
    │  │         Service Layer                  │          │
    │  │  - GabayFormService                    │          │
    │  │  - NotificationService                 │          │
    │  │  - CacheService                        │          │
    │  └────────────────────────────────────────┘          │
    └─────┬─────────┬─────────┬────────┬─────────┬─────────┘
          │         │         │        │         │
  ┌───────▼──┐  ┌───▼────┐ ┌─▼────┐ ┌▼──┐  ┌───▼───────┐
  │PostgreSQL│  │ Redis  │ │MinIO │ │I/O│  │  Workers  │
  │  Multi-  │  │ Cache/ │ │ File │ │   │  │  (BullMQ) │
  │  Tenant  │  │ Queue  │ │Store │ │   │  │           │
  └──────────┘  └────────┘ └──────┘ └───┘  └─────┬─────┘
                                                  │
                                      ┌───────────▼──────────┐
                                      │  External Services   │
                                      │  - OpenAI (GPT)      │
                                      │  - Brevo (Email)     │
                                      └──────────────────────┘
```

---

## Frontend Architecture

See [frontend-architecture.md](./frontend-architecture.md) for detailed component breakdown.

**Key Components:**
- **Pages**: `/forms/[slug].tsx` (SSR), `/forms/builder/[id].tsx` (CSR)
- **State**: FormBuilderContext with useReducer
- **Services**: GabayFormService (axios-based)
- **UI**: shadcn/ui components with Tailwind CSS

---

## Backend Architecture

See [backend-architecture.md](./backend-architecture.md) for detailed service breakdown.

**Key Layers:**
- **API Routes**: Next.js API routes under `/api/v1/gabay-forms`
- **Middleware**: Auth, tenant isolation, validation, rate limiting
- **Services**: Business logic layer (GabayFormService, CacheService, etc.)
- **Data Access**: Prisma ORM with multi-tenant support

---

## Database Schema

```
GabayForm
├── id (PK)
├── title
├── description
├── slug (unique)
├── status (ENUM)
├── schema (JSONB) - Form structure
├── settings (JSONB) - Configuration
├── theme (JSONB) - Styling
├── createdBy (FK → User)
├── createdAt
└── updatedAt

GabayFormResponse
├── id (PK)
├── formId (FK → GabayForm)
├── answers (JSONB)
├── metadata (JSONB)
├── submittedBy (FK → User)
├── submittedAt
└── status

GabayFormAssessmentLink (Junction Table)
├── formId (FK → GabayForm)
├── assessmentConfigId (FK → AssessmentConfig)
└── createdAt

Multi-Tenant Isolation:
- Each tenant has a separate PostgreSQL schema
- tenant_schoola.gabay_forms
- tenant_schoolb.gabay_forms
```

---

## Worker System Architecture

See [worker-system.md](./worker-system.md) for complete worker documentation.

```
WorkerManager (Singleton)
├── Question Generation Workers
│   ├── Queue: question-gen
│   ├── Concurrency: 3
│   └── Provider: DeepSeek + OpenAI
│
└── Form Response Worker
    ├── Queue: form-response-processing
    ├── Concurrency: 3
    ├── Rate Limit: 10/min
    └── Provider: OpenAI GPT-4o-mini

Flow: API → Redis Queue → Worker → External API → Email/DB
```

---

## Multi-Tenant Architecture

```
Request Flow:
1. HTTP Request with x-tenant-tag header
2. Tenant Middleware extracts tenant context
3. getPrismaClient(req, tenantId)
4. Query isolated to tenant schema
5. Cache with tenant-prefixed keys
6. Response to client

Isolation Levels:
✅ Database: Separate PostgreSQL schemas
✅ Cache: Tenant-prefixed Redis keys
✅ Workers: Tenant context in job data
✅ Storage: Tenant-specific MinIO buckets
✅ Sessions: Tenant-scoped authentication
```

---

## Related Documentation

- [Data Flow Diagrams](./data-flow-diagrams.md)
- [API Request Flows](./api-flows.md)
- [Worker System Guide](./worker-system.md)
- [Multi-Tenancy Guide](./multi-tenancy.md)
