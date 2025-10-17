# Exam Security Review - Potential Cheating Vectors

## Executive Summary
This document identifies potential cheating methods K-12 students might use with the current Gabay Form implementation. Recommendations are prioritized by **Risk Level** and **Implementation Complexity**.

---

## 🔴 HIGH RISK - Address Immediately

### 1. **Correct Answers Exposed to Client**
**Risk Level:** 🔴 CRITICAL  
**Complexity:** 🟡 Medium

**Issue:**
The form schema (including questions with correct answers) is sent directly to the student's browser via the public API endpoint.

**How Students Can Exploit:**
```javascript
// In browser console:
console.log(formData.schema.sections)
// Or check localStorage:
localStorage.getItem('gabay-exam-progress-{formId}')
// Or inspect Network tab -> Preview -> schema -> sections -> questions
```

**Current Code Location:**
- `api/src/pages/api/v1/gabay-forms/public/[slug].ts` (Line 59)
- Returns full `GabayForm` object including schema with correct answers

**Recommended Fix:**
```typescript
// In gabay-form.service.ts, add a method to sanitize form data for students
async getPublicFormForStudent(slug: string): Promise<GabayForm | null> {
  const form = await this.getFormBySlug(slug);
  
  if (!form) return null;
  
  // Strip correct answers from schema
  const sanitizedSchema = this.sanitizeFormSchema(form.schema);
  
  return {
    ...form,
    schema: sanitizedSchema
  };
}

private sanitizeFormSchema(schema: any): any {
  const sanitized = { ...schema };
  
  if (sanitized.sections) {
    sanitized.sections = sanitized.sections.map((section: any) => ({
      ...section,
      questions: section.questions?.map((q: any) => {
        const { correctAnswer, correctAnswers, points, explanation, ...safeQuestion } = q;
        // Only return question data students should see
        return safeQuestion;
      })
    }));
  }
  
  return sanitized;
}
```

**Impact:** Prevents students from seeing answers before submitting.

---

### 2. **LocalStorage Manipulation**
**Risk Level:** 🔴 HIGH  
**Complexity:** 🟢 Low

**Issue:**
Student progress is saved in localStorage without integrity checking. Students can:
- Edit their answers after submission
- Manipulate timer values
- Change question index
- Add fake answers

**How Students Can Exploit:**
```javascript
// In browser console:
const progress = JSON.parse(localStorage.getItem('gabay-exam-progress-{formId}'));
progress.answers['question-1'] = 'New Answer';
progress.timerEndTime = Date.now() + 9999999; // Extend timer
localStorage.setItem('gabay-exam-progress-{formId}', JSON.stringify(progress));
location.reload(); // Changes take effect
```

**Recommended Fix:**
1. **Add integrity hash to localStorage:**
```typescript
// When saving progress
const stateToSave = {
  currentQuestionIndex,
  answers,
  // ... other fields
};

// Create integrity hash
const hash = await crypto.subtle.digest(
  'SHA-256',
  new TextEncoder().encode(JSON.stringify(stateToSave) + SECRET_SALT)
);
const hashHex = Array.from(new Uint8Array(hash))
  .map(b => b.toString(16).padStart(2, '0'))
  .join('');

localStorage.setItem(`gabay-exam-progress-${formId}`, JSON.stringify({
  data: stateToSave,
  hash: hashHex
}));
```

2. **Validate on load:**
```typescript
// When loading progress
const stored = JSON.parse(persistedStateJSON);
const calculatedHash = await crypto.subtle.digest(/* ... */);
if (calculatedHash !== stored.hash) {
  console.warn('[Security] Progress data tampered, starting fresh');
  return createFreshState();
}
```

**Impact:** Detects and prevents localStorage tampering.

---

### 3. **Client-Side Timer Bypass**
**Risk Level:** 🟡 MEDIUM  
**Complexity:** 🟢 Low

**Issue:**
All timer logic runs on the client. Students can:
- Pause JavaScript execution
- Modify `Date.now()` behavior
- Change system clock

**How Students Can Exploit:**
```javascript
// Pause execution in DevTools debugger
// Or override Date.now()
const originalDateNow = Date.now;
Date.now = () => originalDateNow() - 60000; // Go back 1 minute
```

