# Exam Attempt Tracking - Complete Documentation Guide

> Central hub for all Exam Attempt Tracking documentation

---

## 🆕 What's New in v1.1.0 (October 11, 2025)

**Major Security Enhancements**:
- 🛡️ **DevTools Detection**: 6 detection methods to catch students using browser DevTools
- 📋 **Copy/Paste Tracking**: Monitor and track copy/paste attempts
- 🚫 **Right-Click Blocking**: Disabled context menu during exams
- ⌨️ **Keyboard Shortcuts Blocked**: F12, Ctrl+Shift+I/J/C now blocked
- 🔒 **Persistent Flags**: Security flags never get overwritten once detected

**Critical Bug Fixes**:
- ⏱️ **timeSpent Fix**: Now correctly tracks and updates exam duration
- 🔄 **Auto-Sync Fix**: Stops syncing immediately on submission (no more race conditions)
- 💾 **Flag Preservation**: DevTools and copy/paste counts preserved across syncs

**Updated Thresholds**:
- Resume count: 15 → **5** (stricter)
- Focus loss: 25 → **10** (stricter)
- New: DevTools = **immediate flag**
- New: Copy/paste ≥ **5 = flag**

---

## 📚 Documentation Index

This module provides comprehensive exam attempt tracking for Gabay Forms with real-time progress syncing, abuse detection, and anonymous user support.

### Core Documentation

1. **[Exam Attempt System Overview](./exam-attempt-system.md)** ⭐ START HERE
   - Architecture and components
   - Database schema
   - Backend service implementation
   - Frontend hook implementation
   - Core features and use cases

2. **[Frontend Integration Guide](./exam-attempt-frontend.md)**
   - Form page integration (`forms/[slug].tsx`)
   - InlineExamDialog integration
   - AssessmentExam component
   - Progress persistence with localStorage
   - Submission flow

3. **[Gabay Forms Integration](./exam-attempt-integration.md)**
   - Form response submission integration
   - Attempt completion logic
   - Anonymous user support
   - Assignment integration
   - Data flow diagrams

4. **[API Reference & Troubleshooting](./exam-attempt-api.md)**
   - Complete API endpoint reference
   - Request/response examples
   - Error codes and handling
   - Common issues and solutions
   - Debugging guide
   - Performance considerations

---

## 🚀 Quick Start

### For Developers

**1. Understand the System**
```bash
Read: exam-attempt-system.md (Architecture & Schema)
```

**2. Implement Frontend**
```bash
Read: exam-attempt-frontend.md (Hook usage & Integration)
```

**3. Backend Integration**
```bash
Read: exam-attempt-integration.md (Form submission flow)
```

**4. Debug Issues**
```bash
Read: exam-attempt-api.md (Troubleshooting guide)
```

### For Testers

**Key Test Scenarios**:
1. ✅ Authenticated user takes exam → Check attempt created
2. ✅ Anonymous user takes public form → Check attempt with NULL studentId
3. ✅ Student refreshes page → Check resumeCount increments
4. ✅ Student switches tabs → Check focusLossCount increments
5. ✅ Student submits form → Check attempt status = COMPLETED

**Verification Queries**:
```sql
-- Check attempt created
SELECT * FROM "ExamAttempt" WHERE "sessionId" = 'session_xxx';

-- Check completion
SELECT * FROM "ExamAttempt" 
WHERE "sessionId" = 'session_xxx' AND status = 'COMPLETED';

-- Check suspicious attempts (updated thresholds)
SELECT * FROM "ExamAttempt" 
WHERE "resumeCount" >= 5 
   OR "focusLossCount" >= 10
   OR ("suspiciousFlags"->>'devToolsDetected')::boolean = true
   OR ("suspiciousFlags"->>'copyPasteCount')::int >= 5;
```

---

## ✨ Key Features

### Real-Time Tracking
- ✅ Progress synced every 5 seconds
- ✅ Auto-save to localStorage
- ✅ Resume from last position after refresh

