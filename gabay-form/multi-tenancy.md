# Gabay Form - Multi-Tenancy Guide

> Complete data isolation for multiple schools and organizations

---

## Overview

The Gabay Form system is built from the ground up to support **multi-tenancy**, allowing multiple schools or organizations to use the platform with complete data isolation.

---

## Architecture

### Tenant Isolation Levels

```
1. Database Level
   └── Separate PostgreSQL schemas per tenant
       ├── tenant_schoola.gabay_forms
       ├── tenant_schoolb.gabay_forms
       └── tenant_schoolc.gabay_forms

2. Cache Level
   └── Tenant-prefixed Redis keys
       ├── schoola:form:123
       ├── schoolb:form:456
       └── schoolc:form:789

3. Application Level
   └── Middleware enforces tenant context
       ├── Extract tenant from headers
       ├── Validate tenant access
       └── Scope all queries to tenant

4. Worker Level
   └── Tenant context in job data
       ├── tenantId passed in jobs
       ├── tenantToken for authentication
       └── Correct Prisma client used

5. Storage Level
   └── Tenant-specific file buckets
       ├── schoola-uploads/
       ├── schoolb-uploads/
       └── schoolc-uploads/
```

---

## Request Flow

### 1. Tenant Identification

```
HTTP Request
    ↓
Headers:
  x-tenant-tag: "schoola_token"
Cookie:
  tenant_id=schoola
    ↓
Tenant Middleware
  - Extract tenant token
  - Validate access
  - Set tenant context
    ↓
Request continues with tenant context
```

### 2. Database Access

```typescript
// Get tenant-specific Prisma client
const tenantId = getTenantId(req);
const prisma = await getPrismaClient(req, tenantId);

// All queries automatically scoped to tenant schema
const forms = await prisma.gabayForm.findMany({
  where: { createdBy: userId }
});

// Queries: SELECT * FROM tenant_schoola.gabay_forms
```

### 3. Cache Access

```typescript
// Cache keys automatically prefixed
const cacheKey = cacheService.generateKey('form', formId);
// Result: "schoola:form:123"

// Get from cache
const cached = await cacheService.get(cacheKey);

// Set to cache
await cacheService.set(cacheKey, data, ttl);
```

---

## Implementation Details

### Backend (API)

**Middleware Setup:**

```typescript
// Tenant middleware (automatic)
export default async function handler(req, res) {
  // 1. Extract tenant
  const tenantId = getTenantId(req);
  
  // 2. Get Prisma client
  const prisma = await getPrismaClient(req, tenantId);
  
  // 3. All queries use correct schema
  const form = await prisma.gabayForm.findUnique({
    where: { id: formId }
  });
  
  return res.json({ data: form });
}
```

**Cache with Tenant:**

```typescript
// Generate tenant-specific cache key
const cacheKey = cacheService.generateKey(
  'gabay-form',
  formId
);
// Result: "schoola:gabay-form:abc123"

// Cache operations automatically scoped
await cacheService.set(cacheKey, data);
const cached = await cacheService.get(cacheKey);
await cacheService.del(cacheKey);
```

### Frontend (Next.js)

**SSR with Tenant:**

```typescript
// getServerSideProps automatically includes tenant cookie
export async function getServerSideProps(context) {
  const { slug } = context.params;
  
  // Tenant cookie automatically sent
  const response = await axios.get(
    `${process.env.BASE_URL}/api/v1/gabay-forms/public/${slug}`,
    {
      headers: {
        cookie: context.req.headers.cookie // Includes x-tenant-tag
      }
    }
  );
  
  return {
    props: {
      form: response.data.data.form
    }
  };
}
```

**Client-side with Tenant:**

```typescript
// Axios automatically includes tenant cookie
const response = await GabayFormService.getForm(formId);
// Headers automatically include x-tenant-tag from cookie
```

### Worker System

**Tenant Context in Jobs:**

```typescript
// When queuing job (API)
await responseQueueManager.addJob({
  responseId,
  formId,
  studentEmail,
  // ... other fields
  tenantId: tenantId || 'public',      // Tenant ID
  tenantToken: req.headers['x-tenant-tag']  // Tenant token
});
```

**Worker Processing:**

```typescript
// Worker extracts tenant context
async function processFormResponse(job) {
  const { tenantId, tenantToken } = job.data;
  
  // Build mock request with tenant headers
  const mockReq = {
    headers: {
      'x-tenant-tag': tenantToken
    }
  };
  
  // Get tenant-specific Prisma client
  const prisma = await getPrismaClient(mockReq, tenantId);
  
  // All queries scoped to tenant
  const form = await prisma.gabayForm.findUnique({
    where: { id: formId }
  });
}
```

---

## Data Isolation Guarantees

### Database Level

**✅ Separate Schemas:**
```sql
-- Each tenant has own schema
CREATE SCHEMA tenant_schoola;
CREATE SCHEMA tenant_schoolb;

-- Tables isolated per tenant
tenant_schoola.gabay_forms
tenant_schoolb.gabay_forms

-- No way to query across tenants
```

