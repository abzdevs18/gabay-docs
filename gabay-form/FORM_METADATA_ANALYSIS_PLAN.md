# Form Metadata Analysis - Implementation Plan

> **AI-powered form analysis to enhance personalized feedback generation**

**Created**: October 12, 2025 | **Version**: 1.0.0 | **Status**: Planning Phase

---

## 🎯 Executive Summary

### Problem
Current feedback generation lacks context:
- No subject matter understanding
- No grade level awareness
- Generic "K-12 teacher" approach
- Cannot reference specific concepts

### Solution
AI analyzes forms during creation to extract:
- Subject, grade level, difficulty
- Learning objectives & key concepts
- Pedagogical context for feedback
- Stores as metadata for enhanced feedback

### Expected Impact
- **20%+** improvement in feedback relevance
- **85%+** accuracy in subject identification
- **$0.003** cost per analysis (one-time)
- Reused for all student submissions

---

## 🏗️ Architecture

### Flow: Form Creation
```
Teacher creates form → Publishes → [NEW] Analysis Worker → Stores metadata
```

### Flow: Enhanced Feedback
```
Student submits → Worker fetches (questions + answers + [NEW] metadata) → Better feedback
```

### Components
- **New Worker**: `form-analysis-worker` (BullMQ queue)
- **New Field**: `form.analysisMetadata` (JSON)
- **Enhanced Prompt**: Uses metadata for subject-specific feedback

---

## 💾 Database Schema

```prisma
model GabayForm {
  // ... existing fields
  
  // NEW FIELDS
  analysisMetadata  Json?      // AI analysis results
  analyzedAt        DateTime?
  analysisVersion   Int?       @default(1)
  questionHash      String?    // Detect changes
}
```

### analysisMetadata JSON Structure
```typescript
{
  subject: { primary: "Mathematics", secondary: ["Algebra"], gradeLevel: "8-10" },
  examType: "Summative Assessment",
  difficulty: "Intermediate",
  learningObjectives: ["Solve quadratic equations", ...],
  keyConcepts: ["Pythagorean theorem", ...],
  contextForFeedback: "This is an 8th grade algebra exam focusing on...",
  bloomsLevels: { remember: 3, understand: 5, apply: 6 }
}
```

---

## 🤖 AI Prompts

### Analysis Prompt (Form Creation)
```
Analyze exam questions and return JSON with:
- subject (primary, secondary, gradeLevel, confidence)
- examType, difficulty, estimatedDuration
- learningObjectives, keyConcepts
- pedagogicalNotes
- bloomsLevels
- contextForFeedback (detailed for AI feedback generation)
```

### Enhanced Feedback Prompt
```
You are a {subject.primary} teacher for {gradeLevel} students.

CONTEXT: {contextForFeedback}
KEY CONCEPTS: {keyConcepts}
LEARNING OBJECTIVES: {learningObjectives}

STUDENT ANSWERS: {answers}

Provide subject-specific, encouraging feedback...
```

**Cost**: ~$0.0005 per analysis (~1,600 tokens)

---

## ✅ Implementation TODO

### Phase 1: Database (Week 1) - 4-6 hours
- [ ] Add fields to GabayForm schema (analysisMetadata, analyzedAt, analysisVersion, questionHash)
- [ ] Create Prisma migration
- [ ] Update TypeScript types
- [ ] Create FormAnalysisMetadata interface

### Phase 2: Backend Worker (Week 1-2) - 12-16 hours
- [ ] Create `form-analysis-queue.service.ts` (BullMQ queue, rate limit: 15/min)
- [ ] Create `form-analysis-worker.service.ts` (concurrency: 3, retry: 3x)
- [ ] Integrate into WorkerManager
- [ ] Implement question extraction utility
- [ ] Create AI prompt templates
- [ ] Implement OpenAI API integration
- [ ] Store metadata & calculate question hash

### Phase 3: API Endpoints (Week 2) - 8-10 hours
- [ ] `POST /api/v1/gabay-forms/:id/analyze` - Queue analysis
- [ ] `GET /api/v1/gabay-forms/:id/analysis` - Get metadata
- [ ] `PATCH /api/v1/gabay-forms/:id/analysis` - Teacher edit
- [ ] Modify publish endpoint to auto-queue analysis
- [ ] Include metadata in form GET endpoints