### Abuse Detection & Security
- ✅ Track excessive refreshes (resumeCount)
- ✅ Track focus loss events (tab switches)
- ✅ **DevTools detection** (6 detection methods) - NEW
- ✅ **Copy/paste tracking** - NEW
- ✅ **Right-click blocking** during exams - NEW
- ✅ **Keyboard shortcut blocking** (F12, Ctrl+Shift+I/J/C) - NEW
- ✅ Flag suspicious attempts (thresholds: 5 refreshes, 10 focus losses, DevTools detected, 5+ copy/paste)
- ✅ Store browser fingerprint (userAgent, ipAddress)
- ✅ Preserve security flags across syncs (once detected, always flagged)

### Anonymous Support
- ✅ Works for public forms without authentication
- ✅ Optional studentId field (NULL for anonymous)
- ✅ LRN lookup fallback for identification
- ✅ Completes attempts for all users

### Assignment Integration
- ✅ Links to TimelineAssignment
- ✅ Creates both ExamAttempt and AssignmentSubmission
- ✅ Tracks late submissions
- ✅ Inline exam dialog support

### Progress Persistence
- ✅ localStorage backup
- ✅ Database primary storage
- ✅ Redis caching with graceful fallback
- ✅ Automatic restoration on formId change

---

## 🔧 Technical Stack

**Backend**:
- Node.js + TypeScript
- Prisma ORM (PostgreSQL)
- Redis (caching)
- Next.js API Routes

**Frontend**:
- React + TypeScript
- Custom hooks (`useExamAttempt`)
- localStorage API
- Axios for HTTP

**Database**:
- PostgreSQL (primary)
- Redis (cache)

---

## 📊 Data Model

```
ExamAttempt
├── id (UUID)
├── sessionId (unique) → "session_{timestamp}_{random}"
├── formId → GabayForm
├── studentId? → User (NULL for anonymous)
├── assignmentId? → TimelineAssignment
├── status → IN_PROGRESS | COMPLETED | ABANDONED | SUSPICIOUS
├── attemptNumber (1, 2, 3...)
├── currentQuestion (0-based index)
├── totalQuestions
├── answers (JSON)
├── resumeCount (abuse detection)
├── focusLossCount (abuse detection)
├── timeSpent (seconds - fixed with ref-based calculation)
├── suspiciousFlags (JSON) → { devToolsDetected, copyPasteCount, reasons, flaggedAt }
├── responseId? → GabayFormResponse (set on completion)
└── timestamps (startedAt, lastActivityAt, submittedAt)
```

---

## 🔄 Data Flow Summary

```
1. Student opens form
   └→ useExamAttempt.startAttempt()
      └→ POST /api/v1/exam-attempts/start
         └→ ExamAttemptService.startOrResumeAttempt()
            └→ Returns sessionId

2. Student answers questions
   └→ Progress saved to localStorage
   └→ Every 5 seconds: syncProgress()
      └→ PATCH /api/v1/exam-attempts/{sessionId}/sync
         └→ ExamAttemptService.syncProgress()

3. Student submits form
   └→ POST /api/v1/gabay-forms/{id}/responses
      ├→ Create GabayFormResponse
      ├→ Check metadata.sessionId
      └→ ExamAttemptService.completeAttempt()
         └→ Update status → COMPLETED
         └→ Link responseId
```

---

## 🐛 Common Issues Quick Reference

