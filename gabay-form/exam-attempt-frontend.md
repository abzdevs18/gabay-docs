# Exam Attempt - Frontend Integration Guide

> How the Exam Attempt system integrates with Gabay Forms on the frontend

---

## Table of Contents

1. [Integration Points](#integration-points)
2. [Form Page Integration](#form-page-integration)
3. [InlineExamDialog Integration](#inlineexamdialog-integration)
4. [AssessmentExam Component](#assessmentexam-component)
5. [Progress Persistence](#progress-persistence)
6. [Submission Flow](#submission-flow)

---

## Integration Points

The Exam Attempt system integrates with three main frontend components:

1. **`forms/[slug].tsx`** - Public form page
2. **`InlineExamDialog.tsx`** - Inline exam modal
3. **`new-preview.tsx` (AssessmentExam)** - Form renderer

```
forms/[slug].tsx
      │
      ├─ useExamAttempt()
      │       │
      │       ├─ startAttempt()
      │       ├─ syncProgress()
      │       └─ focusTracking
      │
      └─ AssessmentExam
              │
              └─ localStorage persistence
```

---

## Form Page Integration

**File**: `frontend/src/pages/forms/[slug].tsx`

### Hook Initialization

```typescript
import { useExamAttempt } from '../../hooks/useExamAttempt';

const assignmentId = router.query.assignmentId as string;

// Initialize exam attempt tracking
const examAttempt = useExamAttempt({
  formId: finalForm?.id || '',
  assignmentId: assignmentId,
  interactionType: assignmentId ? 'ASSIGNMENT' : 'PUBLIC_FORM',
  onError: (error) => {
    console.error('[ExamAttempt] Error:', error);
    toast.error(error.message);
  }
});
```

### Auto-Start on Form Load

```typescript
useEffect(() => {
  if (finalForm?.id && !submissionSuccess) {
    examAttempt.startAttempt();
  }
}, [finalForm?.id, submissionSuccess]);
```

### Form Submission with SessionId

```typescript
const handleSubmit = async (payload: { 
  answers: Record<string, any>; 
  userInfo: { fullName: string; email: string; lrn: string };
  timeTaken: number;
  sessionStartTime?: number;
  focusLossCount?: number;
}) => {
  const metadata = {
    studentName: userInfo.fullName,
    respondentEmail: userInfo.email,
    respondentLrn: userInfo.lrn,
    fallbackName: userInfo.fullName,
    timeTaken,
    sessionStartTime,
    focusLossCount: examAttempt.focusLossCount || focusLossCount || 0,
    userAgent: navigator.userAgent,
    screenResolution: `${window.screen.width}x${window.screen.height}`,
    // 🔑 Include sessionId for attempt completion
    sessionId: examAttempt.attempt?.sessionId,
    resumeCount: examAttempt.attempt?.resumeCount || 0,
    ...(assignmentId && { assignmentId })
  };
  
  const response = await axios.post(
    `${process.env.BASE_URL}/api/v1/gabay-forms/${formData.id}/responses`,
    { answers, metadata }
  );

  if (response.data.success) {
    toast.success('Form submitted successfully');
    localStorage.removeItem(`form-preview-${formData.id}`);
    setSubmissionSuccess(true);
    
    // Auto-close if assignment submission
    if (assignmentId && window.opener) {
      setTimeout(() => window.close(), 3000);
    }
  }
};
```

### Key Points

- ✅ Hook initialized with `formId`, `assignmentId`, and `interactionType`
- ✅ Auto-starts attempt when form loads
- ✅ Includes `sessionId` in submission metadata
- ✅ Tracks focus losses automatically
- ✅ Clears localStorage on successful submission

---

## InlineExamDialog Integration

**File**: `frontend/src/views/components/subject/timeline/InlineExamDialog.tsx`

### Component Structure

```typescript
export default function InlineExamDialog({
  assignment,
  isOpen,
  onClose,
  onSubmitSuccess
}: InlineExamDialogProps) {
  const auth = useAuth();
  const [formData, setFormData] = useState<FormState | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  // Initialize exam attempt tracking
  const examAttempt = useExamAttempt({
    formId: assignment.formId,
    assignmentId: assignment.id,
    interactionType: 'ASSIGNMENT',
    onError: (error) => {
      setError(error.message);
      toast.error(error.message);
    }
  });

  // Pre-fill user info from auth context
  const prefilledUserInfo = useMemo(() => {
    if (auth.user) {
      const firstName = auth.user.f_name || '';
      const lastName = auth.user.l_name || '';
      const fullName = `${firstName} ${lastName}`.trim() || auth.user.username;
      
      return {
        fullName,
        email: auth.user.email || '',
        lrn: auth.user.lrn || ''
      };
    }
    return null;
  }, [auth.user]);

  // Load form data and start attempt
  useEffect(() => {
    if (isOpen && assignment.formSlug) {
      initializeExam();
    }
  }, [isOpen, assignment.formSlug]);

  const initializeExam = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Step 1: Start exam attempt
      const attemptData = await examAttempt.startAttempt();
      
      if (!attemptData || !attemptData.canContinue) {
        return;
      }

      // Step 2: Load form data
      const response = await axios.get(
        `${process.env.BASE_URL}/api/v1/gabay-forms/public/${assignment.formSlug}`
      );

      const form = response.data.data.form;
      
      // Apply shuffling if needed
      let processedSections = form.schema?.sections || [];
      if (form.settings?.shuffleQuestions) {
        processedSections = processedSections.map(section => ({
          ...section,
          questions: shuffleArray(section.questions)
        }));
      }

      setFormData({
        ...form,
        sections: processedSections,
        settings: form.schema?.settings || form.settings,
        theme: form.schema?.theme || form.theme
      });
    } catch (error: any) {
      setError(error.message || 'Failed to initialize exam');
    } finally {
      setIsLoading(false);
    }
  };
}
```

### Submission Handler

```typescript
const handleSubmit = async (payload: {
  answers: Record<string, any>;
  userInfo: { fullName: string; email: string; lrn: string };
  timeTaken: number;
  sessionStartTime?: number;
  focusLossCount?: number;
}) => {
  if (isSubmitting || isSubmitted) return;

  setIsSubmitting(true);
  
  try {
    const response = await axios.post(
      `${process.env.BASE_URL}/api/v1/gabay-forms/${formData!.id}/responses`,
      { 
        answers: payload.answers,
        metadata: {
          studentName: payload.userInfo.fullName,
          respondentEmail: payload.userInfo.email,
          respondentLrn: payload.userInfo.lrn,
          fallbackName: payload.userInfo.fullName,
          timeTaken: payload.timeTaken,
          sessionStartTime: payload.sessionStartTime || 0,
          focusLossCount: examAttempt.focusLossCount || payload.focusLossCount || 0,
          userAgent: navigator.userAgent,
          screenResolution: `${window.screen.width}x${window.screen.height}`,
          // 🔑 Assignment integration
          assignmentId: assignment.id,
          submittedFrom: 'inline_exam_dialog',
          // 🔑 Exam attempt tracking
          sessionId: examAttempt.attempt?.sessionId,
          resumeCount: examAttempt.attempt?.resumeCount || 0
        }
      }
    );

    if (response.data.success) {
      setIsSubmitted(true);
      setSubmissionResult(response.data.data);
      
      // Clear exam progress
      if (formData?.id) {
        localStorage.removeItem(`gabay-exam-progress-${formData.id}`);
      }
      
      toast.success('Assignment submitted successfully!');
      
      // Auto-close after 3 seconds
      setTimeout(() => {
        onSubmitSuccess();
        onClose();
      }, 3000);
    }
  } catch (error: any) {
    toast.error(error.response?.data?.error || 'Failed to submit');
    setIsSubmitting(false);
  }
};
```

### Key Differences from Form Page

1. **Pre-filled User Info**: Uses `auth.user` to pre-fill name, email, LRN
2. **Assignment Context**: Always `interactionType: 'ASSIGNMENT'`
3. **Submission Source**: Includes `submittedFrom: 'inline_exam_dialog'`
4. **Auto-close**: Dialog closes after successful submission

---

## AssessmentExam Component

**File**: `frontend/src/shad-components/shad/components/gabay-form/new-preview.tsx`

### LocalStorage Persistence

The AssessmentExam component persists all exam state to localStorage for recovery:

```typescript
useEffect(() => {
  if (!formState.id || !hasStarted) return;
  
  try {
    const stateToSave = {
      currentQuestionIndex,
      answers,
      fullName: studentFullName,
      email: studentEmail,
      lrn: studentLRN,
      formStarted: hasStarted,
      timerEndTime,
      startTime: state.startTime,
      currentQuestionEndTime,
      currentQuestionStartTime,
      attemptNumber: state.attemptNumber,
      resumeCount: state.resumeCount,
      sessionId: state.sessionId, // 🔑 Includes sessionId
    };
    
    localStorage.setItem(
      `gabay-exam-progress-${formState.id}`,
      JSON.stringify(stateToSave)
    );
  } catch (error) {
    console.error('[Exam Persist] Failed to save progress:', error);
  }
}, [
  formState.id, 
  currentQuestionIndex, 
  answers, 
  studentFullName, 
  studentEmail, 
  studentLRN, 
  hasStarted, 
  timerEndTime, 
  state.startTime, 
  currentQuestionEndTime, 
  currentQuestionStartTime, 
  state.attemptNumber, 
  state.resumeCount, 
  state.sessionId
]);
```

### Focus Loss Tracking

```typescript
useEffect(() => {
  if (!hasStarted || previewMode) return;

  let blurTimeout: NodeJS.Timeout;

  const handleBlur = () => {
    blurTimeout = setTimeout(() => {
      dispatch({ type: 'INCREMENT_FOCUS_LOSS' });
      console.log('[Focus Loss] Window blurred');
    }, 500);
  };

  const handleFocus = () => {
    clearTimeout(blurTimeout);
  };

  window.addEventListener('blur', handleBlur);
  window.addEventListener('focus', handleFocus);
  
  return () => {
    window.removeEventListener('blur', handleBlur);
    window.removeEventListener('focus', handleFocus);
    clearTimeout(blurTimeout);
  };
}, [hasStarted, previewMode]);
```

### State Restoration on Load

```typescript
useEffect(() => {
  const loadSavedProgress = () => {
    try {
      const saved = localStorage.getItem(`gabay-exam-progress-${formState.id}`);
      if (!saved) return;

      const savedData = JSON.parse(saved);
      
      // Restore all state
      dispatch({ 
        type: 'RESTORE_PROGRESS', 
        payload: savedData 
      });

      console.log('[Exam Progress] Restored from localStorage:', savedData);
    } catch (error) {
      console.error('[Exam Progress] Failed to restore:', error);
    }
  };

  if (formState.id) {
    loadSavedProgress();
  }
}, [formState.id]);
```

---

## Progress Persistence

### What Gets Saved

```typescript
{
  // User progress
  currentQuestionIndex: 5,
  answers: {
    "q1": "answer1",
    "q2": "answer2",
    ...
  },
  
  // User info
  fullName: "John Doe",
  email: "john@example.com",
  lrn: "123456789",
  
  // Timing
  timerEndTime: 1642100000000,
  startTime: 1642090000000,
  currentQuestionEndTime: 1642092000000,
  currentQuestionStartTime: 1642091500000,
  
  // Exam attempt metadata
  sessionId: "session_1642090000_abc123",
  attemptNumber: 1,
  resumeCount: 2,
  
  // State flags
  formStarted: true
}
```

### When It's Cleared

1. **Successful Submission**: `localStorage.removeItem()`
2. **Manual Clear**: User/teacher action
3. **Different Form**: Overwritten by new formId

### Recovery Flow

```
1. User refreshes page
2. forms/[slug].tsx loads
3. useExamAttempt checks localStorage
4. Finds saved sessionId
5. Calls startOrResumeAttempt() with sessionId
6. Backend resumes existing attempt
7. resumeCount incremented
8. AssessmentExam restores UI state
9. User continues from last question
```

---

## Submission Flow

### Complete Sequence

```
1. Student completes exam
2. Clicks "Submit"
3. AssessmentExam calls onSubmit()
4. forms/[slug].tsx handleSubmit()
5. Includes sessionId in metadata
6. POST /api/v1/gabay-forms/{id}/responses
7. Backend creates GabayFormResponse
8. Backend checks for sessionId in metadata
9. Calls examAttemptService.completeAttempt()
10. Updates ExamAttempt status to COMPLETED
11. Links responseId to attempt
12. Frontend clears localStorage
13. Shows success message
14. Redirects/closes window if assignment
```

### Metadata Sent to Backend

```typescript
{
  // User info
  studentName: "John Doe",
  respondentEmail: "john@example.com",
  respondentLrn: "123456789",
  fallbackName: "John Doe",
  
  // Timing
  timeTaken: 1800, // seconds
  sessionStartTime: 1642090000000,
  
  // Abuse detection
  focusLossCount: 3,
  resumeCount: 1,
  
  // Security
  userAgent: "Mozilla/5.0...",
  screenResolution: "1920x1080",
  
  // Integration
  assignmentId: "uuid", // if assignment
  submittedFrom: "inline_exam_dialog", // if inline
  
  // 🔑 Exam attempt linking
  sessionId: "session_1642090000_abc123"
}
```

---

## Best Practices

### DO ✅

- Initialize `useExamAttempt` hook early (before form data loads)
- Include `sessionId` in all form submissions
- Clear localStorage on successful submission
- Handle errors gracefully with toast notifications
- Log all exam attempt operations for debugging

### DON'T ❌

- Initialize hook with empty `formId` (causes issues)
- Skip `sessionId` in submission metadata (breaks linking)
- Modify localStorage keys (breaks restoration)
- Ignore error callbacks from hook
- Skip cleanup on component unmount

---

**Related Documentation**:
- [Exam Attempt System](./exam-attempt-system.md)
- [Exam Attempt Integration](./exam-attempt-integration.md)
- [Exam Attempt API](./exam-attempt-api.md)

---

**Last Updated**: January 2025
