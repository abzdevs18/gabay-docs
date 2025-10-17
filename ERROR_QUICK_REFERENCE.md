# Error Components Quick Reference

## 🎯 Quick Decision Guide

**Question: Is the entire page broken?**
- ✅ **YES** → Use `FriendlyError` (full-page)
- ❌ **NO** → Use `InlineError` (inline)

---

## Full-Page Errors

```tsx
import FriendlyError from 'src/components/FriendlyError'

// 500 Server Error
<FriendlyError type="server" />

// Network/Connection Error
<FriendlyError type="network" />

// General/Unexpected Error
<FriendlyError type="general" />

// 404 Not Found
<FriendlyError type="notfound" showRefresh={false} />
```

**Props:**
- `type` - error type (server/network/general/notfound)
- `title` - custom title
- `message` - custom message
- `showRefresh` - show retry button (default: true)
- `showHome` - show home button (default: true)
- `showSupport` - show support link (default: true)
- `onRetry` - custom retry handler

---

## Inline Errors

```tsx
import InlineError, { InlineErrorCompact } from 'src/components/InlineError'

// Error (red)
<InlineError 
  message="Failed to load"
  onRetry={handleRetry}
/>

// Warning (amber)
<InlineError 
  variant="warning"
  title="Slow Connection"
  message="Features may be limited"
/>

// Info (blue)
<InlineError 
  variant="info"
  message="Maintenance at 2 PM"
/>

// Compact
<InlineErrorCompact 
  message="Save failed"
  onRetry={handleSave}
/>
```

**Props:**
- `variant` - error type (error/warning/info)
- `title` - error title
- `message` - error message
- `onRetry` - retry handler
- `action` - custom action button
- `className` - additional CSS classes

---

## Common Use Cases

### API Call Failed
```tsx
<InlineError 
  message="Failed to load assignments"
  onRetry={refetchAssignments}
/>
```

### Form Submission Failed
```tsx
<InlineError 
  title="Submission Failed"
  message={error.message}
  onRetry={handleSubmit}
/>
```

### Session Expired
```tsx
<InlineError 
  message="Your session has expired"
  action={
    <button onClick={handleLogin}>Login</button>
  }
/>
```

### Server Down
```tsx
<FriendlyError type="server" />
```

### No Internet
```tsx
<FriendlyError type="network" />
```

### Page Not Found
```tsx
<FriendlyError type="notfound" showRefresh={false} />
```

### Warning Message
```tsx
<InlineError 
  variant="warning"
  message="Connection unstable"
/>
```

### Info Notice
```tsx
<InlineError 
  variant="info"
  title="Scheduled Maintenance"
  message="System will be down 2-4 PM"
/>
```

---

## Cheat Sheet

| What Happened | Component | Code |
|--------------|-----------|------|
| 500 Error | FriendlyError | `<FriendlyError type="server" />` |
| No Internet | FriendlyError | `<FriendlyError type="network" />` |
| 404 Error | FriendlyError | `<FriendlyError type="notfound" />` |
| Unknown Error | FriendlyError | `<FriendlyError type="general" />` |
| API Failed | InlineError | `<InlineError onRetry={fn} />` |
| Form Error | InlineError | `<InlineError message="..." />` |
| Warning | InlineError | `<InlineError variant="warning" />` |
| Notice | InlineError | `<InlineError variant="info" />` |

---

## Color Guide

- 🔴 **Red** - Error/Failed operations
- 🟠 **Orange** - Network issues
- 🟡 **Amber** - Warnings/Cautions
- 🔵 **Blue** - Server issues/Info
- 🟣 **Purple** - Not found

---

## Testing

**View all examples:**
```
http://localhost:3000/examples/error-showcase
```

**Built-in error pages:**
- `/500` - Server error page
- `/404` - Not found page

---

## Key Points

✅ Full-page errors for critical issues  
✅ Inline errors for recoverable issues  
✅ Always provide a retry option when possible  
✅ Use friendly, non-alarming language  
✅ Customize messages to be specific  
✅ Test error states regularly  

---

**Full Documentation:** `/frontend/docs/ERROR_PAGES.md`
