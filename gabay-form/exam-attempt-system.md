# Exam Attempt Tracking System - Comprehensive Documentation

> **Complete guide** to the Exam Attempt tracking system in Gabay Forms

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/gabay)
[![Status](https://img.shields.io/badge/status-production-green.svg)](./)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Database Schema](#3-database-schema)
4. [Backend Implementation](#4-backend-implementation)
5. [Frontend Implementation](#5-frontend-implementation)
6. [Integration with Gabay Forms](#6-integration-with-gabay-forms)
7. [Data Flow & Sequences](#7-data-flow--sequences)
8. [Anonymous User Support](#8-anonymous-user-support)
9. [Abuse Detection](#9-abuse-detection)
10. [API Reference](#10-api-reference)
11. [Common Issues & Solutions](#11-common-issues--solutions)

---

## 1. Overview

The **Exam Attempt Tracking System** monitors and manages student exam attempts with real-time tracking, abuse detection, and progress persistence.

### Key Features

- **📊 Real-Time Progress Tracking**: Syncs every 5 seconds
- **🔒 Abuse Detection**: Tracks refreshes and focus losses
- **💾 Progress Persistence**: localStorage + database
- **👤 Anonymous Support**: Works for public forms
- **🔄 Resume Capability**: Continue from last position
- **⚡ Redis Caching**: Fast retrieval with fallback
- **📈 Attempt Counting**: Multiple attempts per student
- **🎯 Assignment Integration**: Links to LMS assignments

### Use Cases

1. Track student progress during exams
2. Detect excessive refreshes and tab switching
3. Allow resume after disconnection
4. Generate analytics reports
5. Provide evidence for academic integrity

---

## 2. Architecture

### System Components

```
FRONTEND                BACKEND              DATABASE
┌──────────┐           ┌──────────┐         ┌──────────┐
│ Form Page│──────────▶│   API    │────────▶│PostgreSQL│
│   Hook   │           │Endpoints │         │  +Redis  │
└──────────┘           └──────────┘         └──────────┘
     │                      │
     │                      ▼
     │              ┌──────────────┐
     └─────────────▶│ExamAttempt   │
     localStorage   │  Service     │
                    └──────────────┘
```

---

## 3. Database Schema

### ExamAttempt Model

```prisma
model ExamAttempt {
  id                String              @id @default(uuid())
  formId            String
  studentId         String?             // NULL for anonymous
  assignmentId      String?             // NULL for public forms
  
  // Metadata
  attemptNumber     Int                 @default(1)
  sessionId         String              @unique
  status            ExamAttemptStatus   @default(IN_PROGRESS)
  interactionType   FormInteractionType @default(PUBLIC_FORM)
  
  // Progress tracking
  currentQuestion   Int                 @default(0)
  totalQuestions    Int                 @default(0)
  answers           Json                @default("{}")
  userInfo          Json?
  
  // Timing
  startedAt         DateTime            @default(now())
  lastActivityAt    DateTime            @default(now())
  submittedAt       DateTime?
  timeSpent         Int                 @default(0)
  
  // Abuse detection
  resumeCount       Int                 @default(0)
  focusLossCount    Int                 @default(0)
  suspiciousFlags   Json?
  
  // Security
  userAgent         String?
  ipAddress         String?
  
  // Relations
  form              GabayForm           @relation(fields: [formId], references: [id])
  student           User?               @relation(fields: [studentId], references: [id])
  assignment        TimelineAssignment? @relation(fields: [assignmentId], references: [id])
  response          GabayFormResponse?  @relation(fields: [responseId], references: [id])
  responseId        String?             @unique
  
  @@index([formId, studentId])
  @@index([sessionId])
  @@index([status])
}

enum ExamAttemptStatus {
  IN_PROGRESS
  COMPLETED
  ABANDONED
  EXPIRED
  SUSPICIOUS
}

enum FormInteractionType {
  PUBLIC_FORM
  ASSIGNMENT
  STANDALONE_EXAM
  PRACTICE_QUIZ
}
```

### Key Fields

| Field | Purpose | Notes |
|-------|---------|-------|
| `sessionId` | Unique identifier | `session_{timestamp}_{random}` |
| `studentId` | User reference | NULL for anonymous |
| `attemptNumber` | Nth attempt | Increments per student |
| `answers` | Partial progress | Synced every 5s |
| `resumeCount` | Refresh count | Abuse detection |
| `focusLossCount` | Tab switches | Abuse detection |

---

## 4. Backend Implementation

### ExamAttemptService

**Location**: `api/src/services/exam-attempt.service.ts`

#### Core Methods

```typescript
export class ExamAttemptService {
  constructor(private prisma: PrismaClient) {}
  
  private cacheService = CacheService.getInstance();

  // Start or resume an attempt
  async startOrResumeAttempt(params): Promise<ExamAttempt>
  
  // Sync progress every 5 seconds
  async syncProgress(sessionId: string, progress): Promise<ExamAttempt>
  
  // Mark as completed
  async completeAttempt(sessionId: string, responseId: string): Promise<ExamAttempt>
  
  // Flag suspicious activity
  private async flagAsSuspicious(attemptId: string, flags): Promise<void>
}
```

#### startOrResumeAttempt()

**Purpose**: Initialize or resume exam attempt

**Flow**:
1. Check Redis cache (graceful fallback)
2. Look for existing IN_PROGRESS attempt by sessionId
3. If not found, find by formId + studentId + assignmentId
4. Resume (increment resumeCount) OR create new
5. Cache result (graceful fallback)

**Key Code**:
```typescript
async startOrResumeAttempt(params: {
  formId: string;
  studentId?: string;
  assignmentId?: string;
  sessionId?: string;
  userAgent?: string;
  ipAddress?: string;
  interactionType?: FormInteractionType;
}) {
  // Check cache
  const cacheKey = `exam_attempt:${formId}:${studentId || 'null'}:${assignmentId || 'public'}`;
  try {
    const cached = await this.cacheService.get(cacheKey);
    if (cached && sessionId === cached.sessionId) return cached;
  } catch (error) {
    console.warn('Cache failed, continuing');
  }

  // Find existing attempt
  let attempt = null;
  if (sessionId) {
    attempt = await this.prisma.examAttempt.findFirst({
      where: { sessionId, status: ExamAttemptStatus.IN_PROGRESS }
    });
  }

  if (!attempt) {
    attempt = await this.prisma.examAttempt.findFirst({
      where: {
        formId,
        studentId: studentId || undefined, // undefined matches NULL
        assignmentId,
        status: ExamAttemptStatus.IN_PROGRESS
      },
      orderBy: { lastActivityAt: 'desc' }
    });
  }

  if (attempt) {
    // Resume
    attempt = await this.prisma.examAttempt.update({
      where: { id: attempt.id },
      data: {
        resumeCount: { increment: 1 },
        lastActivityAt: new Date()
      }
    });
  } else {
    // Create new
    const newSessionId = this.generateSessionId();
    const attemptNumber = await this.getNextAttemptNumber(formId, studentId, assignmentId);

    attempt = await this.prisma.examAttempt.create({
      data: {
        formId,
        sessionId: newSessionId,
        attemptNumber,
        interactionType: interactionType || FormInteractionType.PUBLIC_FORM,
        status: ExamAttemptStatus.IN_PROGRESS,
        studentId: studentId || null,
        assignmentId,
        userAgent,
        ipAddress
      }
    });
  }

  // Cache with 5 min TTL
  try {
    await this.cacheService.set(cacheKey, attempt, 300);
  } catch (error) {
    console.warn('Cache write failed');
  }

  return attempt;
}
```

#### syncProgress()

**Purpose**: Update progress every 5 seconds

**Flow**:
1. Update database with current progress
2. Check for suspicious activity
3. Flag if thresholds exceeded

**Thresholds**:
- `resumeCount > 15`: Flag as suspicious
- `focusLossCount > 25`: Flag as suspicious

**Key Code**:
```typescript
async syncProgress(sessionId: string, progress: {
  currentQuestion: number;
  totalQuestions: number;
  answers: any;
  userInfo?: any;
  timeSpent: number;
  focusLossCount: number;
}) {
  const attempt = await this.prisma.examAttempt.update({
    where: { sessionId },
    data: {
      currentQuestion: progress.currentQuestion,
      totalQuestions: progress.totalQuestions,
      answers: progress.answers,
      userInfo: progress.userInfo,
      timeSpent: progress.timeSpent,
      focusLossCount: progress.focusLossCount,
      lastActivityAt: new Date()
    }
  });

  // Check for suspicious activity
  if (attempt.resumeCount > 15 || attempt.focusLossCount > 25) {
    await this.flagAsSuspicious(attempt.id, {
      resumeCount: attempt.resumeCount,
      focusLossCount: attempt.focusLossCount
    });
  }

  return attempt;
}
```

#### completeAttempt()

**Purpose**: Mark attempt as completed

**Called by**: Form response submission endpoint

**Key Code**:
```typescript
async completeAttempt(sessionId: string, responseId: string) {
  const result = await this.prisma.examAttempt.update({
    where: { sessionId },
    data: {
      status: ExamAttemptStatus.COMPLETED,
      submittedAt: new Date(),
      responseId
    }
  });
  
  console.log('✅ Attempt completed:', result.sessionId);
  return result;
}
```

---

## 5. Frontend Implementation

### useExamAttempt Hook

**Location**: `frontend/src/hooks/useExamAttempt.ts`

#### Hook Interface

```typescript
interface UseExamAttemptParams {
  formId: string;
  assignmentId?: string;
  interactionType?: 'PUBLIC_FORM' | 'ASSIGNMENT' | 'STANDALONE_EXAM';
  onError?: (error: Error) => void;
}

function useExamAttempt(params): {
  attempt: ExamAttempt | null;
  isLoading: boolean;
  error: Error | null;
  startAttempt: () => Promise<ExamAttempt | null>;
  syncProgress: (progress) => Promise<void>;
  startAutoSync: (getProgress) => () => void;
  focusLossCount: number;
}
```

#### Key Features

1. **Automatic Initialization**: Starts on form load
2. **Progress Buffering**: Queues sync until sessionId available
3. **LocalStorage Persistence**: Restores on formId change
4. **Focus Tracking**: Automatic blur/visibilitychange detection
5. **Auto-sync**: Every 5 seconds with interval cleanup

#### Hook State

```typescript
const [attempt, setAttempt] = useState<ExamAttempt | null>(null);
const [isLoading, setIsLoading] = useState(false);
const [error, setError] = useState<Error | null>(null);

const focusLossCount = useRef(0);
const pendingProgressRef = useRef<ExamProgress | null>(null);
const syncIntervalRef = useRef<NodeJS.Timeout | null>(null);
const formIdRef = useRef(formId);
```

#### startAttempt()

```typescript
const startAttempt = useCallback(async () => {
  const isPublicForm = interactionType === 'PUBLIC_FORM';

  if (!formId || (!auth.user && !isPublicForm)) {
    return;
  }

  setIsLoading(true);
  setError(null);

  try {
    // Restore sessionId from localStorage
    const localProgress = localStorage.getItem(`gabay-exam-progress-${formId}`);
    const savedSessionId = localProgress ? JSON.parse(localProgress).sessionId : null;

    const requestBody: any = {
      formId,
      assignmentId,
      sessionId: savedSessionId,
      userAgent: navigator.userAgent,
      ipAddress: 'unknown',
      interactionType
    };
    
    if (auth.user?.id) {
      requestBody.studentId = auth.user.id;
    }

    const response = await axios.post(
      `${process.env.BASE_URL}/api/v1/exam-attempts/start`,
      requestBody,
      {
        headers: {
          Authorization: `Bearer ${parseCookies().token || ''}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const attemptData = response.data.data.attempt;
    
    // Update state
    setAttempt(attemptData);
    
    // Update localStorage
    const updatedProgress = {
      ...JSON.parse(localStorage.getItem(`gabay-exam-progress-${formId}`) || '{}'),
      sessionId: attemptData.sessionId,
      attemptNumber: attemptData.attemptNumber,
      resumeCount: attemptData.resumeCount,
      attempt: attemptData
    };
    localStorage.setItem(`gabay-exam-progress-${formId}`, JSON.stringify(updatedProgress));

    // Warn if excessive resumes
    if (attemptData.resumeCount > 15) {
      onError?.(new Error('Cannot continue due to excessive refreshes'));
    }

    return attemptData;
  } catch (err) {
    const error = err instanceof Error ? err : new Error('Failed to start attempt');
    setError(error);
    onError?.(error);
    return null;
  } finally {
    setIsLoading(false);
  }
}, [formId, assignmentId, interactionType, auth.user, onError]);
```

#### syncProgress()

```typescript
const syncProgress = useCallback(async (progress: ExamProgress) => {
  if (!attempt?.sessionId) {
    // Buffer progress until sessionId available
    pendingProgressRef.current = progress;
    console.warn('Deferring progress sync – sessionId not available');
    return;
  }

  try {
    await axios.patch(
      `${process.env.BASE_URL}/api/v1/exam-attempts/${attempt.sessionId}/sync`,
      {
        ...progress,
        focusLossCount: focusLossCount.current
      },
      {
        headers: {
          Authorization: `Bearer ${parseCookies().token || ''}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Progress synced');
  } catch (err) {
    console.error('❌ Failed to sync progress:', err);
  }
}, [attempt]);
```

#### startAutoSync()

```typescript
const startAutoSync = useCallback((getProgress: () => ExamProgress) => {
  if (syncIntervalRef.current) {
    clearInterval(syncIntervalRef.current);
  }

  syncIntervalRef.current = setInterval(() => {
    const progress = getProgress();
    syncProgress(progress);
  }, 5000); // Every 5 seconds

  return () => {
    if (syncIntervalRef.current) {
      clearInterval(syncIntervalRef.current);
    }
  };
}, [syncProgress]);
```

#### Focus Loss Tracking

```typescript
useEffect(() => {
  const handleVisibilityChange = () => {
    if (document.hidden && attempt?.status === 'IN_PROGRESS') {
      focusLossCount.current += 1;
      console.log('Focus lost, count:', focusLossCount.current);
    }
  };

  const handleBlur = () => {
    if (attempt?.status === 'IN_PROGRESS') {
      focusLossCount.current += 1;
    }
  };

  document.addEventListener('visibilitychange', handleVisibilityChange);
  window.addEventListener('blur', handleBlur);

  return () => {
    document.removeEventListener('visibilitychange', handleVisibilityChange);
    window.removeEventListener('blur', handleBlur);
  };
}, [attempt?.status]);
```

#### LocalStorage Restoration

```typescript
useEffect(() => {
  if (formId && formId !== formIdRef.current) {
    formIdRef.current = formId;
    
    // Restore from localStorage
    const localProgress = localStorage.getItem(`gabay-exam-progress-${formId}`);
    if (localProgress) {
      try {
        const savedData = JSON.parse(localProgress);
        if (savedData.sessionId && savedData.attempt) {
          setAttempt(savedData.attempt);
        }
      } catch (error) {
        console.warn('Failed to restore from localStorage');
      }
    }
  }
}, [formId]);
```

---

See [exam-attempt-frontend.md](./exam-attempt-frontend.md) for frontend integration details.
See [exam-attempt-integration.md](./exam-attempt-integration.md) for Gabay Forms integration.
See [exam-attempt-api.md](./exam-attempt-api.md) for complete API reference.

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Status**: ✅ Production Ready
