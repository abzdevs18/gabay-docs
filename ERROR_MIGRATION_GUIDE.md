# Error Pages Migration Guide

## 🎯 Purpose

This guide helps you migrate existing error handling to use the new friendly error components throughout the Gabay LMS application.

---

## ✅ Already Migrated

The following pages have already been updated:

- ✅ `/pages/500.tsx` - Server error page
- ✅ `/pages/404.tsx` - Not found page

---

## 🔍 Finding Existing Error Displays

### 1. Search for Old Error Patterns

```bash
# In frontend directory
cd frontend/src

# Find div elements with "error" class
grep -r "className.*error" .

# Find error messages
grep -r "Something went wrong" .
grep -r "Error:" .
grep -r "Failed to" .

# Find old error components
grep -r "ErrorMessage" .
grep -r "ErrorDisplay" .
grep -r "AlertError" .
```

### 2. Common Old Patterns

**Old Pattern #1: Plain div with error text**
```tsx
// ❌ OLD
<div className="text-red-500">
  Error: Failed to load data
</div>
```

**New Pattern:**
```tsx
// ✅ NEW
<InlineError 
  message="Failed to load data"
  onRetry={handleRetry}
/>
```

---

**Old Pattern #2: Alert/Toast for critical errors**
```tsx
// ❌ OLD
{error && (
  <div className="bg-red-100 border border-red-400 p-4">
    <p className="text-red-700">Critical Error: {error.message}</p>
    <button onClick={retry}>Try Again</button>
  </div>
)}
```

**New Pattern:**
```tsx
// ✅ NEW
{error && (
  <InlineError 
    title="Critical Error"
    message={error.message}
    onRetry={retry}
  />
)}
```

---

**Old Pattern #3: Full page error screen**
```tsx
// ❌ OLD
if (isError) {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div>
        <h1>Error</h1>
        <p>Something went wrong</p>
        <button onClick={reload}>Reload</button>
      </div>
    </div>
  )
}
```

**New Pattern:**
```tsx
// ✅ NEW
if (isError) {
  return <FriendlyError type="general" onRetry={reload} />
}
```

---

## 📝 Migration Steps by Component Type

### API Error Handlers

**Old Code:**
```tsx
const { data, error, isLoading } = useQuery('data', fetchData)

if (error) {
  return (
    <div className="text-red-500">
      Failed to load data: {error.message}
    </div>
  )
}
```

**New Code:**
```tsx
const { data, error, isLoading, refetch } = useQuery('data', fetchData)

if (error) {
  return (
    <InlineError 
      message={`Failed to load data: ${error.message}`}
      onRetry={refetch}
    />
  )
}
```

---

### Form Errors

**Old Code:**
```tsx
{formError && (
  <div className="bg-red-50 border-red-200 p-3 rounded">
    <p className="text-red-700 text-sm">{formError}</p>
  </div>
)}
```

**New Code:**
```tsx
{formError && (
  <InlineError 
    message={formError}
    onRetry={() => setFormError(null)}
  />
)}
```

---

### Network Errors

**Old Code:**
```tsx
if (networkError) {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h2>Network Error</h2>
        <p>Please check your connection</p>
        <button onClick={retry}>Retry</button>
      </div>
    </div>
  )
}
```

**New Code:**
```tsx
if (networkError) {
  return <FriendlyError type="network" onRetry={retry} />
}
```

---

### Error Boundaries

**Old Code:**
```tsx
class ErrorBoundary extends React.Component {
  render() {
    if (this.state.hasError) {
      return (
        <div>
          <h1>Something went wrong.</h1>
          <button onClick={() => window.location.reload()}>
            Reload
          </button>
        </div>
      )
    }
    return this.props.children
  }
}
```

**New Code:**
```tsx
import FriendlyError from 'src/components/FriendlyError'

class ErrorBoundary extends React.Component {
  render() {
    if (this.state.hasError) {
      return <FriendlyError type="general" />
    }
    return this.props.children
  }
}
```

---

### Loading States with Errors

**Old Code:**
```tsx
if (isLoading) return <div>Loading...</div>
if (error) return <div className="text-red-500">Error: {error.message}</div>
```

**New Code:**
```tsx
if (isLoading) return <div>Loading...</div>
if (error) {
  return (
    <InlineError 
      message={error.message}
      onRetry={refetch}
    />
  )
}
```

---

## 🗺️ Migration Checklist

### Phase 1: Critical Pages (High Priority)

- [ ] Login/Authentication errors
- [ ] Dashboard errors
- [ ] Data loading errors
- [ ] Form submission errors
- [ ] Payment/billing errors

### Phase 2: User-Facing Pages (Medium Priority)

- [ ] Profile page errors
- [ ] Settings page errors
- [ ] Course/subject pages
- [ ] Assignment pages
- [ ] Grade pages

### Phase 3: Admin Pages (Lower Priority)

- [ ] Admin dashboard errors
- [ ] User management errors
- [ ] System settings errors
- [ ] Reports errors

---

## 🔧 Common Scenarios

### Scenario 1: Async Data Fetching

```tsx
// Import
import InlineError from 'src/components/InlineError'

// In component
const [data, setData] = useState(null)
const [error, setError] = useState(null)
const [isLoading, setIsLoading] = useState(false)

const fetchData = async () => {
  try {
    setIsLoading(true)
    setError(null)
    const result = await api.getData()
    setData(result)
  } catch (err) {
    setError(err.message)
  } finally {
    setIsLoading(false)
  }
}

// In render
if (error) {
  return (
    <InlineError 
      message={error}
      onRetry={fetchData}
    />
  )
}
```

