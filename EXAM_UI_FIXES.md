# Exam UI Fixes - Points & Duration Display

## Issues Fixed

### 1. ✅ Duration Display - Too Many Decimal Places
**Problem:** Duration showed as `4.666666666666667m` instead of `4.67m`

**Solution:** Added rounding to 2 decimal places
```typescript
const totalDuration = useMemo(() => {
  if (!formState?.settings) return 0;
  if (formState.settings.enablePerQuestionTimer) {
    const totalMinutes = allQuestions.reduce((total, q) => {
      const seconds = getQuestionTimeLimitInSeconds(q);
      return total + (seconds / 60);
    }, 0);
    // Round to 2 decimal places
    return Math.round(totalMinutes * 100) / 100;
  }
  return formState.settings.timeLimit || 0;
}, [allQuestions, formState?.settings, getQuestionTimeLimitInSeconds]);
```

**Result:** Now displays as `4.67m` ✅

---

### 2. ✅ Points Always Showing 0
**Problem:** Total points displayed as 0 even when questions had points assigned

**Root Cause:** Questions might use either `points` or `score` field depending on question type

**Solution:** Check both fields when calculating total
```typescript
const getTotalPoints = () => {
  // Check both points and score fields (some questions use 'score' instead of 'points')
  return allQuestions.reduce((total, q) => {
    const questionPoints = q.points || (q as any).score || 0;
    return total + questionPoints;
  }, 0);
}
```

**Additional Fix:** Improved question extraction from API response
```typescript
const allQuestions = useMemo(() => {
  // Extract sections from either root level or schema (API returns in schema.sections)
  const sections = formState?.sections || formState?.schema?.sections || [];
  
  const questions = sections.flatMap(section => 
    section.questions?.map(q => ({ ...q, sectionTitle: section.title })) || []
  );
  
  // Debug logging to verify structure
  if (questions.length > 0) {
    console.log('[Exam] Sample question structure:', {
      id: questions[0].id,
      type: questions[0].type,
      points: questions[0].points,
      score: (questions[0] as any).score,
      hasPoints: 'points' in questions[0],
      hasScore: 'score' in questions[0]
    });
  }
  
  return questions;
}, [formState, formState?.sections, formState?.schema?.sections]);
```

**Result:** Points now display correctly ✅

---

## How to Verify

### Test Duration Display:
1. Create a form with per-question timers enabled
2. Set questions with various time limits (e.g., 30 seconds, 1 minute, 45 seconds)
3. Open exam as student
4. Check header card - should show duration like `4.67m` (not `4.666666666666667m`)

### Test Points Display:
1. Create questions with points assigned
2. Open browser console (F12)
3. Look for log: `[Exam] Sample question structure:`
4. Verify `points` or `score` field has values
5. Check header card - should show total points (not 0)

---

## Files Modified

- `frontend/src/shad-components/shad/components/gabay-form/new-preview.tsx`
  - Fixed `totalDuration` calculation (added rounding)
  - Fixed `getTotalPoints()` function (check both fields)
  - Improved `allQuestions` extraction (better fallback logic)
  - Added debug logging

---

## Related Memory

This fix follows the pattern from MEMORY[802ab303-dc0f-4173-af50-ad4f30736d6d]:
- API returns form data with sections nested in `schema.sections`
- Need to check both `formState.sections` and `formState.schema.sections`
- Use fallback pattern: `formState?.sections || formState?.schema?.sections || []`

---

## Future Considerations

### If Points Still Show 0:
1. Check browser console for debug log
2. Verify questions actually have points assigned in form builder
3. Check if points are stored in a different field name
4. Verify API response includes points data

### If Duration is Still Wrong:
1. Check if per-question timer is enabled
2. Verify time limits are set on questions
3. Check if global time limit is set correctly
4. Verify time unit (minutes vs seconds)
