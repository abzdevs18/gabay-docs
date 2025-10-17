# Teacher's Guide: Monitoring Exam Security

## Quick Reference: What to Look For

When reviewing student submissions, these indicators help identify potential academic dishonesty:

---

## 🚨 Red Flags

### 1. High Focus Loss Count
**What it means:** Student switched away from the exam window multiple times.

**When to investigate:**
- ✅ **Normal**: 0-2 focus losses (accidentally clicking elsewhere)
- ⚠️ **Suspicious**: 3-5 focus losses (possible research/notes)
- 🚨 **High Risk**: 6+ focus losses (likely using external resources)

**Example:**
```
Student A: focusLossCount = 1 ✅ Acceptable
Student B: focusLossCount = 8 🚨 Investigate
```

---

### 2. Time Discrepancy
**What it means:** Difference between the time the student claims they took vs. what the server calculated.

**When to investigate:**
- ✅ **Normal**: 0-5 seconds difference (network latency)
- ⚠️ **Suspicious**: 6-30 seconds difference (possible minor tampering)
- 🚨 **High Risk**: 30+ seconds difference (likely timer manipulation)

**Example:**
```json
{
  "timeTaken": 600,  // Student claims 10 minutes
  "serverCalculatedTime": 750,  // Server says 12.5 minutes
  "timeDiscrepancy": 150  // 2.5 minute difference 🚨
}
```

---

### 3. Suspicious Activity Flags
**What it means:** System detected unusual behavior.

**Possible flags:**
- `TIME_DISCREPANCY` - Client and server time don't match
- (More flags may be added in future updates)

**Example:**
```json
{
  "suspiciousActivity": ["TIME_DISCREPANCY"]
}
```

---

## 📊 How to Review Submissions

### Step 1: Export Submissions
1. Go to your exam's responses page
2. Download the CSV export
3. Look for these columns:
   - `focusLossCount`
   - `serverCalculatedTime`
   - `timeTaken`
   - `timeDiscrepancy`

### Step 2: Sort by Risk Level
```
High Risk Students:
- focusLossCount >= 6
- timeDiscrepancy >= 30

Medium Risk Students:
- focusLossCount = 3-5
- timeDiscrepancy = 6-29

Low Risk Students:
- focusLossCount = 0-2
- timeDiscrepancy = 0-5
```

### Step 3: Take Action
**For High Risk Students:**
1. Review their answers for unusual patterns
2. Compare with their typical performance
3. Consider:
   - One-on-one conversation
   - Oral exam for verification
   - Grade adjustment if confirmed

**For Medium Risk Students:**
1. Monitor for patterns across multiple exams
2. Document for future reference
3. Consider a warning if repeated

**For Low Risk Students:**
1. No action needed
2. These are normal behaviors

---

## 💡 Understanding the Data

### Focus Loss Scenarios

#### Legitimate Reasons (Don't penalize):
```
focusLossCount = 1-2
- Phone notification accidentally clicked
- Parent walked into room
- Quick bathroom break
- Email notification popped up
```

#### Suspicious Reasons (Investigate):
```
focusLossCount = 6+
- Googling answers
- Using ChatGPT
- Checking notes in another window
- Collaborating via messaging apps
```

---

### Time Discrepancy Scenarios

#### Normal (Network issues):
```
timeDiscrepancy = 0-5 seconds
- Slow internet connection
- Server processing delay
- Normal browser variation
```

#### Suspicious (Tampering):
```
timeDiscrepancy = 30+ seconds
- Attempted to pause timer
- Browser DevTools manipulation
- System clock changes
```

---

## 🎯 Best Practices

### Before the Exam
1. **Set Clear Expectations**
   ```
   "This exam tracks:
   - Time taken
   - Window focus losses
   - Submission timestamp
   
   Academic integrity violations will result in consequences."
   ```

2. **Test the System**
   - Take the exam yourself
   - Check that tracking works
   - Verify data appears correctly

