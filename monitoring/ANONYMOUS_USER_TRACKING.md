# Anonymous User Tracking

## 🎯 Overview

In addition to tracking **authenticated users**, the system now tracks **anonymous users** (visitors who are NOT logged in).

**Perfect for:**
- 📝 Public forms
- 🎓 Guest access features
- 📊 Landing pages
- 🌐 Public content

---

## ✅ What Gets Tracked

### **Authenticated Users** 👤
- Tracked via `userId`
- Metrics: `gabay_active_users_5m`, `gabay_active_users_15m`, `gabay_active_users_1h`
- **Example:** Students logged into the LMS

### **Anonymous Users** 👻
- Tracked via `sessionId` (generated from IP + User-Agent)
- Metrics: `gabay_anonymous_users_5m`, `gabay_anonymous_users_15m`, `gabay_anonymous_users_1h`
- **Example:** Someone filling out a public form

---

## 🚀 Implementation

### **1. Service Methods**

```typescript
import { userActivityService } from '@/services/user-activity.service';

// For authenticated users (already implemented)
userActivityService.trackUserActivity(userId, tenantTag);

// For anonymous users (NEW!)
const sessionId = userActivityService.generateSessionId(req);
userActivityService.trackAnonymousActivity(sessionId, tenantTag);
```

### **2. Session ID Generation**

The service automatically generates a stable session ID from:
- **Cookie:** `req.cookies.sessionId` (if exists)
- **Header:** `x-session-id` (if provided)
- **Fallback:** IP address + User-Agent (stable for same visitor)

```typescript
// Generates: "anon_AbCdEf123456..." (stable for same IP + browser)
const sessionId = userActivityService.generateSessionId(req);
```

### **3. Tracking is Non-Blocking** ⚡