---

### Scenario 2: Form Validation

```tsx
import InlineError from 'src/components/InlineError'

const handleSubmit = async (e) => {
  e.preventDefault()
  try {
    setSubmitError(null)
    await api.submit(formData)
    // Success
  } catch (err) {
    setSubmitError(err.message)
  }
}

// In render
<form onSubmit={handleSubmit}>
  {submitError && (
    <InlineError 
      message={submitError}
      onRetry={handleSubmit}
    />
  )}
  {/* form fields */}
</form>
```

---

### Scenario 3: Page-Level Errors

```tsx
import FriendlyError from 'src/components/FriendlyError'

// For critical page errors
if (criticalError) {
  return <FriendlyError type="general" />
}

// For network errors
if (isOffline) {
  return <FriendlyError type="network" />
}

// For server errors
if (serverError) {
  return <FriendlyError type="server" onRetry={refetchData} />
}
```

---

### Scenario 4: Conditional Inline Errors

```tsx
import InlineError from 'src/components/InlineError'

<div className="space-y-4">
  {/* Content */}
  <div className="p-4">
    {/* Your content here */}
  </div>
  
  {/* Error display */}
  {error && (
    <InlineError 
      variant="error"
      message={error}
      onRetry={handleRetry}
    />
  )}
  
  {/* Warning display */}
  {warning && (
    <InlineError 
      variant="warning"
      message={warning}
    />
  )}
</div>
```

---

## 🎨 Styling Considerations

### Old Custom Error Styles

If you have custom error styles that you want to preserve:

```tsx
// You can still add custom classes
<InlineError 
  message="Error message"
  className="my-custom-class mb-4"
/>
```

### Matching Existing Design

The new components use Tailwind CSS and are designed to fit the existing Gabay design system. If you need custom colors, modify the component files directly.

---

## 🧪 Testing After Migration

### Checklist

- [ ] All error states still display correctly
- [ ] Retry buttons work as expected
- [ ] Error messages are clear and helpful
- [ ] Mobile display looks good
- [ ] Keyboard navigation works
- [ ] Screen readers announce errors
- [ ] Error tracking still logs errors (if applicable)

### Test Cases

1. **Trigger API Error**
   - Disconnect internet
   - Verify network error displays
   - Test retry functionality

2. **Trigger Form Error**
   - Submit invalid form
   - Verify inline error displays
   - Error message is clear

3. **Trigger Page Error**
   - Navigate to non-existent page
   - Verify 404 page displays
   - Test home button

4. **Trigger Server Error**
   - Test with failing backend
   - Verify server error displays
   - Test retry button

---

## 📊 Migration Progress Tracker

Create a file `ERROR_MIGRATION_PROGRESS.md` to track your progress:

```markdown
# Error Migration Progress

## Phase 1: Critical Pages
- [x] 500.tsx
- [x] 404.tsx
- [ ] Login page
- [ ] Dashboard
- [ ] Data tables

## Phase 2: User Pages
- [ ] Profile page
- [ ] Settings
- [ ] Courses
- [ ] Assignments

## Phase 3: Admin Pages
- [ ] Admin dashboard
- [ ] User management
- [ ] System settings
```

---

## 🚀 Quick Wins

Start with these easy migrations for quick impact:

1. **Global Error Boundary**
   - Update `_app.tsx` error boundary
   - Big impact, single change

2. **API Error States**
   - Find all `useQuery` error states
   - Add `<InlineError />` components

3. **Form Submissions**
   - Find all form error displays
   - Replace with `<InlineError />`

---

## 💡 Tips

1. **Use Find & Replace Carefully**
   - Don't blindly replace all error divs
   - Review each case individually

2. **Test Incrementally**
   - Migrate one section at a time
   - Test before moving to next

3. **Keep Old Code Temporarily**
   - Comment out old code
   - Remove after testing new version

4. **Update Tests**
   - Update component tests
   - Update E2E tests
   - Verify error selectors

5. **Document Custom Cases**
   - Note any special error handling
   - Document workarounds if needed

---

## 🆘 Common Issues

### Issue 1: Error Not Showing

**Problem:** Error component doesn't display

**Solutions:**
- Check error is truthy
- Verify import path is correct
- Check component is in render tree

### Issue 2: Retry Not Working

**Problem:** Retry button doesn't work

**Solutions:**
- Verify onRetry prop is passed
- Check function is defined
- Ensure function isn't causing error

### Issue 3: Styling Conflicts

**Problem:** Error component looks wrong

**Solutions:**
- Check for CSS conflicts
- Use className prop for adjustments
- Verify Tailwind is processing classes

---

## 📚 Resources

- **Full Documentation:** `/frontend/docs/ERROR_PAGES.md`
- **Quick Reference:** `/frontend/docs/ERROR_QUICK_REFERENCE.md`
- **Visual Guide:** `/frontend/docs/ERROR_PAGES_README.md`
- **Examples:** `http://localhost:3000/examples/error-showcase`

---

## ✅ Done Migrating?

After migration is complete:

1. **Remove old error components** (if any)
2. **Update documentation** to reference new components
3. **Train team** on new error handling patterns
4. **Remove showcase page** from production (or restrict access)

---

**Questions or Issues?** Create an issue in the project repository or contact the development team.
