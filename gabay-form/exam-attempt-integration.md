# Exam Attempt - Gabay Forms Integration

> How the Exam Attempt system integrates with Gabay Forms backend

---

## Table of Contents

1. [Integration Overview](#integration-overview)
2. [Form Response Submission](#form-response-submission)
3. [Attempt Completion Logic](#attempt-completion-logic)
4. [Anonymous User Support](#anonymous-user-support)
5. [Assignment Integration](#assignment-integration)
6. [Data Flow Diagrams](#data-flow-diagrams)
7. [Error Handling](#error-handling)

---

## Integration Overview

The Exam Attempt system integrates with Gabay Forms at the submission layer:

```
Student Submission
       │
       ▼
 Form Response API
   (/responses)
       │
       ├─ Create GabayFormResponse
       │
       ├─ Check for sessionId
       │
       └─ Complete ExamAttempt
              │
              ├─ Update status → COMPLETED
              └─ Link responseId
```

### Key Integration Point

**File**: `api/src/pages/api/v1/gabay-forms/[id]/responses/index.ts`

After creating the form response, the API checks for `sessionId` in metadata and completes the exam attempt.

---

## Form Response Submission

### Submission Endpoint

**Endpoint**: `POST /api/v1/gabay-forms/{id}/responses`

**Handler**: Form response POST handler

### Complete Submission Flow

```typescript
case 'POST': {
  const { answers, metadata } = req.body;
  
  // Use metadata as provided (frontend sends an object)
  const metadataObj: any = (metadata && typeof metadata === 'object') 
    ? { ...metadata } 
    : {};

  // Extract assignmentId if provided
  const assignmentId = metadataObj.assignmentId || req.body.assignmentId;

  // Determine submitter ID
  let resolvedSubmitterId = req.user?.id || null;
  
  // For public forms without authentication
  if (!resolvedSubmitterId) {
    // Check if LRN provided and lookup student
    if (metadataObj.respondentLrn) {
      const student = await prisma.user.findFirst({
        where: { 
          lrn: metadataObj.respondentLrn,
          role: 'student'
        }
      });
      if (student) {
        resolvedSubmitterId = student.id;
      }
    }
  }

  try {
    // Create response in database
    const newResponse = await formService.submitResponse({
      formId: id,
      answers,
      metadata: metadataObj,
      submittedBy: resolvedSubmitterId || 'anonymous'
    });

    // ✅ Complete exam attempt if sessionId exists
    try {
      const sessionId = metadataObj?.sessionId;
      console.log('[ExamAttempt] Checking for sessionId in metadata:', { 
        hasSessionId: !!sessionId, 
        sessionId,
        metadataKeys: Object.keys(metadataObj)
      });
      
      if (sessionId) {
        const { ExamAttemptService } = await import('@/services/exam-attempt.service');
        const examAttemptService = new ExamAttemptService(prisma);
        
        console.log(`[ExamAttempt] Completing attempt for session: ${sessionId}`);
        const completedAttempt = await examAttemptService.completeAttempt(
          sessionId, 
          newResponse.id
        );
        
        console.log(`✅ [ExamAttempt] Successfully completed attempt:`, {
          attemptId: completedAttempt.id,
          sessionId: completedAttempt.sessionId,
          status: completedAttempt.status,
          responseId: completedAttempt.responseId
        });
      } else {
        console.warn('⚠️ [ExamAttempt] No sessionId found in metadata');
        console.warn('[ExamAttempt] Metadata received:', metadataObj);
      }
    } catch (attemptError: any) {
      // Log error but don't fail the submission
      console.error('❌ Error completing exam attempt:', {
        error: attemptError?.message || attemptError,
        sessionId: metadataObj?.sessionId,
        responseId: newResponse.id
      });
    }

    // Continue with assignment submission, notifications, etc.
    // ...

    return res.status(200).json({
      success: true,
      message: 'Form submitted successfully',
      data: { response: newResponse }
    });
  } catch (error) {
    // Error handling
  }
}
```

### Key Points

1. **sessionId Required**: Must be in `metadata.sessionId`
2. **Non-Blocking**: Attempt completion errors don't fail submission
3. **Logging**: Comprehensive logging for debugging
4. **Response Linking**: `responseId` links to form response

---

## Attempt Completion Logic

### completeAttempt() Integration

```typescript
// Inside form response handler
if (sessionId) {
  const { ExamAttemptService } = await import('@/services/exam-attempt.service');
  const examAttemptService = new ExamAttemptService(prisma);
  
  const completedAttempt = await examAttemptService.completeAttempt(
    sessionId,
    newResponse.id
  );
  
  // Result:
  // - status: IN_PROGRESS → COMPLETED
  // - submittedAt: current timestamp
  // - responseId: linked to form response
}
```

### Database Updates

```sql
UPDATE "ExamAttempt"
SET 
  status = 'COMPLETED',
  "submittedAt" = NOW(),
  "responseId" = '{form_response_id}'
WHERE 
  "sessionId" = '{session_id}'
```

### What Gets Linked

```
ExamAttempt                 GabayFormResponse
├─ id: uuid                 ├─ id: uuid
├─ sessionId: session_...   │
├─ status: COMPLETED        │
├─ responseId: ─────────────┘
├─ submittedAt: timestamp
└─ answers: { ... }
```

---

## Anonymous User Support

### Problem Solved

**Original Issue**: Attempt completion failed for anonymous users because of this check:

```typescript
// ❌ OLD CODE (broken for anonymous)
if (sessionId && resolvedSubmitterId) {
  await examAttemptService.completeAttempt(sessionId, newResponse.id);
}
```

**Solution**: Changed to check only `sessionId`:

```typescript
// ✅ NEW CODE (works for all users)
if (sessionId) {
  await examAttemptService.completeAttempt(sessionId, newResponse.id);
}
```

### How It Works

1. **Frontend**: Anonymous users don't send `studentId`
2. **Backend startAttempt**: Creates attempt with `studentId: null`
3. **Database**: `studentId` field is nullable (`String?`)
4. **Completion**: Only requires `sessionId`, not `studentId`
5. **Result**: Anonymous attempts completed successfully

### Database Schema Support

```prisma
model ExamAttempt {
  studentId String? // ✅ Optional - can be null
  student   User?   // ✅ Optional relation
}
```

### Frontend Handling

```typescript
// Don't send studentId for anonymous users
const requestBody: any = {
  formId,
  sessionId: savedSessionId,
  interactionType: 'PUBLIC_FORM'
};

// Only add studentId if authenticated
if (auth.user?.id) {
  requestBody.studentId = auth.user.id;
}
```

---

## Assignment Integration

### Dual Integration

When a form is submitted as an assignment, TWO records are created:

1. **GabayFormResponse**: The form submission
2. **AssignmentSubmission**: The assignment submission

AND one is completed:

3. **ExamAttempt**: Marked as COMPLETED

```
Form Submission
      │
      ├─ Create GabayFormResponse
      │
      ├─ Complete ExamAttempt (if sessionId)
      │
      └─ Create AssignmentSubmission (if assignmentId)
```

### Assignment Submission Logic

```typescript
// After creating form response and completing attempt
if (assignmentId) {
  try {
    // Verify assignment exists
    const assignment = await prisma.timelineAssignment.findUnique({
      where: { id: assignmentId },
      select: { id: true, formId: true, dueDate: true }
    });

    if (assignment && assignment.formId === id) {
      // Check if late
      const isLate = assignment.dueDate 
        ? new Date() > new Date(assignment.dueDate)
        : false;

      // Create assignment submission
      await prisma.assignmentSubmission.create({
        data: {
          assignmentId,
          studentId: resolvedSubmitterId,
          formResponseId: newResponse.id,
          status: isLate ? 'LATE' : 'SUBMITTED',
          submittedAt: new Date()
        }
      });

      console.log('✅ Created assignment submission');
    }
  } catch (error) {
    console.error('❌ Failed to create assignment submission:', error);
    // Don't fail the form submission
  }
}
```

### Data Relationships

```
TimelineAssignment
       │
       ├─── AssignmentSubmission
       │         │
       │         ├─ studentId
       │         ├─ formResponseId ──┐
       │         └─ status           │
       │                             │
       └─── ExamAttempt              │
                 │                   │
                 ├─ studentId        │
                 ├─ assignmentId     │
                 └─ responseId ──────┘
                         │
                         └─── GabayFormResponse
```

---

## Data Flow Diagrams

### Authenticated User Flow

```
┌─────────────┐
│   Student   │
│(Logged In)  │
└──────┬──────┘
       │
       │ 1. Opens form
       ▼
┌─────────────────┐
│  forms/[slug]   │
│   useExamAttempt│◄─── Checks localStorage
└──────┬──────────┘     for saved sessionId
       │
       │ 2. POST /exam-attempts/start
       │    { formId, studentId, sessionId? }
       ▼
┌─────────────────────────┐
│ Backend: startOrResume  │
│ - Find by sessionId     │
│ - Or find by student    │
│ - Resume or create      │
└──────┬──────────────────┘
       │
       │ 3. Returns attempt with sessionId
       ▼
┌─────────────────┐
│  AssessmentExam │
│  - Save progress│
│  - Sync every 5s│
└──────┬──────────┘
       │
       │ 4. Every 5 seconds
       │    PATCH /exam-attempts/{sessionId}/sync
       │    { currentQuestion, answers, timeSpent }
       ▼
┌─────────────────┐
│ Backend: sync   │
│ - Update DB     │
│ - Check abuse   │
└─────────────────┘
       │
       │ 5. Student submits
       │    POST /gabay-forms/{id}/responses
       │    { answers, metadata: { sessionId } }
       ▼
┌──────────────────────────┐
│ Backend: submitResponse  │
│ 1. Create response       │
│ 2. Complete attempt      │
│ 3. Create assignment sub │
└──────┬───────────────────┘
       │
       │ 6. Returns success
       ▼
┌─────────────────┐
│  Success Page   │
│ - Clear storage │
│ - Show result   │
└─────────────────┘
```

### Anonymous User Flow

```
┌─────────────┐
│  Anonymous  │
│   Student   │
└──────┬──────┘
       │
       │ 1. Opens public form
       ▼
┌─────────────────┐
│  forms/[slug]   │
│   useExamAttempt│
└──────┬──────────┘
       │
       │ 2. POST /exam-attempts/start
       │    { formId, interactionType: 'PUBLIC_FORM' }
       │    ❌ NO studentId
       ▼
┌─────────────────────────┐
│ Backend: startOrResume  │
│ - Creates with NULL     │
│   studentId             │
│ - Returns sessionId     │
└──────┬──────────────────┘
       │
       │ 3. Progress syncs normally
       │    PATCH /exam-attempts/{sessionId}/sync
       ▼
┌─────────────────┐
│   Sync works    │
│   (no studentId │
│    required)    │
└──────┬──────────┘
       │
       │ 4. Student submits
       │    POST /responses
       │    { sessionId, respondentLrn? }
       ▼
┌──────────────────────────┐
│ Backend: submitResponse  │
│ 1. Try LRN lookup        │
│ 2. Use 'anonymous' if    │
│    no match              │
│ 3. Complete attempt ✅   │
│    (only needs sessionId)│
└──────┬───────────────────┘
       │
       │ 5. Success
       ▼
┌─────────────────┐
│  Completed!     │
└─────────────────┘
```

---

## Error Handling

### Non-Blocking Errors

Exam attempt errors should NOT fail form submission:

```typescript
try {
  const newResponse = await formService.submitResponse(...);

  // ✅ Attempt completion in separate try-catch
  try {
    if (sessionId) {
      await examAttemptService.completeAttempt(sessionId, newResponse.id);
    }
  } catch (attemptError) {
    // Log but don't throw
    console.error('Failed to complete attempt:', attemptError);
  }

  // Continue with success response
  return res.status(200).json({ success: true });
} catch (error) {
  // Only form submission errors should fail here
  return res.status(500).json({ success: false });
}
```

### Common Error Scenarios

| Scenario | Handling | Impact |
|----------|----------|--------|
| Missing sessionId | Log warning, continue | ✅ Form submitted, no attempt tracking |
| Invalid sessionId | Log error, continue | ✅ Form submitted, attempt not completed |
| Database error | Log error, continue | ✅ Form submitted, attempt completion failed |
| Redis cache error | Gracefully fallback | ✅ All operations continue |
| Network timeout | Retry or log | ⚠️ May need manual resolution |

### Logging Strategy

```typescript
// ✅ Comprehensive logging
console.log('[ExamAttempt] Checking for sessionId:', { 
  hasSessionId: !!sessionId,
  sessionId,
  metadataKeys: Object.keys(metadataObj)
});

if (sessionId) {
  console.log(`[ExamAttempt] Completing attempt for session: ${sessionId}`);
  
  try {
    const result = await examAttemptService.completeAttempt(sessionId, responseId);
    
    console.log('✅ [ExamAttempt] Success:', {
      attemptId: result.id,
      sessionId: result.sessionId,
      status: result.status
    });
  } catch (error: any) {
    console.error('❌ [ExamAttempt] Failed:', {
      error: error?.message,
      sessionId,
      responseId
    });
  }
} else {
  console.warn('⚠️ [ExamAttempt] No sessionId found');
}
```

---

## Testing Integration

### Test Scenarios

1. **Authenticated User**
   - Create attempt with studentId
   - Sync progress multiple times
   - Submit with sessionId
   - Verify completion

2. **Anonymous User**
   - Create attempt without studentId
   - Sync progress
   - Submit with sessionId
   - Verify completion

3. **Assignment Submission**
   - Create attempt with assignmentId
   - Submit form
   - Verify both ExamAttempt and AssignmentSubmission created

4. **Resume After Refresh**
   - Start attempt
   - Refresh page
   - Verify resumeCount incremented
   - Continue and submit

5. **Error Scenarios**
   - Submit without sessionId → Form succeeds, no attempt
   - Submit with invalid sessionId → Form succeeds, log error
   - Network failure during sync → Buffered and retried

---

**Related Documentation**:
- [Exam Attempt System](./exam-attempt-system.md)
- [Exam Attempt Frontend](./exam-attempt-frontend.md)
- [Exam Attempt API](./exam-attempt-api.md)

---

**Last Updated**: January 2025