Both authenticated and anonymous tracking:
- ✅ **Non-blocking** (fire-and-forget)
- ✅ **Zero performance impact**
- ✅ **Fails silently** (doesn't break user experience)

---

## 📊 Where It's Used

### **Current Implementation:**

| Endpoint | Type | Tracked? |
|----------|------|----------|
| `/api/v1/gabay-forms/public/[slug]` | Anonymous | ✅ YES |
| Most authenticated APIs | Authenticated | ✅ YES |

### **How to Add to Other Public Endpoints:**

```typescript
import { userActivityService } from '@/services/user-activity.service';
import { getTenantId } from '@/utils/tenant-identifier';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const tenantId = getTenantId(req);
  
  // Your endpoint logic here...
  
  // Track anonymous activity (add this anywhere in your handler)
  const sessionId = userActivityService.generateSessionId(req);
  userActivityService.trackAnonymousActivity(sessionId, tenantId).catch(err => {
    console.error('Failed to track anonymous activity:', err);
  });
  
  return res.status(200).json({ success: true });
}
```

---

## 📈 Prometheus Metrics

### **Authenticated Users:**
```promql
# Active authenticated users
gabay_active_users_5m{tenant="aans"} 15
gabay_active_users_15m{tenant="aans"} 28
gabay_active_users_1h{tenant="aans"} 45
```

### **Anonymous Users:** (NEW!)
```promql
# Active anonymous users
gabay_anonymous_users_5m{tenant="aans"} 8
gabay_anonymous_users_15m{tenant="aans"} 12
gabay_anonymous_users_1h{tenant="aans"} 20
```

### **Total Active Users:**
```promql
# Total = Authenticated + Anonymous
sum(gabay_active_users_5m) + sum(gabay_anonymous_users_5m)
```

---

## 🎨 Grafana Dashboards

### **Add Anonymous User Panels:**

**Query for Anonymous Users:**
```promql
sum(gabay_anonymous_users_5m)
```

**Query for Total Users:**
```promql
sum(gabay_active_users_5m) + sum(gabay_anonymous_users_5m)
```

**Query for User Type Breakdown:**
```promql
# Authenticated
sum(gabay_active_users_15m{tenant="$tenant"})

# Anonymous  
sum(gabay_anonymous_users_15m{tenant="$tenant"})
```

---

## 🔍 How Session IDs Work

### **Session ID Generation:**

```typescript
generateSessionId(req):
  1. PRIMARY: Use UUID header (already sent with every request)
     - req.headers['uuid'] or req.headers['x-uuid']
     - This is what your frontend already sends!
  2. Fallback: Check cookie or header
     - req.cookies.sessionId
     - req.headers['x-session-id']
  3. Last resort: Create from IP + User-Agent
     - Only if UUID header is missing
```

### **Examples:**

| Scenario | Session ID Source | Notes |
|----------|-------------------|-------|
| Normal request (frontend) | `uuid` header | ✅ MOST COMMON - Already implemented! |
| Same user, same session | Same UUID | Tracked once |
| Same user, new session | New UUID | Tracked as different session |
| Request without UUID | IP + User-Agent | Rare fallback |

### **Privacy:**

- ✅ No personal data stored
- ✅ Only counts unique sessions
- ✅ Session IDs are anonymized
- ✅ Auto-expires after time window

---

## 🧪 Testing

### **Test Anonymous Tracking:**

```bash
# 1. Check current anonymous user count
curl.exe http://localhost:3001/api/metrics | Select-String "gabay_anonymous_users"

# Should show:
# gabay_anonymous_users_5m{tenant="aans"} 0
# gabay_anonymous_users_15m{tenant="aans"} 0
# gabay_anonymous_users_1h{tenant="aans"} 0
```

```bash
# 2. Access a public form (not logged in)
# Open in browser: http://localhost:3000/forms/some-form-slug
```

```bash
# 3. Wait 30 seconds (for gauge update)

# 4. Check metrics again
curl.exe http://localhost:3001/api/metrics | Select-String "gabay_anonymous_users"

# Should show:
# gabay_anonymous_users_5m{tenant="aans"} 1  ← You!
# gabay_anonymous_users_15m{tenant="aans"} 1
# gabay_anonymous_users_1h{tenant="aans"} 1
```

---

## 📊 Use Cases

### **1. Public Form Analytics**

Track how many people are viewing/filling forms:

```promql
# Form viewers (anonymous)
gabay_anonymous_users_5m

# Logged-in form submitters
gabay_active_users_5m

# Total engagement
sum(gabay_active_users_5m) + sum(gabay_anonymous_users_5m)
```

### **2. Conversion Tracking**

See conversion from anonymous to authenticated:

```promql
# Anonymous visitors
sum(gabay_anonymous_users_1h)

# Authenticated users (converted)
sum(gabay_active_users_1h)

# Conversion rate (if they register/login)
```

### **3. Public Content Popularity**

Track which public content is most viewed:

```promql
# Most popular tenant (by public views)
topk(10, sum by (tenant) (gabay_anonymous_users_15m))
```

### **4. Capacity Planning**

Plan for both logged-in and anonymous traffic:

```promql
# Peak total users
max_over_time((sum(gabay_active_users_5m) + sum(gabay_anonymous_users_5m))[24h])
```

---

## 🎯 When to Use Each

### **Use `trackUserActivity()` when:**
- ✅ User is **logged in** (has userId)
- ✅ Request is **authenticated**
- ✅ You want to track **who** is active

### **Use `trackAnonymousActivity()` when:**
- ✅ User is **NOT logged in**
- ✅ Public/guest access
- ✅ You want to track **how many** visitors

---

## 🔧 Configuration

### **Redis Keys:**

**Authenticated:**
```
user_activity:{tenant}:5m   → Sorted set of userIds
user_activity:{tenant}:15m
user_activity:{tenant}:1h
```

**Anonymous:**
```
anon_activity:{tenant}:5m   → Sorted set of sessionIds
anon_activity:{tenant}:15m
anon_activity:{tenant}:1h
```

### **Time Windows:**

```typescript
// In user-activity.service.ts
private readonly WINDOW_5M = 300;    // 5 minutes
private readonly WINDOW_15M = 900;   // 15 minutes
private readonly WINDOW_1H = 3600;   // 1 hour
```

---

## ✅ Benefits

### **vs Google Analytics:**

| Feature | Gabay Tracking | Google Analytics |
|---------|----------------|------------------|
| **Anonymous users** | ✅ Tracked | ✅ Tracked |
| **Authenticated users** | ✅ Tracked separately | ⚠️ Mixed with anonymous |
| **Real-time** | ✅ 30s refresh | ❌ 5-10 min delay |
| **Server-side** | ✅ Can't be blocked | ❌ Blocked by ad-blockers |
| **Privacy** | ✅ Your data | ❌ Goes to Google |
| **Per-tenant** | ✅ Native | ⚠️ Complex filtering |
| **API activity** | ✅ Tracks all | ❌ Misses backend |

### **Key Advantages:**

1. **Separate Metrics** - Know exactly how many are logged in vs anonymous
2. **Real-time** - Updates every 30 seconds
3. **Privacy-friendly** - No cookies or tracking pixels needed
4. **Can't be blocked** - Server-side tracking
5. **Same system** - Integrated with your existing monitoring

---

## 📝 Summary

**You now have TWO types of user tracking:**

1. **Authenticated Users** 👤
   - Tracked in `authenticate()` middleware
   - Requires login
   - Metrics: `gabay_active_users_*`

2. **Anonymous Users** 👻 (NEW!)
   - Tracked manually in public endpoints
   - No login required
   - Metrics: `gabay_anonymous_users_*`

**Both:**
- ✅ Non-blocking (zero performance impact)
- ✅ Real-time (30s update)
- ✅ Per-tenant separation
- ✅ Multiple time windows (5m, 15m, 1h)
- ✅ Prometheus + Grafana ready

---

## 🚀 Next Steps

1. **Test it:**
   - Access a public form
   - Check metrics after 30s
   - See yourself counted!

2. **Add to more endpoints:**
   - Any public content
   - Guest features
   - Landing pages

3. **Create dashboards:**
   - Anonymous vs Authenticated breakdown
   - Conversion funnels
   - Public content popularity

4. **Monitor trends:**
   - Track growth over time
   - Identify popular content
   - Plan capacity

---

**Happy tracking!** 📊👤👻✨