| Issue | Solution | Reference |
|-------|----------|-----------|
| Attempt not completing | Ensure sessionId in metadata | [API Ref](./exam-attempt-api.md#issue-1-attempt-not-completing) |
| Anonymous users fail | Check studentId is optional | [Integration](./exam-attempt-integration.md#anonymous-user-support) |
| Progress not syncing | Verify sessionId available | [API Ref](./exam-attempt-api.md#issue-3-progress-not-syncing) |
| localStorage not restoring | Check formId tracking | [Frontend](./exam-attempt-frontend.md#progress-persistence) |
| Excessive resumeCount | Review thresholds | [API Ref](./exam-attempt-api.md#issue-6-excessive-resumecount) |
| Hook initialized with empty formId | Wait for formId before starting | [API Ref](./exam-attempt-api.md#issue-7-formid-empty-on-hook-init) |
| Redis cache errors | Gracefully handled | [System](./exam-attempt-system.md#caching-strategy) |

---

## 📈 Monitoring & Analytics

### Key Metrics to Track

1. **Completion Rate**: % of attempts completed vs abandoned
2. **Average resumeCount**: Track refresh patterns
3. **Average focusLossCount**: Track focus patterns
4. **Suspicious Attempts**: Count flagged attempts
5. **Sync Success Rate**: % of successful progress syncs
6. **Cache Hit Rate**: Redis cache effectiveness

### Database Queries

```sql
-- Completion rate by status
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM "ExamAttempt"
GROUP BY status;

-- Average metrics for completed attempts
SELECT 
  AVG("resumeCount") as avg_resume_count,
  AVG("focusLossCount") as avg_focus_loss_count,
  AVG("timeSpent") as avg_time_spent_seconds
FROM "ExamAttempt"
WHERE status = 'COMPLETED';

-- Suspicious attempts by date
SELECT 
  DATE("startedAt") as date,
  COUNT(*) as suspicious_attempts
FROM "ExamAttempt"
WHERE status = 'SUSPICIOUS'
GROUP BY DATE("startedAt")
ORDER BY date DESC;

-- Student attempt history with security flags
SELECT 
  "formId",
  "attemptNumber",
  status,
  "resumeCount",
  "focusLossCount",
  "timeSpent",
  "suspiciousFlags",
  "startedAt",
  "submittedAt"
FROM "ExamAttempt"
WHERE "studentId" = '{student_id}'
ORDER BY "startedAt" DESC;

-- Attempts with DevTools detected
SELECT 
  "sessionId",
  "studentId",
  "formId",
  ("suspiciousFlags"->>'devToolsDetected')::boolean as devtools_detected,
  ("suspiciousFlags"->>'copyPasteCount')::int as copy_paste_count,
  "suspiciousFlags"->>'reasons' as reasons,
  "suspiciousFlags"->>'flaggedAt' as flagged_at
FROM "ExamAttempt"
WHERE ("suspiciousFlags"->>'devToolsDetected')::boolean = true
ORDER BY "startedAt" DESC;

-- Security metrics summary
SELECT 
  COUNT(*) as total_attempts,
  COUNT(CASE WHEN ("suspiciousFlags"->>'devToolsDetected')::boolean = true THEN 1 END) as devtools_attempts,
  COUNT(CASE WHEN ("suspiciousFlags"->>'copyPasteCount')::int >= 5 THEN 1 END) as excessive_copy_paste,
  COUNT(CASE WHEN "focusLossCount" >= 10 THEN 1 END) as excessive_focus_loss,
  COUNT(CASE WHEN status = 'SUSPICIOUS' THEN 1 END) as flagged_suspicious
FROM "ExamAttempt"
WHERE "startedAt" >= NOW() - INTERVAL '7 days';
```

---

## 🔐 Security Considerations

### Implemented Security Features

- ✅ Browser fingerprinting (userAgent, ipAddress)
- ✅ Abuse detection thresholds (adjustable)
- ✅ Focus loss tracking (window blur events)
- ✅ **DevTools detection** (6 methods: window size, Firebug, console detection, timing, shortcuts)
- ✅ **Copy/paste prevention & tracking**
- ✅ **Right-click context menu blocking**
- ✅ **Keyboard shortcut blocking** (F12, Ctrl+Shift+I/J/C)
- ✅ Session-based tracking (prevents tampering)
- ✅ Database-backed verification (not just client-side)
- ✅ Server-side sessionId generation
- ✅ Unique sessionId per attempt
- ✅ Suspicious flag persistence (once detected, stays flagged)
- ✅ Auto-sync stops on submission (prevents race conditions)

### DevTools Detection Methods (Technical Details)

Our system uses **6 different detection methods** to identify if DevTools is open:

1. **Window Size Difference**: Checks if `outerWidth - innerWidth > 160px`
2. **Firebug Legacy Check**: Detects `window.console.firebug`
3. **Screen vs Window Analysis**: Detects if window is too small for screen size
4. **Console Property Getter**: Triggers when console renders objects
5. **Debugger Timing**: Measures delay caused by `debugger` statement
6. **Keyboard Shortcuts**: Blocks F12, Ctrl+Shift+I/J/C

**Limitations**: 
- DevTools in separate window (undocked) may not be detected
- DevTools already open before exam start may bypass initial detection
- Students can disable JavaScript (but exam won't load)

**Recommendation**: Use as deterrent + behavior analysis, not sole security measure

### Suspicious Activity Thresholds

Current thresholds (adjustable in backend):

| Metric | Threshold | Action |
|--------|-----------|--------|
| `resumeCount` | ≥ 5 | Flag as suspicious |
| `focusLossCount` | ≥ 10 | Flag as suspicious |
| `devToolsDetected` | true | Flag immediately |
| `copyPasteCount` | ≥ 5 | Flag as suspicious |

### Best Practices

1. **Never trust client data alone**: Always verify server-side
2. **Review flagged attempts**: Manual instructor review for suspicious cases
3. **Layered security**: Combine DevTools detection + behavior analysis + teacher review
4. **Clear communication**: Inform students about monitoring at exam start
5. **Secure sessionId**: Generated server-side, unique per attempt
6. **Rate limiting**: Consider adding to prevent spam attempts
7. **Audit logs**: Keep comprehensive logs for investigations
8. **Regular monitoring**: Check suspicious attempt patterns

---

## 🔄 Integration Points

### Files Involved

**Backend**:
- `api/src/services/exam-attempt.service.ts` - Core service
- `api/src/pages/api/v1/exam-attempts/start.ts` - Start endpoint
- `api/src/pages/api/v1/exam-attempts/[sessionId]/sync.ts` - Sync endpoint
- `api/src/pages/api/v1/gabay-forms/[id]/responses/index.ts` - Completion integration
- `api/prisma/schema/gabay-form.prisma` - Database schema

**Frontend**:
- `frontend/src/hooks/useExamAttempt.ts` - Main hook
- `frontend/src/pages/forms/[slug].tsx` - Form page integration
- `frontend/src/views/components/subject/timeline/InlineExamDialog.tsx` - Inline exam
- `frontend/src/shad-components/shad/components/gabay-form/new-preview.tsx` - Form renderer

### Key Integration Points

1. **Hook Initialization**: Initialize `useExamAttempt` when form loads
2. **Attempt Start**: Call `startAttempt()` when form is ready
3. **Progress Sync**: Call `syncProgress()` every 5 seconds
4. **Submission**: Include `sessionId` in form submission metadata
5. **Completion**: Backend calls `completeAttempt()` on form submission

---

## 🚀 Future Enhancements

### Planned Features

1. **Advanced Analytics Dashboard**
   - Visualize attempt patterns
   - Identify cheating trends
   - Teacher insights panel
   - Real-time attempt monitoring

2. **Proctoring Integration**
   - Webcam monitoring
   - Screen recording
   - AI-based behavior analysis
   - Face recognition

3. **Adaptive Thresholds**
   - ML-based suspicious activity detection
   - Per-exam configurable thresholds
   - Student history consideration
   - Automatic threshold adjustment

4. **Real-Time Monitoring**
   - Teacher dashboard showing live attempts
   - Alert on suspicious behavior
   - Intervention capabilities (pause/terminate exam)
   - Live chat with student

5. **Detailed Timeline**
   - Question-by-question timing
   - Answer change tracking
   - Activity heatmap
   - Mouse movement patterns

6. **Enhanced Security** (Beyond Current Implementation)
   - Full browser lockdown mode
   - Screenshot detection/prevention
   - Second device detection
   - Network traffic analysis
   - Virtual machine detection

---

## 📖 Reading Path by Role

### Backend Developer
1. [System Overview](./exam-attempt-system.md) - Architecture & schema
2. [Integration Guide](./exam-attempt-integration.md) - Backend integration
3. [API Reference](./exam-attempt-api.md) - Endpoints & debugging

### Frontend Developer
1. [System Overview](./exam-attempt-system.md) - Architecture basics
2. [Frontend Guide](./exam-attempt-frontend.md) - Hook usage & components
3. [API Reference](./exam-attempt-api.md) - API calls & troubleshooting

### Full-Stack Developer
1. [System Overview](./exam-attempt-system.md) - Complete architecture
2. [Frontend Guide](./exam-attempt-frontend.md) - Frontend implementation
3. [Integration Guide](./exam-attempt-integration.md) - Backend integration
4. [API Reference](./exam-attempt-api.md) - Complete reference

### QA/Tester
1. [System Overview](./exam-attempt-system.md#key-features) - Features to test
2. [API Reference](./exam-attempt-api.md#common-issues--solutions) - Test scenarios
3. [Integration Guide](./exam-attempt-integration.md#data-flow-diagrams) - Flow understanding

### DevOps/SRE
1. [System Overview](./exam-attempt-system.md#architecture) - System architecture
2. [API Reference](./exam-attempt-api.md#performance-considerations) - Performance & monitoring
3. [Integration Guide](./exam-attempt-integration.md#error-handling) - Error handling

---

## 📞 Support & Contributing

### Getting Help

**Documentation**:
1. [System Overview](./exam-attempt-system.md) - Architecture & implementation
2. [Frontend Guide](./exam-attempt-frontend.md) - Frontend integration
3. [Integration Guide](./exam-attempt-integration.md) - Backend integration
4. [API Reference](./exam-attempt-api.md) - API & troubleshooting

**For Issues**:
1. Check [Common Issues](./exam-attempt-api.md#common-issues--solutions)
2. Review [Debugging Guide](./exam-attempt-api.md#debugging-guide)
3. Search existing documentation
4. Contact development team

### Reporting Issues

When reporting issues, please include:
- **Student ID** (if applicable)
- **Form ID**
- **SessionId** (from localStorage or logs)
- **Error messages** (frontend console & backend logs)
- **Steps to reproduce**
- **Browser and OS information**
- **Screenshots** (if applicable)

### Contributing

Contributions welcome! Please:
1. Read all documentation thoroughly
2. Follow existing code patterns
3. Add comprehensive logging
4. Write tests for new features
5. Update documentation

---

## 📊 System Health Checklist

### Daily Checks
- [ ] No spike in suspicious attempts
- [ ] Average resumeCount within normal range (< 3)
- [ ] Average focusLossCount within normal range (< 10)
- [ ] Completion rate above 90%
- [ ] No Redis connection errors

### Weekly Review
- [ ] Review flagged suspicious attempts
- [ ] Check database performance
- [ ] Monitor cache hit rates
- [ ] Review error logs
- [ ] Update thresholds if needed

### Monthly Analysis
- [ ] Analyze attempt patterns
- [ ] Review security incidents
- [ ] Update documentation
- [ ] Plan feature enhancements
- [ ] Performance optimization

---

## 🎓 Training Resources

### For New Developers

**Week 1**: Understanding the System
- Day 1-2: Read System Overview
- Day 3-4: Study database schema
- Day 5: Review code implementation

**Week 2**: Hands-On Practice
- Day 1-2: Set up local environment
- Day 3-4: Test existing features
- Day 5: Make small improvements

**Week 3**: Integration Work
- Day 1-3: Implement new feature
- Day 4-5: Write tests and documentation

### For Teachers/Administrators

**Quick Guide**:
1. How to view attempt history
2. How to identify suspicious activity
3. How to handle flagged attempts
4. How to generate reports

---

## 📄 License

Part of Gabay LMS Platform - Proprietary Software

© 2025 Gabay. All rights reserved.

---

## 🎉 Summary

The Exam Attempt Tracking system provides:

✅ **Comprehensive Tracking** - Real-time progress monitoring  
✅ **Abuse Detection** - Automatic flagging of suspicious behavior  
✅ **Anonymous Support** - Works for all user types  
✅ **Seamless Integration** - Works with Gabay Forms and Assignments  
✅ **Production Ready** - Tested, documented, deployed  

**Ready to use!** 🚀

---

## 📝 Changelog

### Version 1.1.0 - October 11, 2025

**New Security Features**:
- ✅ DevTools detection (6 detection methods)
- ✅ Copy/paste tracking
- ✅ Right-click blocking during exams
- ✅ Keyboard shortcut blocking (F12, Ctrl+Shift+I/J/C)
- ✅ Suspicious flag persistence across syncs

**Bug Fixes**:
- ✅ Fixed timeSpent always being 0 (ref-based calculation)
- ✅ Fixed auto-sync continuing after submission
- ✅ Fixed DevTools flag being overwritten on subsequent syncs

**Backend Improvements**:
- ✅ Preserve security metrics even when not suspicious yet
- ✅ Updated suspicious activity thresholds (5 refreshes, 10 focus losses)
- ✅ Enhanced suspicious flags JSON structure

### Version 1.0.0 - January 2025
- Initial production release
- Core exam attempt tracking
- Anonymous user support
- Assignment integration

---

**Last Updated**: October 11, 2025  
**Version**: 1.1.0  
**Status**: ✅ Production Ready  
**Documentation Completeness**: 100%
