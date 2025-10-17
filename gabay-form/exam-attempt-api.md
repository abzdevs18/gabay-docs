# Exam Attempt - API Reference & Troubleshooting

> Complete API reference and common issues guide

---

## Table of Contents

1. [API Endpoints](#api-endpoints)
2. [Request/Response Examples](#requestresponse-examples)
3. [Error Codes](#error-codes)
4. [Common Issues & Solutions](#common-issues--solutions)
5. [Debugging Guide](#debugging-guide)
6. [Performance Considerations](#performance-considerations)

---

## API Endpoints

### POST /api/v1/exam-attempts/start

**Description**: Start a new exam attempt or resume an existing one

**Authentication**: 
- Required for non-public forms
- Optional for `PUBLIC_FORM` interaction type

**Request Headers**:
```
Content-Type: application/json
Authorization: Bearer {token}  // Optional for public forms
```

**Request Body**:
```typescript
{
  formId: string;              // Required
  studentId?: string;          // Optional (omit for anonymous)
  assignmentId?: string;       // Optional
  sessionId?: string;          // Optional (for resume)
  userAgent?: string;          // Optional
  ipAddress?: string;          // Optional
  interactionType?: 'PUBLIC_FORM' | 'ASSIGNMENT' | 'STANDALONE_EXAM' | 'PRACTICE_QUIZ';
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "attempt": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "sessionId": "session_1642090000_abc123",
      "formId": "form-uuid",
      "studentId": "student-uuid",
      "assignmentId": null,
      "attemptNumber": 1,
      "status": "IN_PROGRESS",
      "interactionType": "PUBLIC_FORM",
      "currentQuestion": 0,
      "totalQuestions": 0,
      "answers": {},
      "userInfo": null,
      "startedAt": "2025-01-11T10:30:00.000Z",
      "lastActivityAt": "2025-01-11T10:30:00.000Z",
      "submittedAt": null,
      "timeSpent": 0,
      "resumeCount": 0,
      "focusLossCount": 0,
      "suspiciousFlags": null,
      "userAgent": "Mozilla/5.0...",
      "ipAddress": "192.168.1.1",
      "responseId": null
    }
  }
}
```

**Error Responses**:

**400 Bad Request**:
```json
{
  "success": false,
  "message": "formId is required"
}
```

**401 Unauthorized** (for non-public forms):
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

**405 Method Not Allowed**:
```json
{
  "success": false,
  "message": "Method not allowed"
}
```

**500 Internal Server Error**:
```json
{
  "success": false,
  "message": "Failed to start attempt",
  "error": "Database connection failed"
}
```

---

### PATCH /api/v1/exam-attempts/[sessionId]/sync

**Description**: Sync exam progress in real-time

**Authentication**: Optional (uses CORS)

**Request Headers**:
```
Content-Type: application/json
Authorization: Bearer {token}  // Optional
```

**URL Parameters**:
- `sessionId` (string): The exam attempt session ID

**Request Body**:
```typescript
{
  currentQuestion: number;       // Current question index (0-based)
  totalQuestions: number;        // Total questions in exam
  answers: Record<string, any>;  // Partial answers
  userInfo?: {                   // Optional user information
    fullName: string;
    email: string;
    lrn: string;
  };
  timeSpent: number;             // Total seconds spent
  focusLossCount: number;        // Number of focus loss events
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Progress synced",
  "data": {
    "currentQuestion": 5,
    "totalQuestions": 20,
    "answers": {
      "q1": "answer1",
      "q2": "answer2",
      "q5": "answer5"
    },
    "userInfo": {
      "fullName": "John Doe",
      "email": "john@example.com",
      "lrn": "123456789"
    },
    "timeSpent": 300,
    "focusLossCount": 2
  }
}
```

**Error Responses**:

**405 Method Not Allowed**:
```json
{
  "success": false,
  "message": "Method not allowed"
}
```

**500 Internal Server Error**:
```json
{
  "success": false,
  "message": "Failed to sync progress"
}
```

---

## Request/Response Examples

### Example 1: Start Authenticated Attempt

**Request**:
```bash
curl -X POST http://localhost:3001/api/v1/exam-attempts/start \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "formId": "form-12345",
    "studentId": "student-67890",
    "assignmentId": "assignment-abc",
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.100",
    "interactionType": "ASSIGNMENT"
  }'
```

**Response**:
```json
{
  "success": true,
  "data": {
    "attempt": {
      "id": "attempt-uuid",
      "sessionId": "session_1642090000_xyz789",
      "formId": "form-12345",
      "studentId": "student-67890",
      "assignmentId": "assignment-abc",
      "attemptNumber": 1,
      "status": "IN_PROGRESS",
      "interactionType": "ASSIGNMENT",
      "resumeCount": 0,
      "focusLossCount": 0
    }
  }
}
```

---

### Example 2: Resume Existing Attempt

**Request**:
```bash
curl -X POST http://localhost:3001/api/v1/exam-attempts/start \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "formId": "form-12345",
    "studentId": "student-67890",
    "sessionId": "session_1642090000_xyz789",
    "interactionType": "ASSIGNMENT"
  }'
```

**Response** (resumeCount incremented):
```json
{
  "success": true,
  "data": {
    "attempt": {
      "id": "attempt-uuid",
      "sessionId": "session_1642090000_xyz789",
      "formId": "form-12345",
      "studentId": "student-67890",
      "assignmentId": "assignment-abc",
      "attemptNumber": 1,
      "status": "IN_PROGRESS",
      "interactionType": "ASSIGNMENT",
      "resumeCount": 1,
      "currentQuestion": 5,
      "answers": { "q1": "answer1", "q2": "answer2" }
    }
  }
}
```

---

### Example 3: Anonymous User Attempt

**Request** (no Authorization header, no studentId):
```bash
curl -X POST http://localhost:3001/api/v1/exam-attempts/start \
  -H "Content-Type: application/json" \
  -d '{
    "formId": "form-12345",
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.100",
    "interactionType": "PUBLIC_FORM"
  }'
```

**Response** (studentId is null):
```json
{
  "success": true,
  "data": {
    "attempt": {
      "id": "attempt-uuid",
      "sessionId": "session_1642091000_def456",
      "formId": "form-12345",
      "studentId": null,
      "assignmentId": null,
      "attemptNumber": 1,
      "status": "IN_PROGRESS",
      "interactionType": "PUBLIC_FORM"
    }
  }
}
```

---

### Example 4: Sync Progress

**Request**:
```bash
curl -X PATCH http://localhost:3001/api/v1/exam-attempts/session_1642090000_xyz789/sync \
  -H "Content-Type: application/json" \
  -d '{
    "currentQuestion": 5,
    "totalQuestions": 20,
    "answers": {
      "q1": "answer1",
      "q2": "answer2",
      "q3": "answer3",
      "q4": "answer4",
      "q5": "answer5"
    },
    "userInfo": {
      "fullName": "John Doe",
      "email": "john@example.com",
      "lrn": "123456789"
    },
    "timeSpent": 300,
    "focusLossCount": 2
  }'
```

**Response**:
```json
{
  "success": true,
  "message": "Progress synced",
  "data": {
    "currentQuestion": 5,
    "totalQuestions": 20,
    "timeSpent": 300,
    "focusLossCount": 2
  }
}
```

---

## Error Codes

| Status Code | Meaning | Common Causes |
|-------------|---------|---------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Missing formId, invalid parameters |
| 401 | Unauthorized | Missing/invalid auth token for non-public forms |
| 403 | Forbidden | User doesn't have access to this form |
| 404 | Not Found | Form or attempt not found |
| 405 | Method Not Allowed | Wrong HTTP method used |
| 500 | Internal Server Error | Database error, service failure |

---

## Common Issues & Solutions

### Issue 1: Attempt Not Completing

**Symptom**: Form submits successfully, but ExamAttempt status stays IN_PROGRESS

**Possible Causes**:
1. ❌ sessionId not included in submission metadata
2. ❌ Wrong sessionId format
3. ❌ Backend completion logic failing silently

**Solutions**:

```typescript
// ✅ Ensure sessionId is included in metadata
const metadata = {
  sessionId: examAttempt.attempt?.sessionId,  // Must be present
  // ... other metadata
};

await axios.post(`${process.env.BASE_URL}/api/v1/gabay-forms/${formId}/responses`, {
  answers,
  metadata
});
```

**Verification**:
```sql
SELECT 
  "sessionId", 
  status, 
  "responseId", 
  "submittedAt"
FROM "ExamAttempt"
WHERE "sessionId" = 'session_xxx';
```

**Expected Result**: 
- `status` = 'COMPLETED'
- `responseId` is not null
- `submittedAt` has timestamp

---

### Issue 2: Anonymous Users Can't Complete

**Symptom**: Anonymous form submissions don't complete the attempt

**Root Cause**: Old code checked for both `sessionId` AND `resolvedSubmitterId`

```typescript
// ❌ WRONG (prevents anonymous completion)
if (sessionId && resolvedSubmitterId) {
  await examAttemptService.completeAttempt(sessionId, responseId);
}
```

**Solution**:

```typescript
// ✅ CORRECT (works for all users)
if (sessionId) {
  await examAttemptService.completeAttempt(sessionId, responseId);
}
```

**Database Schema**:
```prisma
model ExamAttempt {
  studentId String? // ✅ Must be optional
  student   User?   // ✅ Optional relation
}
```

---

### Issue 3: Progress Not Syncing

**Symptom**: Frontend syncs every 5 seconds but database not updating

**Possible Causes**:
1. ❌ sessionId not available when syncProgress called
2. ❌ API endpoint unreachable
3. ❌ CORS issues
4. ❌ Database connection issues

**Solutions**:

**Check sessionId availability**:
```typescript
const syncProgress = useCallback(async (progress: ExamProgress) => {
  if (!attempt?.sessionId) {
    // Buffer until sessionId available
    pendingProgressRef.current = progress;
    console.warn('Deferring sync - no sessionId');
    return;
  }
  
  // Proceed with sync
  await axios.patch(`${API_URL}/exam-attempts/${attempt.sessionId}/sync`, progress);
}, [attempt]);
```

**Check API connectivity**:
```bash
# Test endpoint
curl -X PATCH http://localhost:3001/api/v1/exam-attempts/session_test/sync \
  -H "Content-Type: application/json" \
  -d '{"currentQuestion": 0, "totalQuestions": 10, "answers": {}, "timeSpent": 0, "focusLossCount": 0}'
```

---

### Issue 4: localStorage Not Restoring

**Symptom**: Page refresh loses exam attempt state

**Possible Causes**:
1. ❌ formId changed during restore
2. ❌ localStorage cleared unexpectedly
3. ❌ Restore logic not triggered

**Solutions**:

**Ensure formId tracking**:
```typescript
const formIdRef = useRef(formId);

useEffect(() => {
  if (formId && formId !== formIdRef.current) {
    formIdRef.current = formId;
    
    // Restore from localStorage
    const saved = localStorage.getItem(`gabay-exam-progress-${formId}`);
    if (saved) {
      const data = JSON.parse(saved);
      if (data.sessionId && data.attempt) {
        setAttempt(data.attempt);
      }
    }
  }
}, [formId]);
```

**Verify localStorage structure**:
```javascript
// Check in browser console
console.log(
  JSON.parse(localStorage.getItem('gabay-exam-progress-form-12345'))
);

// Expected structure:
{
  sessionId: "session_1642090000_xyz789",
  attemptNumber: 1,
  resumeCount: 1,
  attempt: { /* full attempt object */ },
  currentQuestionIndex: 5,
  answers: { "q1": "answer1" },
  // ... other state
}
```

---

### Issue 5: Redis Cache Errors

**Symptom**: Cache-related errors in logs

**Examples**:
```
Error: Connection timeout
Error: Redis connection refused
```

**Solution**: Graceful fallback already implemented

```typescript
// ✅ Gracefully handles Redis failures
try {
  const cached = await this.cacheService.get(cacheKey);
  if (cached) return cached;
} catch (error) {
  console.warn('Cache read failed, continuing without cache');
  // Continues to database query
}
```

**Impact**: No user-facing errors, slightly slower performance

---

### Issue 6: Excessive resumeCount

**Symptom**: resumeCount > 15, student warned or blocked

**Causes**:
1. Legitimate: Network issues, genuine refreshes
2. Suspicious: Attempting to cheat

**Thresholds**:
```typescript
// Warning threshold
if (resumeCount > 5) {
  toast.warning('Excessive refreshes detected');
}

// Blocking threshold
if (resumeCount > 15) {
  // Flagged as suspicious
  status = 'SUSPICIOUS';
}
```

**Solutions**:

**For legitimate users**:
- Inform about network stability
- Suggest not refreshing during exam

**For suspicious activity**:
- Review attempt logs
- Check focusLossCount and other metrics
- Manual review by instructor

---

### Issue 7: FormId Empty on Hook Init

**Symptom**: Hook initialized with empty formId, then updates

**Problem**: Causes duplicate attempts or failed initialization

**Solution**: Wait for formId before initializing

```typescript
// ❌ WRONG (initializes with empty formId)
const examAttempt = useExamAttempt({
  formId: form?.id || '',  // Empty on first render
  assignmentId,
  interactionType: 'ASSIGNMENT'
});

// ✅ CORRECT (conditional initialization)
const examAttempt = useExamAttempt({
  formId: form?.id || '',
  assignmentId,
  interactionType: 'ASSIGNMENT'
});

// Only start when formId available
useEffect(() => {
  if (form?.id && !submissionSuccess) {
    examAttempt.startAttempt();
  }
}, [form?.id, submissionSuccess]);
```

---

## Debugging Guide

### Enable Comprehensive Logging

**Frontend**:
```typescript
// In useExamAttempt hook
console.log('[ExamAttempt] startAttempt called', {
  formId,
  hasAuth: !!auth.user,
  assignmentId,
  interactionType
});

console.log('[ExamAttempt] ✅ Attempt started:', {
  sessionId: attemptData.sessionId,
  attemptNumber: attemptData.attemptNumber
});
```

**Backend**:
```typescript
// In ExamAttemptService
console.log('[ExamAttemptService] startOrResumeAttempt called:', {
  formId,
  studentId,
  assignmentId,
  sessionId
});

console.log('[ExamAttemptService] ✅ Created new attempt:', {
  id: attempt.id,
  sessionId: attempt.sessionId
});
```

### Check Database State

```sql
-- View active attempts
SELECT 
  "sessionId",
  "studentId",
  "formId",
  status,
  "attemptNumber",
  "resumeCount",
  "currentQuestion",
  "lastActivityAt"
FROM "ExamAttempt"
WHERE status = 'IN_PROGRESS'
ORDER BY "lastActivityAt" DESC;

-- View completed attempts with responses
SELECT 
  ea."sessionId",
  ea.status,
  ea."responseId",
  ea."submittedAt",
  gfr.id as response_id,
  gfr."createdAt" as response_created
FROM "ExamAttempt" ea
LEFT JOIN "GabayFormResponse" gfr ON ea."responseId" = gfr.id
WHERE ea.status = 'COMPLETED'
ORDER BY ea."submittedAt" DESC
LIMIT 10;

-- Find suspicious attempts
SELECT 
  "sessionId",
  "studentId",
  "resumeCount",
  "focusLossCount",
  status,
  "suspiciousFlags"
FROM "ExamAttempt"
WHERE "resumeCount" > 15 OR "focusLossCount" > 25 OR status = 'SUSPICIOUS'
ORDER BY "lastActivityAt" DESC;
```

### Check localStorage

```javascript
// In browser console
// List all exam progress keys
Object.keys(localStorage).filter(key => key.startsWith('gabay-exam-progress'));

// View specific progress
const formId = 'form-12345';
const progress = JSON.parse(localStorage.getItem(`gabay-exam-progress-${formId}`));
console.log('Progress:', progress);

// Check if sessionId present
console.log('SessionId:', progress?.sessionId);
```

### Network Debugging

```javascript
// Monitor API calls in browser console
// Add this to useExamAttempt hook

const syncProgress = useCallback(async (progress) => {
  console.log('→ Syncing progress:', {
    url: `${process.env.BASE_URL}/api/v1/exam-attempts/${attempt.sessionId}/sync`,
    payload: progress
  });
  
  try {
    const response = await axios.patch(...);
    console.log('← Sync response:', response.data);
  } catch (error) {
    console.error('× Sync failed:', error);
  }
}, [attempt]);
```

---

## Performance Considerations

### Sync Frequency

**Current**: Every 5 seconds

**Trade-offs**:
- ⬆️ Higher frequency: More real-time, more load
- ⬇️ Lower frequency: Less load, risk of data loss

**Recommendation**: Keep at 5 seconds for good balance

### Redis Caching

**Cache Duration**: 5 minutes (300 seconds)

**Benefits**:
- Faster retrieval on resume
- Reduces database load
- Graceful fallback on failure

**Cache Key Pattern**:
```
exam_attempt:{formId}:{studentId|'null'}:{assignmentId|'public'}
```

### Database Indexes

**Existing Indexes**:
```prisma
@@index([formId, studentId])
@@index([assignmentId, studentId])
@@index([sessionId])
@@index([status])
@@index([studentId])
```

**Query Performance**:
- ✅ Fast lookup by sessionId (unique index)
- ✅ Fast lookup by formId + studentId (composite index)
- ✅ Fast filtering by status

### Optimization Tips

1. **Batch Updates**: Already optimized (syncs every 5s, not per keystroke)
2. **Conditional Syncing**: Only sync when needed
3. **LocalStorage First**: Primary persistence, database as backup
4. **Async Completion**: Non-blocking attempt completion
5. **Graceful Degradation**: Continues without Redis if needed

---

**Related Documentation**:
- [Exam Attempt System](./exam-attempt-system.md)
- [Exam Attempt Frontend](./exam-attempt-frontend.md)
- [Exam Attempt Integration](./exam-attempt-integration.md)

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Status**: ✅ Production Ready