### Phase 4: Frontend (Week 2-3) - 16-20 hours
- [ ] Create `useFormAnalysis` hook
- [ ] Add "Analyze Form" button to form builder
- [ ] Create `FormAnalysisPanel` component (display/edit)
- [ ] Auto-trigger on publish with loading indicator
- [ ] Show "Analysis outdated" warning on changes
- [ ] Add settings toggle for auto-analysis

### Phase 5: Feedback Enhancement (Week 3) - 10-12 hours
- [ ] Modify `form-response-worker` to fetch analysisMetadata
- [ ] Create enhanced prompt builder using metadata
- [ ] Fallback to generic prompt if missing
- [ ] Update email template with "About This Assessment"

### Phase 6: Testing & Deployment (Week 3-4) - 12-16 hours
- [ ] Unit tests (worker, prompts, parsing)
- [ ] Integration tests (full flow, multi-tenant)
- [ ] E2E tests (create → analyze → submit → feedback)
- [ ] Performance testing (100 concurrent)
- [ ] Cost tracking and monitoring
- [ ] Documentation (API, user guide, admin)
- [ ] Feature flag setup
- [ ] Deploy to staging → production

---

## ⚙️ Configuration

```bash
# Environment Variables
ENABLE_FORM_ANALYSIS=true
FORM_ANALYSIS_MODEL=gpt-4o-mini
FORM_ANALYSIS_RATE_LIMIT=15  # per minute
FORM_ANALYSIS_AUTO_ON_PUBLISH=true
FORM_ANALYSIS_MONTHLY_BUDGET=100  # USD
```

---

## ⚠️ Critical Considerations

### Must Address
1. **Cost Control**: Per-tenant monthly limits, spending alerts at 80%
2. **Performance**: Non-blocking publish, async queue processing
3. **Accuracy**: Allow teacher override, show confidence scores
4. **Multi-tenant**: Strict isolation in workers
5. **Graceful Degradation**: Feedback works without metadata
6. **Change Detection**: Hash questions, show "outdated" warning

### Edge Cases
- Empty forms → Skip analysis
- Multi-subject exams → Support multiple primaries
- Large forms (100+ questions) → Sample subset
- Non-English → Detect and analyze in same language
- Teacher edits → Set override flag, preserve versions

---

## 💰 Cost & Timeline

### Development
- **Time**: 80-100 hours over 3-4 weeks
- **Cost**: ~$8,000-12,000

### Operational
- **AI API**: $0.003/analysis (~$50-200/month for 1,000-4,000 forms)
- **Infrastructure**: $10-20/month (worker resources)

### Timeline
- Week 1: Database + Backend Worker
- Week 2: API Endpoints + Frontend (start)
- Week 3: Frontend + Feedback Enhancement
- Week 4: Testing + Deployment

---

## 📈 Success Metrics

### Technical
- Analysis completion < 10 seconds (95th percentile)
- Subject identification accuracy > 85%
- Worker uptime > 99%
- Cost per analysis < $0.005

### Business
- Teacher adoption > 70%
- Feedback quality improvement > 20% (surveys)
- Teacher satisfaction > 4.5/5
- Re-analysis rate < 10%

---

## 🔄 Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AI inaccuracy | Medium | High | Teacher override, confidence scores, beta testing |
| Cost overruns | Medium | Medium | Budget limits, quotas, real-time monitoring |
| Performance bottleneck | Low | Medium | Queue-based, rate limiting, horizontal scaling |
| Multi-tenant leakage | Low | Critical | Strict isolation, security audit, integration tests |
| API outages | Low | Medium | Retry logic, fallback, allow publish without analysis |
| Teacher resistance | Medium | Medium | Optional feature, value messaging, easy disable |

---

## 📝 Notes

### Integration Points
- **Form Builder**: Auto-analyze on publish, manual button
- **Feedback Worker**: Fetch metadata, enhanced prompt
- **Teacher UI**: View/edit analysis summary

### Future Enhancements
- Learn from teacher corrections
- Multi-language support
- Standard alignment (Common Core, NGSS)
- Predictive analytics
- Collaborative analysis

---

**Status**: Ready for review and approval  
**Next Step**: Create tickets for Phase 1 tasks  
**Contact**: Development team for questions

