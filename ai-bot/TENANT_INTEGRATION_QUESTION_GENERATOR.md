# Question Generator Client Service - Tenant Integration

## Overview

The `QuestionGeneratorClientService` has been successfully updated to include proper tenant authentication headers, ensuring secure multi-tenant isolation in your Gabay platform. This implementation follows the same pattern used in the axios interceptors from `_app.tsx`.

## Key Changes Made

### 1. Tenant Header Management

#### Private Helper Methods Added:
```typescript
// For JSON requests (with Content-Type)
private getTenantHeaders(): Record<string, string>

// For file uploads (without Content-Type to allow browser to set multipart boundary)
private getTenantHeadersForUpload(): Record<string, string>
```

#### Headers Included:
- `x-tenant-tag`: Primary tenant identifier from JWT token
- `uuid`: Unique user session identifier
- `Authorization`: Bearer token for user authentication
- `credentials: 'include'`: Ensures cookies are sent with requests

### 2. Tenant Cookie Integration

The service now uses `getTenantCookie()` utility function (same as axios interceptors) to fetch:
- **x-tenant-tag**: From JWT token payload containing tenant information
- **uuid**: Generated unique session identifier
- **token**: User authentication token

### 3. All API Methods Updated

✅ **uploadDocument()**: Uses `getTenantHeadersForUpload()` (no Content-Type for FormData)  
✅ **createQuestionPlan()**: Uses `getTenantHeaders()` (includes Content-Type: application/json)  
✅ **startQuestionGeneration()**: Uses `getTenantHeaders()` (includes Content-Type: application/json)  
✅ **getGeneratedQuestions()**: Uses `getTenantHeaders()` for GET request  
✅ **getPlanStatus()**: Uses `getTenantHeaders()` for GET request  

## Technical Implementation Details

### Header Strategy
```typescript
// Example of how tenant headers are constructed
const headers = {
  'Content-Type': 'application/json', // Only for JSON requests
  'x-tenant-tag': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...', // JWT token
  'uuid': 'f47ac10b-58cc-4372-a567-0e02b2c3d479', // Session UUID
  'Authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...' // User token
};
```

### SSE Streaming Compatibility
The implementation maintains compatibility with Server-Sent Events (SSE) for real-time progress updates while ensuring tenant security:

```typescript
const response = await fetch(url, {
  method: 'POST',
  headers: this.getTenantHeaders(),
  body: JSON.stringify(request),
  credentials: 'include' // Critical for tenant cookies
});

// SSE streaming continues to work normally
const reader = response.body?.getReader();
// ... streaming logic unchanged
```

## Security Benefits

### 1. **Tenant Isolation**
- Each request includes the proper tenant identifier
- Backend can properly route requests to tenant-specific databases
- Prevents cross-tenant data leakage

### 2. **Authentication**
- User token ensures request authorization
- UUID provides session tracking for security auditing
- Credentials included for additional cookie-based auth

### 3. **Consistency**
- Uses same header pattern as axios interceptors in `_app.tsx`
- Follows established tenant authentication architecture
- Maintains compatibility with existing backend middleware

## Usage Example

```typescript
// Initialize client
const client = QuestionGeneratorClient;

// Upload document (automatically includes tenant headers)
const uploadResult = await client.uploadDocument(file, (progress) => {
  console.log(`Progress: ${progress.progress_percentage}%`);
});

// Create question plan (tenant-aware)
const planResult = await client.createQuestionPlan({
  document_id: uploadResult.document_id,
  subject: "Mathematics",
  grade_level: "Grade 8",
  difficulty_level: "intermediate",
  question_types: {
    multiple_choice: 5,
    true_false: 3,
    short_answer: 2,
    essay: 1,
    fill_blank: 2
  }
});

// All requests are now properly tenant-scoped!
```

## Debugging

### Check Headers in Network Tab
When debugging tenant issues, verify these headers are present in browser DevTools Network tab:

```
Request Headers:
x-tenant-tag: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
uuid: f47ac10b-58cc-4372-a567-0e02b2c3d479
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Common Issues
- **No tenant headers**: Check if cookies are properly set in browser
- **403 Forbidden**: Verify tenant token is valid and not expired
- **Cross-tenant access**: Ensure x-tenant-tag matches user's tenant

## Backend Integration

The backend Question Generator API endpoints should expect and validate these headers:

```typescript
// Backend middleware example
const validateTenantAccess = (req, res, next) => {
  const tenantTag = req.headers['x-tenant-tag'];
  const uuid = req.headers['uuid'];
  const auth = req.headers['authorization'];
  
  if (!tenantTag) {
    return res.status(401).json({ error: 'Missing tenant identifier' });
  }
  
  // Validate and decode tenant token
  // Set tenant context for database queries
  // Continue to next middleware
  next();
};
```

## Conclusion

The Question Generator Client Service is now fully integrated with the multi-tenant architecture, ensuring:

✅ **Secure tenant isolation**  
✅ **Consistent authentication patterns**  
✅ **Maintained SSE streaming functionality**  
✅ **Compatible with existing infrastructure**  

All question generation operations will now be properly scoped to the user's tenant, preventing data leakage and ensuring proper resource isolation in your Gabay platform.