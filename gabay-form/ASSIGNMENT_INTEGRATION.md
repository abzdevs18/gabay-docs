# Assignment-Form Integration

## Overview

This document describes how Gabay Form submissions are integrated with the Assignment submission system using an asynchronous worker pattern for optimal performance.

## Architecture

### Frontend Flow

1. **Opening Assignment Form**
   - Student clicks "Submit Work" on assignment → Opens `SubmissionModal`
   - Modal shows "Open Assignment Form" button
   - When clicked, opens form with assignmentId: `/forms/{slug}?assignmentId={assignmentId}`

2. **Form Submission**
   - Form page (`[slug].tsx`) captures `assignmentId` from URL query
   - Includes assignmentId in metadata when posting to form response API
   - Shows assignment-specific success message
   - Auto-closes window after 3 seconds if opened from assignment

### Backend Flow (Async Worker Pattern)

#### 1. Form Response API (`api/v1/gabay-forms/[id]/responses/index.ts`)
```typescript
// Captures assignmentId from metadata
const assignmentId = metadataObj.assignmentId || req.body.assignmentId || null;

// Creates form response immediately
const newResponse = await formService.submitResponse({
  formId: id,
  answers,
  metadata: metadataObj, // includes assignmentId
  submittedBy: resolvedSubmitterId || 'anonymous'
});

// Queues worker job for async processing
await responseQueueManager.addJob({
  responseId: newResponse.id,
  formId: id,
  // ... other data
  metadata: {
    // ... other metadata
    assignmentId // Passed to worker
  }
});

// Returns immediately (fast response)
return res.status(201).json({ success: true });
```

#### 2. Form Response Worker (`services/form-response-worker.service.ts`)
```typescript
async function processFormResponse(job: Job<FormResponseJobData>) {
  // Extract assignmentId from metadata
  const assignmentId = metadata?.assignmentId;
  
  if (assignmentId) {
    // Get form response to access student ID
    const formResponse = await prisma.gabayFormResponse.findUnique({
      where: { id: responseId },
      select: { submittedBy: true }
    });

    // Verify assignment exists and matches form
    const assignment = await prisma.timelineAssignment.findUnique({
      where: { id: assignmentId }
    });

    if (assignment && assignment.formId === formId) {
      // Check for duplicate submission
      const existing = await prisma.assignmentSubmission.findUnique({
        where: {
          assignmentId_studentId: {
            assignmentId,
            studentId: formResponse.submittedBy
          }
        }
      });

      if (!existing) {
        // Determine if late
        const isLate = assignment.dueDate && 
                      new Date() > new Date(assignment.dueDate);
        
        // Create assignment submission
        await prisma.assignmentSubmission.create({
          data: {
            assignmentId,
            studentId: formResponse.submittedBy,
            formResponseId: responseId,
            submittedAt: new Date(),
            status: isLate ? 'LATE' : 'SUBMITTED'
          }
        });
      }
    }
  }
  
  // Continue with AI feedback generation...
}
```

## Key Features

### 1. Performance Optimization
- **Fast API Response**: Form submission returns immediately without blocking
- **Async Processing**: Assignment creation happens in background worker
- **Parallel Processing**: AI feedback and assignment submission processed together

### 2. Reliability
- **Worker Retries**: 3 attempts with exponential backoff on failure
- **Error Isolation**: Assignment creation errors don't fail AI feedback generation
- **Duplicate Prevention**: Unique constraint on `assignmentId_studentId`

### 3. Data Integrity
- **Validation**: Verifies assignment exists and formId matches
- **Late Detection**: Automatically determines if submission is late
- **Proper Linking**: Links form response to assignment submission via `formResponseId`

## User Experience

### For Students
1. Click "Submit Work" on assignment
2. Click "Open Assignment Form" → Opens in new tab
3. Complete the form
4. Submit form
5. See "Assignment Submitted!" success message
6. Window auto-closes after 3 seconds

### For Teachers
1. View submissions through existing UI
2. Each submission includes:
   - Form response data (answers, metadata)
   - Assignment submission record (status, timing)
   - Automatic late detection
   - Link between form response and assignment

## Technical Details

### Type Definitions

**FormResponseJobData** (`services/form-response-queue.service.ts`):
```typescript
export interface FormResponseJobData {
  responseId: string;
  formId: string;
  studentEmail: string;
  studentName: string;
  studentLRN: string;
  answers: Record<string, any>;
  formTitle: string;
  teacherEmail?: string;
  teacherName?: string;
  metadata?: {
    focusLossCount?: number;
    timeDiscrepancy?: number;
    suspiciousActivity?: string[];
    timeTaken?: number;
    assignmentId?: string; // Added for assignment integration
  };
  tenantId?: string;
  tenantToken?: string;
}
```

### Database Schema

**AssignmentSubmission** (Prisma):
```prisma
model AssignmentSubmission {
  id             String   @id @default(uuid())
  assignmentId   String
  studentId      String
  formResponseId String?  // Links to GabayFormResponse
  textResponse   String?  // Optional text from modal
  submittedAt    DateTime
  status         String   // 'SUBMITTED', 'LATE', 'GRADED'
  grade          Float?
  feedback       String?
  
  @@unique([assignmentId, studentId])
}
```

## Error Handling

### Worker Error Handling
- **Assignment creation errors**: Logged but don't fail the job
- **Form response fetch errors**: Job fails and retries
- **Database errors**: Job fails and retries (up to 3 attempts)

### Frontend Error Handling
- **Form submission errors**: Show error toast, don't close window
- **Network errors**: Show "Unable to connect" message
- **Validation errors**: Show specific error message

## Testing

To test the integration:

1. **Create Assignment**:
   - Create assignment with linked Gabay Form
   - Set a due date (optional)

2. **Submit as Student**:
   - Open assignment from timeline
   - Click "Submit Work" → "Open Assignment Form"
   - Complete and submit form
   - Verify success message and auto-close

3. **Verify Data**:
   - Check `GabayFormResponse` created
   - Check `AssignmentSubmission` created (async, may take a few seconds)
   - Verify `formResponseId` links correctly
   - Check status ('SUBMITTED' or 'LATE')

4. **View as Teacher**:
   - Open teacher submissions view
   - Verify submission appears
   - Check form response data
   - Check assignment submission status

## Benefits of Worker Pattern

1. **Faster User Experience**: Students get immediate feedback
2. **Better Scalability**: Heavy processing offloaded to workers
3. **Improved Reliability**: Automatic retries on failure
4. **Cleaner Code**: Separation of concerns between API and processing
5. **Consistent Pattern**: Follows existing AI feedback generation pattern

## Related Files

- `api/src/pages/api/v1/gabay-forms/[id]/responses/index.ts` - Form response API
- `api/src/services/form-response-worker.service.ts` - Worker processing
- `api/src/services/form-response-queue.service.ts` - Queue management
- `frontend/src/pages/forms/[slug].tsx` - Form submission page
- `frontend/src/views/components/subject/timeline/SubmissionModal.tsx` - Assignment modal