**Recommended Fix:**
1. **Server-side timer validation:**
```typescript
// When submitting
const response = await axios.post('/api/v1/gabay-forms/${formId}/responses', {
  answers,
  metadata: {
    ...userInfo,
    timeTaken, // Client-reported time
    sessionStartTime: state.startTime // Send session start
  }
});

// Server validates:
async submitResponse({ formId, answers, metadata }) {
  const actualTimeTaken = Date.now() - metadata.sessionStartTime;
  const reportedTime = metadata.timeTaken;
  
  // Check if time limit exceeded
  const form = await this.getForm(formId);
  const timeLimit = form.settings.timeLimit * 60; // minutes to seconds
  
  if (actualTimeTaken > timeLimit * 1000) {
    throw new Error('Time limit exceeded');
  }
  
  // Flag suspicious time discrepancies
  if (Math.abs(actualTimeTaken - reportedTime * 1000) > 5000) {
    // Log suspicious activity
    console.warn(`Time manipulation suspected: ${formId}`);
  }
  
  // Store actual server time
  return this.prisma.gabayFormResponse.create({
    data: {
      formId,
      answers,
      metadata: {
        ...metadata,
        serverTimeTaken: Math.floor(actualTimeTaken / 1000),
        timeDiscrepancy: Math.abs(actualTimeTaken - reportedTime * 1000)
      }
    }
  });
}
```

**Impact:** Ensures timer limits are enforced server-side.

---

## 🟡 MEDIUM RISK - Consider Implementing

### 4. **Multiple Browser Tabs / Devices**
**Risk Level:** 🟡 MEDIUM  
**Complexity:** 🟡 Medium

**Issue:**
Students can open the exam in multiple tabs/browsers to:
- Compare questions
- Collaborate with others
- Keep one tab as reference

**Current Behavior:**
- LocalStorage is shared across tabs (same progress)
- No detection of multiple sessions

**Recommended Fix:**
```typescript
// Add session locking
interface PreviewState {
  // ... existing fields
  tabId: string;
  sessionLockTime: number;
}

// On component mount
useEffect(() => {
  const tabId = `tab-${Date.now()}-${Math.random()}`;
  const lockKey = `gabay-exam-lock-${formState.id}`;
  
  // Check for existing active session
  const existingLock = localStorage.getItem(lockKey);
  if (existingLock) {
    const lock = JSON.parse(existingLock);
    const timeSinceLock = Date.now() - lock.timestamp;
    
    if (timeSinceLock < 5000) { // Active within 5 seconds
      alert('This exam is already open in another tab/window. Please close other instances.');
      // Disable submission or redirect
      return;
    }
  }
  
  // Set lock with heartbeat
  const updateLock = () => {
    localStorage.setItem(lockKey, JSON.stringify({
      tabId,
      timestamp: Date.now()
    }));
  };
  
  updateLock();
  const lockInterval = setInterval(updateLock, 2000);
  
  return () => {
    clearInterval(lockInterval);
    const currentLock = localStorage.getItem(lockKey);
    if (currentLock && JSON.parse(currentLock).tabId === tabId) {
      localStorage.removeItem(lockKey);
    }
  };
}, [formState.id]);
```

**Impact:** Warns/prevents multiple concurrent sessions.

---

### 5. **External Resources (Google, AI, Notes)**
**Risk Level:** 🟡 MEDIUM  
**Complexity:** 🔴 High

**Issue:**
Students can:
- Search for answers on Google
- Use ChatGPT/AI assistants
- Keep notes open in another window
- Take screenshots and share

**Current Mitigation:**
- None

**Possible Mitigations:**
1. **Full-screen mode** (can be bypassed)
2. **Blur detection** (when window loses focus)
3. **Screenshot detection** (limited browser support)
4. **Proctor integration** (expensive, complex)

**Recommended Simple Fix:**
```typescript
// Add focus tracking and warnings
const [focusLossCount, setFocusLossCount] = useState(0);

useEffect(() => {
  let blurTimeout: NodeJS.Timeout;
  
  const handleBlur = () => {
    if (!hasStarted) return;
    
    blurTimeout = setTimeout(() => {
      setFocusLossCount(prev => prev + 1);
      toast.warning('Window focus lost. This has been recorded.');
    }, 3000); // Only count if away for 3+ seconds
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
}, [hasStarted]);

// Include in submission
const handleSubmit = async () => {
  await onSubmit({
    answers,
    userInfo,
    timeTaken,
    metadata: {
      focusLossCount, // Teacher can review suspicious activity
      userAgent: navigator.userAgent,
      screenResolution: `${window.screen.width}x${window.screen.height}`
    }
  });
};
```

**Impact:** Provides teachers with suspicious activity indicators.