**✅ Connection Pooling:**
```typescript
// Separate connection pools per tenant
const pools = {
  'schoola': new Pool({ schema: 'tenant_schoola' }),
  'schoolb': new Pool({ schema: 'tenant_schoolb' })
};
```

### Application Level

**✅ Middleware Enforcement:**
```typescript
// Every request validates tenant
if (!tenantId || !isValidTenant(tenantId)) {
  return res.status(403).json({
    error: 'Invalid tenant'
  });
}
```

**✅ Prisma Client Scoping:**
```typescript
// Prisma client automatically scoped
const prisma = await getPrismaClient(req, tenantId);
// All queries execute in tenant schema
```

### Cache Level

**✅ Key Prefixing:**
```typescript
// Keys automatically prefixed
schoola:form:123
schoolb:form:456

// No collision between tenants
```

### Worker Level

**✅ Context Preservation:**
```typescript
// Tenant context in job data
{
  ...jobData,
  tenantId: 'schoola',
  tenantToken: 'token_...'
}

// Worker uses correct tenant
const prisma = await getPrismaClient(mockReq, tenantId);
```

---

## Testing Multi-Tenancy

### Test Cases

**1. Data Isolation**
```bash
# Create form as Tenant A
curl -X POST /api/v1/gabay-forms \
  -H "x-tenant-tag: schoola_token" \
  -d '{"title": "Test Form A"}'

# Try to access as Tenant B (should fail)
curl /api/v1/gabay-forms/{formId} \
  -H "x-tenant-tag: schoolb_token"
# Expected: 404 Not Found
```

**2. Cache Isolation**
```bash
# Set cache for Tenant A
redis-cli SET schoola:form:123 "data_a"

# Get as Tenant B (should not find)
redis-cli GET schoolb:form:123
# Expected: (nil)
```

**3. Worker Isolation**
```bash
# Submit form as Tenant A
# Worker should use Tenant A's database

# Check logs
tail -f logs/worker.log | grep "Tenant: schoola"
```

---

## Security Best Practices

### 1. Always Validate Tenant

```typescript
// NEVER trust tenant from user input
const tenantId = getTenantId(req);  // From server-side logic
// NOT from: req.body.tenantId ❌
```

### 2. Use Middleware

```typescript
// Enforce tenant validation at middleware level
app.use(tenantMiddleware);

// Don't rely on individual route checks
```

### 3. Audit Tenant Access

```typescript
// Log all tenant access
logger.info('Tenant access', {
  tenantId,
  userId,
  endpoint: req.url,
  timestamp: new Date()
});
```

### 4. Rate Limit Per Tenant

```typescript
// Different rate limits for different tenants
const limit = getRateLimitForTenant(tenantId);
rateLimiter(limit);
```

---

## Troubleshooting

### Issue: Wrong Data Returned

**Cause:** Tenant context not set

**Solution:**
```typescript
// Always get tenant first
const tenantId = getTenantId(req);

// Then get Prisma client
const prisma = await getPrismaClient(req, tenantId);
```

### Issue: Cache Collisions

**Cause:** Keys not prefixed with tenant

**Solution:**
```typescript
// Always use cacheService.generateKey()
const key = cacheService.generateKey('form', formId);
// NOT: const key = `form:${formId}` ❌
```

### Issue: Worker Using Wrong Tenant

**Cause:** Tenant context not passed in job

**Solution:**
```typescript
// Always include tenant in job data
await queue.addJob({
  ...data,
  tenantId: tenantId || 'public',
  tenantToken: req.headers['x-tenant-tag']
});
```

---

## Migration Guide

### Adding New Tenant

1. **Create Database Schema**
```sql
CREATE SCHEMA tenant_newschool;

-- Run migrations
npx prisma migrate deploy --schema tenant_newschool
```

2. **Configure Tenant**
```typescript
// Add to tenant configuration
const tenants = {
  newschool: {
    id: 'newschool',
    name: 'New School',
    schema: 'tenant_newschool',
    token: 'generated_token'
  }
};
```

3. **Test Access**
```bash
curl /api/v1/gabay-forms \
  -H "x-tenant-tag: newschool_token"
```

---

## Performance Considerations

### Connection Pooling

```typescript
// Reuse connections per tenant
const pool = connectionPools.get(tenantId) || createPool(tenantId);
```

### Cache Strategy

```typescript
// Cache tenant metadata
const tenantCache = new Map();
tenantCache.set(tenantId, tenantData);
```

### Query Optimization

```typescript
// Use indexes on tenant schema
CREATE INDEX idx_forms_created_by 
ON tenant_schoola.gabay_forms(created_by);
```

---

## Related Documentation

- [Architecture Diagrams](./architecture-diagrams.md)
- [Multi-Tenant Worker Support](../../MULTI_TENANT_WORKER_SUPPORT.md)
- [Security Best Practices](../security/README.md)
