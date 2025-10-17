# Friendly Error Pages Documentation

## Overview

The Gabay LMS now uses modern, user-friendly error pages that don't alarm users while communicating issues effectively. The design is calm, reassuring, and professional.

## Components

### FriendlyError Component

**Location:** `/src/components/FriendlyError.tsx`

A reusable **full-page** error display component with multiple configurations for different error scenarios. Use this for critical errors that prevent the entire page from functioning.

### InlineError Component

**Location:** `/src/components/InlineError.tsx`

A compact **inline** error display component for use within pages. Use this for section-specific errors, API failures, or form errors that don't require a full-page error screen.

#### Props

```typescript
interface FriendlyErrorProps {
  type?: 'server' | 'network' | 'general' | 'notfound'
  title?: string              // Custom title (overrides default)
  message?: string            // Custom message (overrides default)
  showRefresh?: boolean       // Show "Try Again" button (default: true)
  showHome?: boolean          // Show "Go to Homepage" button (default: true)
  showSupport?: boolean       // Show support link (default: true)
  customActions?: ReactNode   // Additional custom action buttons
  onRetry?: () => void        // Custom retry handler
}
```

#### Error Types

1. **server** - Server/backend errors (500, 503)
   - Blue color scheme
   - Cloud icon
   - Message: "Taking a Short Break"
   - Reassuring tone

2. **network** - Network connectivity issues
   - Orange color scheme
   - WiFi off icon
   - Message: "Connection Lost"
   - Helps users check their internet

3. **general** - Generic unexpected errors
   - Amber color scheme
   - Alert circle icon
   - Message: "Something Went Wrong"
   - Neutral, non-alarming

4. **notfound** - 404 errors
   - Purple color scheme
   - Server icon
   - Message: "Page Not Found"
   - Helpful navigation tips

#### Usage Examples

**Basic Usage:**
```tsx
import FriendlyError from 'src/components/FriendlyError'

// Server error
<FriendlyError type="server" />

// Network error
<FriendlyError type="network" />

// 404 error (no refresh button)
<FriendlyError type="notfound" showRefresh={false} />
```

**Custom Configuration:**
```tsx
<FriendlyError
  type="general"
  title="Custom Error Title"
  message="Your custom error message here"
  showRefresh={true}
  showHome={false}
  showSupport={true}
  onRetry={async () => {
    // Custom retry logic
    await refetchData()
  }}
/>
```

**With Custom Actions:**
```tsx
<FriendlyError
  type="server"
  customActions={
    <button onClick={handleCustomAction}>
      Custom Action
    </button>
  }
/>
```

### InlineError Usage

**Basic Usage:**
```tsx
import InlineError from 'src/components/InlineError'

// Basic error with retry
<InlineError 
  message="Failed to load data"
  onRetry={handleRetry}
/>

// With title
<InlineError 
  title="Loading Failed"
  message="We couldn't load your assignments. Please try again."
  onRetry={refetchAssignments}
/>

// Warning variant
<InlineError 
  variant="warning"
  title="Connection Unstable"
  message="Your connection is slow. Some features may be limited."
/>

// Info variant
<InlineError 
  variant="info"
  title="Maintenance Scheduled"
  message="The system will undergo maintenance from 2-4 PM today."
/>

// Compact version
import { InlineErrorCompact } from 'src/components/InlineError'

<InlineErrorCompact 
  message="Failed to save"
  onRetry={handleSave}
/>
```

**With Custom Actions:**
```tsx
<InlineError 
  message="Your session has expired"
  action={
    <button 
      onClick={handleLogin}
      className="px-3 py-1.5 text-xs bg-blue-600 text-white rounded-md"
    >
      Login Again
    </button>
  }
/>
```

## Built-in Error Pages

### 500.tsx - Internal Server Error

**Location:** `/src/pages/500.tsx`

Automatically shown for server errors (500 status code).

**Features:**
- Friendly "Taking a Short Break" message
- Try Again button (refreshes page)
- Go to Homepage button
- Contact Support link
- Animated background gradient
- Loading animation indicators

### 404.tsx - Page Not Found

**Location:** `/src/pages/404.tsx`

Automatically shown when a page doesn't exist.

**Features:**
- "Page Not Found" message
- No refresh button (refresh won't help)
- Go to Homepage button
- Tips for finding the right page
- Contact Support link

## Design Philosophy

### User-Centric Messaging

1. **Non-Alarming Language**
   - ❌ "Critical Error", "Fatal Error", "System Failure"
   - ✅ "Taking a Short Break", "Minor Hiccup", "Connection Lost"

2. **Reassuring Tone**
   - Acknowledge the issue
   - Explain it's not their fault
   - Provide clear next steps
   - Offer help if needed

3. **Visual Comfort**
   - Soft gradient backgrounds
   - Friendly animated icons
   - Professional but approachable
   - Loading animations for feedback

### Accessibility

- High contrast text
- Clear button labels
- Keyboard navigation support
- Screen reader friendly
- Touch-friendly button sizes

## Integration in Error Boundaries

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

## Integration in API Error Handlers

```tsx
const fetchData = async () => {
  try {
    const response = await api.getData()
    setData(response)
  } catch (error) {
    if (error.response?.status >= 500) {
      // Show server error
      setErrorType('server')
    } else if (error.message === 'Network Error') {
      // Show network error
      setErrorType('network')
    } else {
      // Show general error
      setErrorType('general')
    }
    setShowError(true)
  }
}

// In render
{showError && <FriendlyError type={errorType} onRetry={fetchData} />}
```

## Customization

### Colors

The component uses Tailwind CSS classes. To customize colors:

1. Modify the `errorConfig` object in `FriendlyError.tsx`
2. Change gradient colors: `bgGradient` and `pulseGradient`
3. Change icon colors: `iconColor`

### Icons

Icons are inline SVG components. To add new error types:

1. Create a new SVG icon component
2. Add a new entry to `errorConfig`
3. Update the `ErrorType` type

### Support Link

Default support link: `/support`

To change globally, update the link in `FriendlyError.tsx` component.

## Best Practices

1. **Choose the Right Type**
   - Use `server` for backend issues (500, 503)
   - Use `network` for connectivity problems
   - Use `general` for unexpected errors
   - Use `notfound` only for 404s

2. **Provide Context When Possible**
   - Override default messages for specific scenarios
   - Add custom actions for recoverable errors
   - Implement custom retry logic when applicable

3. **Don't Over-Use**
   - Use inline error messages for form validation
   - Use toasts for transient errors
   - Reserve full-page errors for critical issues

4. **Test Error States**
   - Test all error types
   - Verify refresh functionality
   - Check mobile responsiveness
   - Test with screen readers

## Future Enhancements

- [ ] Add error tracking integration (Sentry, LogRocket)
- [ ] Add automatic retry with exponential backoff
- [ ] Add offline mode detection
- [ ] Add error code display (dev mode only)
- [ ] Add "Report Bug" button with screenshot
- [ ] Add i18n support for multiple languages
- [ ] Add dark mode support
- [ ] Add analytics tracking for error events