---

### 6. **Answer Sharing via Screenshots**
**Risk Level:** 🟡 MEDIUM  
**Complexity:** 🟢 Low

**Issue:**
Students can:
- Screenshot questions
- Share with classmates
- Post in group chats

**Recommended Fix:**
```typescript
// Add watermarking to exam content
const Watermark = ({ studentLRN, timestamp }: { studentLRN: string; timestamp: number }) => (
  <div className="fixed inset-0 pointer-events-none z-50 select-none">
    <div className="absolute top-4 right-4 text-xs text-gray-400 opacity-30 rotate-12">
      {studentLRN} • {new Date(timestamp).toLocaleString()}
    </div>
    <div className="absolute bottom-4 left-4 text-xs text-gray-400 opacity-30 -rotate-12">
      {studentLRN} • {new Date(timestamp).toLocaleString()}
    </div>
  </div>
);

// Usage in exam component
{hasStarted && <Watermark studentLRN={studentLRN} timestamp={state.startTime || Date.now()} />}
```

**Impact:** Makes screenshots traceable to specific students.

---

## 🟢 LOW RISK - Nice to Have

### 7. **Question Order Memorization**
**Risk Level:** 🟢 LOW  
**Complexity:** 🟢 Low

**Issue:**
If question shuffling is disabled, students can memorize question order.

**Current Mitigation:**
- Settings allow question shuffling
- Already implemented in `frontend/src/pages/forms/[slug].tsx` (Line 118)

**Status:** ✅ Already handled

---

### 8. **Form Code Inspection**
**Risk Level:** 🟢 LOW  
**Complexity:** 🟢 Low

**Issue:**
Technical students might read React source code.

**Mitigation:**
- Use production build with minification
- Already handled by Next.js in production

**Status:** ✅ Already handled

---

## Priority Implementation Plan

### Phase 1: Critical Security (Week 1)
1. ✅ **Sanitize form data** - Remove correct answers from API response
2. ✅ **Server-side timer validation** - Validate time limits on submission
3. ✅ **LocalStorage integrity check** - Add hash verification

### Phase 2: Enhanced Security (Week 2)
4. ✅ **Multiple tab detection** - Warn about concurrent sessions
5. ✅ **Focus tracking** - Log window blur events
6. ✅ **Student watermarking** - Add visible student ID to pages

### Phase 3: Monitoring (Week 3)
7. ✅ **Suspicious activity logging** - Track and flag anomalies
8. ✅ **Teacher dashboard** - Show focus loss counts, time discrepancies

---

## Simple Security Checklist for K-12

For your K-12 audience, keep it simple:

### ✅ Essential (Must Have)
- [ ] Remove correct answers from client-side form data
- [ ] Validate time limits on server
- [ ] Add session tracking (one student = one active session)

### 🎯 Recommended (Should Have)
- [ ] Track window focus losses
- [ ] Add student watermarks to screenshots
- [ ] Detect localStorage tampering

### 💡 Optional (Nice to Have)
- [ ] Full-screen mode prompt
- [ ] Copy/paste prevention on essay questions
- [ ] IP address logging

---

## Notes for K-12 Context

**Keep in mind:**
1. **Trust over paranoia** - K-12 students are learning. Focus on preventing casual cheating, not defeating hackers.
2. **Educate** - Add a "Academic Integrity" agreement before exams
3. **Balance** - Too many restrictions frustrate honest students
4. **Teacher review** - Provide tools for teachers to spot anomalies, not auto-fail

**Recommended approach:**
- Implement Phase 1 (critical security)
- Add warning messages: "This exam tracks focus losses and unusual activity"
- Give teachers a report showing: time taken, focus losses, submission timestamp
- Let teachers decide on consequences

---

## Testing Cheating Scenarios

Create a test checklist:
- [ ] Can I see answers in browser DevTools?
- [ ] Can I edit localStorage and change answers?
- [ ] Can I extend the timer via DevTools?
- [ ] Can I open multiple tabs?
- [ ] Does the server accept submissions after time limit?
- [ ] Can I submit without starting the exam?

---

## Conclusion

**Current Status:** 🔴 High vulnerability to basic cheating methods

**After Phase 1:** 🟢 Adequate security for K-12 honest students  
**After Phase 2:** 🟡 Good security for most use cases  
**After Phase 3:** 🟢 Strong security with monitoring

For K-12, focus on **Phase 1** immediately, then consider Phase 2 based on teacher feedback.
