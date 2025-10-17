# Gabay Form - AI Feedback System

> Automatic personalized feedback for every student submission

---

## Overview

The AI Feedback System automatically generates personalized, encouraging feedback for students after they complete assessments. Using advanced GPT models, it analyzes their responses and provides constructive guidance.

---

## How It Works

### 1. Student Submits Form

```
Student fills out exam → Clicks Submit
                              ↓
                    API saves response
                              ↓
                    Job queued for processing
                              ↓
                    Student sees confirmation
```

**Time:** <200ms (synchronous)

### 2. Background Processing

```
Worker picks up job → Fetches form data
                              ↓
                    Analyzes answers
                              ↓
                    Generates AI prompt
                              ↓
                    Calls OpenAI API
                              ↓
                    Receives feedback
                              ↓
                    Creates email HTML
                              ↓
                    Sends email
```

**Time:** 5-8 seconds (asynchronous)

### 3. Student Receives Email

Beautiful HTML email with:
- Personal greeting
- Completion statistics
- AI-generated feedback
- Study recommendations
- Encouragement

---

## AI Models

### Supported Models

| Model | Provider | Cost | Speed | Quality |
|-------|----------|------|-------|---------|
| `gpt-4o-mini` | OpenAI | $0.15/1M | Fast | High |
| `gpt-5-nano` | OpenAI | $0.10/1M | Fastest | Good |
| `deepseek-chat` | DeepSeek | Varies | Fast | Good |

### Configuration

```bash
# .env
OPENAI_API_KEY=sk-...
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_FEEDBACK_MODEL=gpt-4o-mini  # Override for feedback
DEEPSEEK_API_KEY=sk-...  # Fallback
```

---

## Automatic Scoring

Before AI feedback generation, the system automatically scores student responses:

### Supported Question Types

| Question Type | Answer Field | Scoring Method |
|--------------|-------------|----------------|
| **Multiple Choice** | `correctAnswerIds` | Checks if student's answer ID is in array |
| **True/False** | `correctAnswerIds` | Same as multiple choice |
| **Checkbox** | `correctAnswerIds` | All selected IDs must match (exact match) |
| **Dropdown** | `correctAnswerIds` | Same as multiple choice |
| **Fill-in-Blank** | `correctAnswers` | Case-insensitive string matching |
| **Short Answer** | `correctAnswers` | Multiple acceptable answers supported |
| **Identification** | `correctAnswers` | Trimmed, case-insensitive comparison |
| **Essay** | N/A | Manual grading (no auto-scoring) |

### Scoring Logic

**Choice-Based Questions** (Multiple Choice, True/False, Dropdown):
```typescript
// Student answer: "choice_1"
// Correct answers: ["choice_1"]
isCorrect = correctAnswerIds.includes(studentAnswer);
```

**Multi-Select (Checkbox)**:
```typescript
// Student answer: ["choice_1", "choice_3"]
// Correct answers: ["choice_1", "choice_3"]
isCorrect = studentAnswer.length === correctAnswerIds.length && 
            studentAnswer.every(ans => correctAnswerIds.includes(ans));
```

**Text-Based Questions**:
```typescript
// Student answer: "Photosynthesis"
// Correct answers: ["photosynthesis", "photo synthesis"]
normalizedStudent = studentAnswer.trim().toLowerCase();
isCorrect = correctAnswers.some(ca => 
  ca.trim().toLowerCase() === normalizedStudent
);
```

### Correct Answer Detection

The system intelligently finds correct answers from multiple possible locations:

1. **Primary Fields:**
   - `correctAnswerIds` - For choice-based questions
   - `correctAnswers` - For text-based questions

2. **Legacy Fields:**
   - `correctAnswer`, `answer`, `correct_answer`

3. **Embedded in Options:**
   - `options[].isCorrect = true`
   - `choices[].isCorrect = true`

4. **Validation Objects:**
   - `validation.correctAnswer`
   - `settings.correctAnswer`

This multi-path detection ensures compatibility with forms created by different builders and versions.

### Score Calculation

```
correctCount = number of correct answers
totalQuestions = number of questions with defined correct answers
scorePercentage = (correctCount / totalQuestions) × 100
```

**Example:**
- Total Questions: 10
- Correct Answers: 7
- Score: 70%

---

## Feedback Generation

### AI Prompt

The system uses a carefully crafted prompt:

```
You are an encouraging and supportive K-12 teacher providing 
personalized feedback to students after completing an exam.

Your feedback should:
1. Be warm, encouraging, and age-appropriate
2. Acknowledge effort and completion
3. Identify 2-3 specific strengths based on their answers
4. Suggest 1-2 areas for improvement (gently and constructively)
5. Provide specific study tips related to the exam content
6. End with an encouraging message

Keep the tone positive and motivating.
Length: 250-350 words.
```

