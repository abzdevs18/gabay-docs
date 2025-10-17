# Multi-Tenant System - Quick Reference Guide

## How Tenant Identification Works Now

### 1. Server-Side Rendering (SSR)
```typescript
// _app.tsx getInitialProps
App.getInitialProps = async (appContext) => {
  const host = req.headers.host; // e.g., "school1.gabay.online"
  
  // Call bootstrap API once on server
  const response = await fetch('/api/v2/tenant/bootstrap', {
    method: 'POST',
    body: JSON.stringify({ tag, domain, isLocalhost, isAcademicWebSolution })
  });
  
  const { tenantToken, siteMetadata, features, featuresList } = await response.json();
  
  // Pass to client as initial data
  return { tenantToken, metadata, featureFlags, featureDescriptions };
};
```

### 2. Client-Side (Browser)
```typescript
// TenantProvider receives initialData from SSR
<TenantProvider initialData={/* SSR data */}>
  {/* App content */}
</TenantProvider>

// TenantProvider checks for initialData
if (initialData?.tenantToken) {
  // Use SSR data, skip API call ✅
  console.log('✅ Using SSR initial data');
  return;
}

// Only calls API if no SSR data (edge case)
loadTenantData();
```

## How to Use Tenant Data in Components

### Getting Tenant Token
```typescript
import { useTenantToken } from '@/contexts/TenantContext';

function MyComponent() {
  const tenantToken = useTenantToken();
  // Use in API headers
}
```

### Getting Metadata
```typescript
import { useMetadata } from '@/contexts/TenantContext';

function MyComponent() {
  const logoUrl = useMetadata('logoUrl');
  const brand = useMetadata('brand');
  // Use metadata
}
```

### Checking Features
```typescript
import { useFeature } from '@/contexts/TenantContext';

function MyComponent() {
  const hasGradingSystem = useFeature('grading_system');
  
  if (!hasGradingSystem) {
    return <div>Feature not available</div>;
  }
  
  return <GradingInterface />;
}
```

### Full Context
```typescript
import { useTenantContext } from '@/contexts/TenantContext';

function MyComponent() {
  const {
    metadata,
    featureFlags,
    tenantToken,
    isLoading,
    isReady,
    refresh,
    checkFeature,
    getMetadata
  } = useTenantContext();
  
  // Use any property
}
```

## Cache Management

### Clear Tenant Cache (Current Tenant Only)
```typescript
const { clearCache } = useTenantContext();
await clearCache();
```

### Clear All Cache (All Data)
```typescript
const { clearAllCache } = useTenantContext();
await clearAllCache();
```

### Force Refresh
```typescript
const { refresh } = useTenantContext();
await refresh(); // Bypasses cache, fetches fresh data
```

### Get Cache Stats
```typescript
const { getCacheStats } = useTenantContext();
const stats = await getCacheStats();
console.log(stats);
```

## Backend API Integration

### Making Tenant-Aware API Calls
```typescript
import axios from 'axios';
import { getTenantCookie } from '@/utils/domain-utils';

const tenantToken = getTenantCookie('x-tenant-tag');

const response = await axios.get('/api/v2/students', {
  headers: {
    'x-tenant-tag': tenantToken,
    'Authorization': `Bearer ${userToken}`
  }
});
```

### Axios Interceptor (Already Configured in _app.tsx)
```typescript
// Automatically adds tenant headers to all requests
axios.interceptors.request.use((config) => {
  config.headers.set('x-tenant-tag', tenantToken);
  config.headers.set('uuid', uuid);
  return config;
});
```

## Cache Timings

| Cache Type | Duration | Location |
|------------|----------|----------|
| Complete Bootstrap | 1 hour | Redis (Backend) |
| Tenant Details | 3 days | Redis (Backend) |
| Feature Flags | 3 days | Redis (Backend) |
| Site Metadata | 3 days | Redis (Backend) |
| JWT Tokens | 6 days | Redis (Backend) |
| Frontend Bootstrap | 30 minutes | IndexedDB (Browser) |
| Stale Time | 5 minutes | Memory (State) |

## Debugging

