# Exam Progress Persistence System

## Overview
The exam/assessment system now includes automatic progress tracking that allows students to resume their exam from where they left off, even after closing the browser or refreshing the page.

## Features Implemented

### 1. **Automatic Progress Saving**
- ✅ Current question position
- ✅ All submitted answers
- ✅ Student information (Name, LRN, Email)
- ✅ Timer state (overall and per-question)
- ✅ Session tracking with unique session IDs
- ✅ Attempt number tracking

### 2. **Resume Capability**
- Students can:
  - Close browser and return later
  - Refresh the page without losing progress
  - Continue from the exact question they left off
  - Maintain timer continuity (time continues counting even when offline)

### 3. **Visual Feedback**
- "Progress Restored!" banner when resuming
- Shows current question number
- Displays number of saved answers
- Button changes from "Start Assessment" to "Continue Assessment"
- Green emerald theme for resume state

### 4. **Smart Timer Handling**
- Tracks timer expiration even during offline periods
- If timer expires while student is offline, auto-submits on return
- Maintains per-question timer state

### 5. **Automatic Cleanup**
- Progress is cleared from localStorage on successful submission
- No manual intervention needed

## Technical Implementation

### Storage Key Format
```
gabay-exam-progress-{formId}
```

### Stored Data Structure
```typescript
{
  currentQuestionIndex: number;
  answers: Record<string, any>;
  fullName: string;
  email: string;
  lrn: string;
  formStarted: boolean;
  timerEndTime?: number;
  startTime?: number;
  currentQuestionEndTime?: number;
  currentQuestionStartTime?: number;
  attemptNumber: number;
  sessionId: string;
}
```

### Key Files Modified
1. **`frontend/src/shad-components/shad/components/gabay-form/new-preview.tsx`**
   - Added `attemptNumber` and `sessionId` to state
   - Enhanced `createInitialState()` to properly restore all state
   - Added `useEffect` to persist state on every change
   - Modified `handleSubmit()` to clear localStorage
   - Added visual "Progress Restored" banner
   - Changed button text/color for resume state

## How It Works

### 1. **On Initial Load**
```typescript
createInitialState(formId)
  ├─ Check localStorage for existing progress
  ├─ If found:
  │   ├─ Parse saved state
  │   ├─ Check if timer expired
  │   ├─ Restore all fields (question index, answers, timers)
  │   └─ Log resume details
  └─ If not found:
      └─ Create fresh state with new session ID
```

### 2. **During Exam**
```typescript
useEffect hook monitors:
  ├─ currentQuestionIndex
  ├─ answers
  ├─ userInfo (name, email, LRN)
  ├─ timerEndTime
  └─ All timing data

On any change → Save to localStorage immediately
```

### 3. **On Submission**
```typescript
handleSubmit()
  ├─ Set completed flag
  ├─ Clear localStorage progress
  ├─ Submit answers to server
  └─ Show success message
```

## Important Notes

### Limitations
1. **Device-Specific**: Progress is saved per browser/device
   - Students switching devices will start fresh
   - Consider server-side persistence for cross-device support
   
2. **Browser Storage**: Uses localStorage
   - Limited to ~5-10MB depending on browser
   - Clearing browser data will erase progress
   
3. **Security**: 
   - Data stored in plain text in localStorage
   - No encryption (answers visible in browser DevTools)
   - For sensitive exams, consider adding encryption

### Best Practices

1. **Test Scenarios**:
   - Refresh during exam
   - Close and reopen browser
   - Timer expiration during offline
   - Network interruption during exam
   - Multiple tabs (localStorage is shared)

2. **Future Enhancements**:
   - Server-side progress backup every N seconds
   - Cross-device sync via API
   - Offline mode with service workers
   - Encrypted storage for sensitive data
   - Conflict resolution for multiple tabs

## Testing the Feature

### Manual Testing Steps

1. **Start an exam**:
   ```
   - Navigate to /forms/{slug}
   - Enter student information
   - Click "Start Assessment"
   - Answer 2-3 questions
   ```

2. **Refresh the page**:
   ```
   - Press F5 or Ctrl+R
   - Should see "Progress Restored!" banner
   - Button should say "Continue Assessment"
   - Click button to resume
   ```

3. **Verify state**:
   ```
   - Should be on the same question
   - Previous answers should be preserved
   - Timer should continue from where it left off
   ```

4. **Complete and submit**:
   ```
   - Finish remaining questions
   - Submit the exam
   - Check DevTools → localStorage should be empty
   ```

### DevTools Inspection

Open browser DevTools → Application → Local Storage:
```
Key: gabay-exam-progress-{formId}
Value: {JSON object with all progress data}
```

## Console Logs

The system logs helpful information:

- `[Exam Start]` - New attempt created
- `[Exam Resume]` - Progress restored with details
- `[Exam Persist]` - Progress saved (on every change)
- `[Exam Submit]` - Progress cleared

## Future Considerations

### Server-Side Persistence (Recommended)
For production use, consider:

1. **API Endpoint**: `POST /api/exams/{formId}/progress`
   ```typescript
   {
     studentId: string;
     currentQuestionIndex: number;
     answers: Record<string, any>;
     timestamp: number;
   }
   ```

2. **Benefits**:
   - Cross-device support
   - Better security
   - Admin monitoring
   - Recovery options
   - Audit trail

3. **Implementation**:
   - Save to server every 30 seconds
   - Use localStorage as backup
   - Sync on reconnection
   - Handle conflicts gracefully

## Troubleshooting

### Progress Not Restoring
- Check browser console for errors
- Verify localStorage is enabled
- Check if localStorage has data
- Ensure formId matches

### Timer Issues
- Check if `timerEndTime` is valid timestamp
- Verify timer calculations
- Test with different time limits

### Answers Not Saving
- Check `useEffect` dependencies
- Verify dispatch actions are firing
- Inspect localStorage structure

## Support

For issues or questions, check:
1. Browser console logs (`[Exam ...]` messages)
2. DevTools → Application → Local Storage
3. Network tab for API calls (when implemented)