### Context Provided

```
Exam: Math Quiz

ACTUAL SCORE:
- Correct Answers: 7 out of 10
- Incorrect Answers: 3
- Points Earned: 70 out of 100
- Score Percentage: 70%

Statistics:
- Total Questions: 10
- Questions Answered: 10
- Total Possible Points: 100
- Time Taken: 5 minutes

Questions and Answers (with correctness marked):
Question 1: What is 2+2?
Type: MULTIPLE_CHOICE
Points: 10
Student's Answer: choice_1
Correct Answer: choice_1
✅ CORRECT

Question 2: What is the capital of France?
Type: MULTIPLE_CHOICE
Points: 10
Student's Answer: choice_2
Correct Answer: choice_3
❌ INCORRECT

...
```

### Example Output

```
Great job on completing the Math Quiz, John! 🎉

I'm impressed by your effort and dedication. You answered all 
10 questions and showed a strong understanding of the material.

Your Strengths:
✅ Excellent work on arithmetic problems! Your calculations 
   were accurate and well-thought-out.
✅ Strong grasp of geography concepts, especially with 
   European capitals.
✅ Great time management - you completed the quiz efficiently 
   without rushing.

Areas for Growth:
💡 Review fraction operations, particularly when working with 
   mixed numbers.
💡 Practice identifying prime numbers - a quick review of 
   factors will help!

Study Tips:
- Create flashcards for key math formulas
- Try online practice quizzes for geography
- Review your notes on number theory

Keep up the fantastic work! Your dedication to learning shows, 
and I'm confident you'll continue to improve. Remember, every 
challenge is an opportunity to grow stronger! 🌟

Well done!
```

---

## Email Template

### Structure

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    /* Modern, responsive CSS */
    /* Mobile-optimized */
    /* Professional appearance */
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <h1>🎓 Exam Completed!</h1>
    <p>Hi John Doe,</p>
    
    <!-- Stats Cards -->
    <div class="stats">
      <div class="stat-card">
        <strong>Questions:</strong> 10/10
      </div>
      <div class="stat-card">
        <strong>Time:</strong> 5 minutes
      </div>
      <div class="stat-card">
        <strong>Completion:</strong> 100%
      </div>
    </div>
    
    <!-- AI Feedback -->
    <div class="feedback-section">
      <h2>📝 Personalized Feedback</h2>
      <div class="feedback-content">
        [AI-generated feedback here]
      </div>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <p>This is an automated email from Gabay Assessment Platform.</p>
      <p>© 2025 Gabay. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
```

### Features

- ✅ Mobile-responsive
- ✅ Beautiful typography
- ✅ Clear hierarchy
- ✅ Professional branding
- ✅ Multi-tenant customization

---

## Performance & Cost

### Processing Metrics

| Metric | Value |
|--------|-------|
| Queue → Worker | <50ms |
| Fetch Data | ~100ms |
| AI Generation | 3-5s |
| Email Send | 1-2s |
| **Total Time** | **5-8s** |

### Throughput

- **Rate Limit**: 10 feedbacks/minute
- **Concurrency**: 3 simultaneous
- **Daily Capacity**: ~14,400/day

### Cost Analysis

**Per Feedback (gpt-4o-mini):**
- Input tokens: ~800 (~$0.0001)
- Output tokens: ~400 (~$0.0001)
- **Total: ~$0.0002**

**Monthly Estimates:**
- 1,000 submissions: $0.20
- 10,000 submissions: $2.00
- 100,000 submissions: $20.00

💰 **Extremely cost-effective!**

---

## Multi-Tenant Support

### Tenant Isolation

The system maintains complete data isolation:

```
Student submits (Tenant A)
        ↓
Job includes tenantId + tenantToken
        ↓
Worker uses Tenant A's Prisma client
        ↓
Fetches from tenant_a.gabay_forms
        ↓