3. **Communicate Limitations**
   - Students should use a quiet space
   - Close other apps before starting
   - Avoid interruptions during exam

### During the Exam
1. **Monitor in Real-Time**
   - Watch for submissions
   - Check completion rates
   - Note unusual timing patterns

2. **Be Available**
   - Technical issues happen
   - Have a backup plan
   - Document special circumstances

### After the Exam
1. **Review Data Systematically**
   - Don't jump to conclusions
   - Consider context
   - Document findings

2. **Follow Due Process**
   - Give students a chance to explain
   - Check for patterns
   - Apply policies consistently

---

## 📋 Sample Review Checklist

```markdown
## Submission Review: [Student Name]

### Basic Info
- [ ] Student ID/LRN confirmed
- [ ] Submission timestamp within deadline
- [ ] All questions attempted

### Security Metrics
- [ ] Focus Loss Count: ____ (Normal: 0-2, Flag: 3+)
- [ ] Time Discrepancy: ____ sec (Normal: 0-5, Flag: 6+)
- [ ] Suspicious Flags: ____ (None expected)

### Risk Assessment
- [ ] Low Risk (no action)
- [ ] Medium Risk (monitor)
- [ ] High Risk (investigate)

### Action Items
- [ ] No action needed
- [ ] Document for future reference
- [ ] Schedule follow-up conversation
- [ ] Recommend grade review
- [ ] Report to administration

### Notes
[Your observations here]
```

---

## 🔍 Common Scenarios

### Scenario 1: Perfect Student, High Focus Loss
```
Student: Top performer, always honest
Focus Loss: 8
Time: Normal
Answer Quality: Excellent

Possible explanation: Technical issue, family emergency
Action: Talk to student, give benefit of doubt
```

### Scenario 2: Struggling Student, Low Focus Loss
```
Student: Usually struggles
Focus Loss: 1
Time: Very fast (suspiciously fast)
Answer Quality: Perfect

Possible explanation: Cheating (prepared answers)
Action: Investigate, possible oral exam
```

### Scenario 3: Average Student, Everything Normal
```
Student: Typical performance
Focus Loss: 2
Time: Normal
Answer Quality: Expected

Possible explanation: Honest work
Action: No action needed
```

---

## ⚖️ Legal & Ethical Considerations

### Do's
- ✅ Use data as **one indicator** among many
- ✅ Consider student's full academic record
- ✅ Give students a chance to explain
- ✅ Document all decisions
- ✅ Apply policies consistently

### Don'ts
- ❌ Auto-fail based on metrics alone
- ❌ Publicly shame students
- ❌ Ignore patterns of behavior
- ❌ Make exceptions for favorites
- ❌ Forget innocent until proven guilty

---

## 🎓 Educational Approach

### Instead of Punitive Focus:
```
Traditional: "You switched windows 8 times! You're cheating!"
Better: "I noticed you had some focus losses. Was there 
        something distracting you during the exam?"
```

### Use as Teaching Opportunity:
```
"These metrics help me ensure fairness. If you're honest,
you have nothing to worry about. If you're tempted to cheat,
remember that I'm monitoring and, more importantly, cheating
only hurts your own learning."
```

---

## 📞 When in Doubt

### Contact IT/Administration If:
- Multiple students show identical patterns
- System appears to have false positives
- Student disputes the data
- You need guidance on consequences

### Trust Your Professional Judgment
The security system provides **data**, not **decisions**.
You know your students best. Use this as one tool among many.

---

## 🚀 Future Enhancements

These features may be added in future updates:
- Dashboard with visual analytics
- Automatic risk scoring
- Email alerts for suspicious submissions
- Comparison with class averages
- Historical tracking per student

---

## Summary

**The goal isn't to catch cheaters—it's to promote academic integrity.**

Use these tools to:
1. Deter cheating (students know they're monitored)
2. Identify potential issues (investigate when needed)
3. Protect honest students (ensure fair grading)
4. Improve your teaching (identify struggling students)

Remember: Technology is a tool, not a replacement for your professional judgment.