### Check if SSR Data is Being Used
```typescript
// Open console, look for:
✅ [TenantProvider] Using SSR initial data, skipping client-side bootstrap

// If you see this instead, SSR data isn't being passed:
🚀 [TenantProvider] No initial data, triggering client-side bootstrap
```

### Check Cache Effectiveness
```typescript
// Backend logs
✅ [Bootstrap] Complete bootstrap cache HIT   // Good!
⚠️ [Bootstrap] Complete bootstrap cache MISS   // Expected on first load

// Individual component caches
✅ [Bootstrap] Cache HIT for tenant details   // Good!
❌ [Bootstrap] Cache MISS for tenant details   // Expected on cache expiry
```

### Monitor Performance
```typescript
const { getPerformanceReport } = useTenantContext();
const report = getPerformanceReport();
console.table(report);

/*
{
  "tenant-bootstrap": { duration: 250, cached: true },
  "bootstrap-api-call": { duration: 180, cached: false },
  "cache-hits": 4,
  "cache-misses": 1
}
*/
```

## Common Scenarios

### Scenario 1: User Visits Site (First Time)
```
1. SSR calls bootstrap API
2. Backend checks Redis cache (MISS)
3. Backend queries database (3 queries)
4. Backend generates JWT, caches everything
5. SSR passes data to client
6. Client receives initial data, skips API call ✅
Result: 200-300ms, 3 DB queries
```

### Scenario 2: User Visits Site (Returning)
```
1. SSR calls bootstrap API
2. Backend checks Redis cache (HIT)
3. Backend returns cached data
4. SSR passes data to client  
5. Client receives initial data, skips API call ✅
Result: 10-30ms, 0 DB queries
```

### Scenario 3: User Navigates Between Pages
```
1. No SSR (client-side navigation)
2. TenantProvider checks if data is stale
3. Data is fresh (<5 minutes), skip refresh ✅
Result: 0ms, no requests
```

### Scenario 4: Data Becomes Stale (>5 minutes)
```
1. TenantProvider detects stale data
2. Shows cached data immediately (0ms) ✅
3. Fetches fresh data in background
4. Updates state silently when ready
Result: 0ms perceived, fresh data after ~200ms
```

## Troubleshooting

### Problem: Duplicate Bootstrap Requests
**Symptom:** Seeing 2+ bootstrap API calls in network tab  
**Cause:** Initial data not being passed correctly  
**Solution:** Check that `_app.tsx` getInitialProps is returning all data

### Problem: Slow Page Loads
**Symptom:** 500ms+ load times  
**Cause:** Cache misses or database queries  
**Solution:** Check Redis is running, verify cache hit rates in logs

### Problem: Stale Data
**Symptom:** Old branding/features showing  
**Cause:** Cache not invalidating  
**Solution:** Use `refresh()` or clear cache manually

### Problem: Wrong Tenant Data
**Symptom:** Seeing another school's data  
**Cause:** Incorrect subdomain detection  
**Solution:** Check `detectTenantInfo()` logic, verify domain configuration

## Best Practices

### ✅ DO
- Use `useTenantToken()`, `useMetadata()`, `useFeature()` hooks
- Let the system handle caching automatically
- Use `refresh()` only when necessary (e.g., after admin changes)
- Monitor cache hit rates in production logs

### ❌ DON'T
- Call bootstrap API directly from components
- Manually manage tenant tokens
- Clear cache unnecessarily
- Bypass the TenantProvider
- Hardcode tenant-specific values

## Performance Monitoring

### Key Metrics to Track
```typescript
// Response time percentiles
- p50: <50ms (cached)
- p95: <300ms (uncached)
- p99: <500ms

// Cache hit rate
- Target: >90% after warm-up
- First hour: ~60-70% (acceptable)
- After 24h: >95%

// Database queries per request
- Cached: 0 queries
- Uncached: 3 queries
- Target average: <0.5 queries/request
```

### Alerting Thresholds
```
⚠️ Warning: Cache hit rate <80%
🚨 Critical: Cache hit rate <50%
⚠️ Warning: p95 response time >500ms
🚨 Critical: p95 response time >1000ms
```

---

**Last Updated:** 2025-10-08  
**For Issues:** Contact dev team or check TENANT_OPTIMIZATION_REPORT.md