Email sent with Tenant A branding
```

**Guarantees:**
- ✅ Correct database schema
- ✅ Proper data isolation
- ✅ Tenant-specific emails
- ✅ No cross-tenant leakage

---

## Configuration Options

### Disable AI Feedback

```typescript
// worker-manager.service.ts
const workerManager = WorkerManager.getInstance({
  enableFormResponseWorker: false
});
```

### Adjust Concurrency

```typescript
// form-response-worker.service.ts
concurrency: 5  // Process 5 jobs at once
```

### Change Rate Limit

```typescript
// form-response-queue.service.ts
limiter: {
  max: 20,        // 20 jobs
  duration: 60000 // per minute
}
```

### Switch AI Provider

```bash
# Use DeepSeek instead
OPENAI_FEEDBACK_MODEL=deepseek-chat
```

---

## Monitoring

### Log Output

```bash
📧 Form Response - Active: 2, Waiting: 5, Completed: 1,234, Failed: 0
🔄 [FormResponse] Processing response abc-123
📧 [FormResponse] Student email: student@school.com
🏢 [FormResponse] Tenant: school_alpha
📚 [FormResponse] Analyzing 10 questions

[SCORING] Summary: {
  totalQuestions: 10,
  correctCount: 7,
  incorrectCount: 3,
  pointsEarned: 70,
  totalPoints: 100,
  scorePercentage: 70,
  hasCorrectAnswers: 10
}

[FormResponse] Using openai provider with model: gpt-4o-mini
[FormResponse] AI feedback generated (1,958 chars)
📤 [FormResponse] Sending email to student@school.com...
✅ [FormResponse] Feedback email sent
✅ [FormResponse] Response processed successfully
```

**Scoring Warnings** (only shown if issues detected):
```bash
[SCORING] 2/10 questions missing correct answers. Sample: {
  id: 'q_1',
  type: 'MULTIPLE_CHOICE',
  hasCorrectAnswerIds: false,
  fields: ['id', 'type', 'title', 'choices']
}

[SCORING] Question "What is X?" (MULTIPLE_CHOICE) missing correct answer. 
Available fields: ['id', 'type', 'title', 'choices', 'required']
```

### Queue Stats

```bash
redis-cli LLEN bull:form-response-processing:wait
redis-cli LLEN bull:form-response-processing:active
redis-cli LLEN bull:form-response-processing:completed
```

---

## Troubleshooting

### No Email Received

**Possible Causes:**
1. Missing `respondentEmail` in form metadata
2. Invalid email address
3. Brevo API key not configured
4. Worker not running

**Solutions:**
```bash
# Check worker status
npm run start:workers

# Verify email in metadata
# Form must collect respondentEmail field

# Check Brevo API key
echo $BREVO_API_KEY

# View logs
tail -f logs/worker.log
```

### Generic Feedback

**Cause:** AI API key invalid or quota exceeded

**Solution:**
```bash
# Verify OpenAI API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check quota
# https://platform.openai.com/usage
```

### Score Shows 0% Despite Correct Answers

**Cause:** Correct answers not properly configured in form questions

**Solution:**
1. **Check logs** for scoring details:
   ```bash
   [SCORING] Summary: {
     correctCount: 0,
     hasCorrectAnswers: 0  # ← Should match totalQuestions
   }
   ```

2. **Verify question structure** - ensure questions have:
   - Multiple Choice: `correctAnswerIds` field (array of choice IDs)
   - Text Questions: `correctAnswers` field (array of strings)

3. **Example correct format:**
   ```json
   {
     "type": "MULTIPLE_CHOICE",
     "correctAnswerIds": ["choice_1"],
     "choices": [...]
   }
   ```

4. **Check warning logs:**
   ```bash
   [SCORING] Question "..." missing correct answer
   ```
   This shows which questions lack correct answer definitions.

### Worker Not Processing

**Cause:** Redis connection issue

**Solution:**
```bash
# Check Redis
redis-cli ping

# Restart Redis (if needed)
redis-server

# Restart workers
npm run start:workers
```

---

## Security & Privacy

### Data Protection

- ✅ Email addresses validated
- ✅ Student data not logged externally
- ✅ Minimal context sent to AI
- ✅ Tenant isolation maintained
- ✅ GDPR/FERPA compliant

### AI Safety

- No PII sent to AI (only answers)
- No student names in prompts (anonymized)
- Feedback reviewed for appropriateness
- Family-friendly content only

---

## Future Enhancements

**Planned Features:**
- [ ] Customizable feedback templates
- [ ] Teacher review before sending
- [ ] Multilingual support
- [ ] Voice feedback (audio)
- [ ] Video feedback
- [ ] Parent CC option
- [ ] Feedback history tracking
- [ ] A/B testing for prompts

---

## Related Documentation

- [Worker System](./worker-system.md)
- [Multi-Tenant Support](../../MULTI_TENANT_WORKER_SUPPORT.md)
- [Form Response Worker](../../FORM_RESPONSE_WORKER_SYSTEM.md)
- [API Cost Estimate](../../AI_FEEDBACK_COST_ESTIMATE.md)
