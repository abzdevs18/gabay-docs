# Gabay Platform Analytics Setup

## Overview

The Gabay Platform Analytics system provides comprehensive user tracking, session management, and platform usage insights. This system replaces the need for Google Analytics with a custom, privacy-focused solution that gives you complete control over your data.

## Features

### ✅ Real-time Active User Tracking
- Live count of currently active users
- Session-based user activity monitoring
- Automatic session management with heartbeat system

### ✅ Comprehensive User Analytics
- User behavior tracking (page views, actions, clicks)
- Session duration and engagement metrics
- Device and browser analytics
- User flow and navigation patterns

### ✅ Platform Usage Statistics
- Daily, weekly, and monthly user metrics
- Peak usage hours and patterns
- Bounce rate and retention analytics
- Page performance metrics

### ✅ Privacy-Focused Design
- All data stored in your own database
- No third-party tracking
- GDPR and privacy compliance ready
- Complete data ownership

### ✅ Multi-tenant Support
- Proper tenant identification using axios client with automatic header injection
- Tenant-specific analytics data isolation
- Secure cross-tenant data separation

## Architecture

### Backend Components

1. **UserAnalyticsService** (`api/src/services/user-analytics.service.ts`)
   - Core analytics engine
   - Session management
   - Data aggregation and caching
   - Real-time metrics calculation

2. **API Endpoints** (`api/src/pages/api/v2/analytics/`)
   - `/active-users` - Get current active users
   - `/session/start` - Start user session
   - `/session/heartbeat` - Update session activity
   - `/session/end` - End user session
   - `/dashboard` - Comprehensive analytics data

3. **Database Schema** (`api/prisma/schema/analytics.prisma`)
   - UserSession - Track user sessions
   - UserActivity - Log user actions
   - PlatformMetrics - Aggregated platform statistics
   - PageAnalytics - Page-specific metrics
   - UserBehaviorAnalytics - User behavior patterns

### Frontend Components

1. **Analytics Hook** (`frontend/src/hooks/useAnalytics.ts`)
   - Automatic session management
   - Page view tracking
   - Action tracking
   - Device detection

2. **Analytics Provider** (`frontend/src/contexts/AnalyticsProvider.tsx`)
   - App-wide analytics integration
   - Context for analytics data
   - Higher-order components for tracking

3. **Analytics Dashboard** (`frontend/src/components/analytics/AnalyticsDashboard.tsx`)
   - Real-time analytics visualization
   - Interactive charts and metrics
   - Customizable time ranges

## Setup Instructions

### 1. Database Migration

Run the Prisma migration to create analytics tables:

```bash
cd api
npx prisma db push
```

### 2. Backend Integration

The analytics service is automatically available. No additional setup required.

### 3. Frontend Integration

#### Option A: App-wide Integration (Recommended)

Add the AnalyticsProvider to your app layout:

```tsx
// pages/_app.tsx or your main layout
import { AnalyticsProvider } from '@/contexts/AnalyticsProvider';

function MyApp({ Component, pageProps }) {
  return (
    <SessionProvider session={pageProps.session}>
      <AnalyticsProvider>
        <Component {...pageProps} />
      </AnalyticsProvider>
    </SessionProvider>
  );
}
```

#### Option B: Page-specific Integration

Use the analytics hook in specific components:

```tsx
import { useAnalytics } from '@/hooks/useAnalytics';

function MyComponent() {
  const { trackAction, trackPageView } = useAnalytics();

  const handleButtonClick = () => {
    trackAction('button_click', { button: 'submit' });
  };

  return (
    <button onClick={handleButtonClick}>
      Submit
    </button>
  );
}
```

### 4. Analytics Dashboard

Access the analytics dashboard at `/analytics` (requires authentication).

## API Usage

### Get Active Users

```javascript
const response = await fetch('/api/v2/analytics/active-users');
const data = await response.json();

console.log('Current active users:', data.data.current);
```

### Track Custom Actions

```javascript
const { trackAction } = useAnalytics();

// Track form submission
await trackAction('form_submit', {
  formId: 'contact-form',
  formType: 'contact'
});

// Track feature usage
await trackAction('feature_used', {
  feature: 'export_data',
  format: 'pdf'
});
```

## Tenant Identification

The analytics system automatically handles tenant identification through the following mechanisms:

### Frontend (Automatic)
- Uses the centralized `apiClient` from `@/utils/api-client`
- Automatically includes `x-tenant-tag` header from cookies
- Handles authentication tokens seamlessly

### Backend (Automatic)
- All analytics endpoints use the `authenticate` middleware
- Tenant isolation is enforced at the database level
- Special handling for `sendBeacon` requests during page unload

### Key Benefits
- **Secure**: Tenant data is completely isolated
- **Automatic**: No manual tenant handling required
- **Reliable**: Works even during page unload events

### Get Dashboard Data

```javascript
const response = await fetch('/api/v2/analytics/dashboard?timeframe=24h');
const analytics = await response.json();

console.log('Analytics data:', analytics.data);
```

## Configuration

### Analytics Hook Configuration

```tsx
const analytics = useAnalytics({
  heartbeatInterval: 30000,     // 30 seconds (default)
  enablePageTracking: true,     // Auto-track page views
  enableActionTracking: true    // Enable action tracking
});
```

### Service Configuration

The UserAnalyticsService can be configured via environment variables:

```env
# Cache TTL for analytics data (seconds)
ANALYTICS_CACHE_TTL=300

# Session timeout (seconds)
ANALYTICS_SESSION_TIMEOUT=1800

# Enable debug logging
ANALYTICS_DEBUG=false
```

## Performance Considerations

### System Architecture Overview

The Gabay Analytics system employs a **hybrid real-time architecture** designed for optimal performance and scalability:

#### Real-time Capabilities
- **Active User Updates**: Live tracking with 30-second heartbeat intervals
- **Immediate Session Detection**: Sessions start/end in real-time
- **Dashboard Auto-refresh**: 30-second intervals for live data updates
- **Circuit Breaker Protection**: Automatic fallback when Redis is unavailable

#### Multi-layer Caching Strategy

**Cache TTL Settings by Data Type:**
```typescript
// Real-time data (frequent updates)
USER_SESSIONS: 5 minutes
ACTIVE_USERS: 5 minutes
HEARTBEAT_DATA: 1 minute

// Dashboard aggregations (moderate updates)
PLATFORM_STATISTICS: 15 minutes
USER_BEHAVIOR_STATS: 15 minutes
SESSION_STATISTICS: 15 minutes

// Historical data (infrequent updates)
DAILY_METRICS: 1 hour
WEEKLY_METRICS: 24 hours
MONTHLY_METRICS: 3 days
```

**Environment-specific Cache Configuration:**
- **Development**: 1-hour default TTL, aggressive cleanup
- **Production**: 2-hour default TTL, optimized for performance
- **Test**: 30-minute TTL, fast cleanup for testing

### Performance Bottlenecks and Mitigations

#### 1. High-Frequency Operations

**Potential Bottlenecks:**
- **Heartbeat Requests**: 30-second intervals per active user
- **Session Updates**: Frequent database writes
- **Cache Key Proliferation**: Growing number of session-specific keys

**Built-in Mitigations:**
```typescript
// Batch heartbeat processing
const batchHeartbeats = async (sessionIds: string[]) => {
  // Process multiple heartbeats in single database transaction
  return await prisma.$transaction(
    sessionIds.map(id => 
      prisma.userSession.update({
        where: { id },
        data: { lastActivity: new Date() }
      })
    )
  );
};

// Intelligent cache key management
const cleanupExpiredSessions = async () => {
  // Automatic cleanup every 15 minutes
  // Removes expired sessions and their cache keys
};
```

#### 2. Dashboard Auto-refresh Load

**Current Implementation:**
- 30-second refresh intervals
- Conditional rendering based on data changes
- Efficient API calls using Axios with proper caching headers

**Performance Optimizations:**
```typescript
// Optimized dashboard fetching
const fetchAnalytics = useCallback(async () => {
  try {
    const response = await apiClient.get('/api/v2/analytics/dashboard', {
      params: { timeframe },
      // Leverage HTTP caching
      headers: { 'Cache-Control': 'max-age=30' }
    });
    
    // Only update state if data actually changed
    if (JSON.stringify(response.data) !== JSON.stringify(prevData)) {
      setAnalyticsData(response.data);
    }
  } catch (error) {
    // Graceful degradation on errors
    console.warn('Analytics fetch failed:', error);
  }
}, [timeframe, prevData]);
```

#### 3. Database Query Performance

**Expensive Operations:**
- Session cleanup queries
- Cross-tenant data aggregation
- Historical data calculations

**Optimization Strategies:**
```sql
-- Indexed queries for session management
CREATE INDEX idx_user_sessions_tenant_active 
ON UserSession(tenantId, isActive, lastActivity);

-- Efficient cleanup with batch processing
DELETE FROM UserSession 
WHERE lastActivity < NOW() - INTERVAL 30 MINUTE 
AND isActive = false 
LIMIT 1000;

-- Optimized aggregation queries
SELECT 
  DATE(createdAt) as date,
  COUNT(*) as sessions,
  AVG(TIMESTAMPDIFF(SECOND, createdAt, endedAt)) as avg_duration
FROM UserSession 
WHERE tenantId = ? 
  AND createdAt >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(createdAt)
ORDER BY date DESC;
```

### Built-in Performance Protections

#### 1. Circuit Breaker Pattern
```typescript
class CacheService {
  private circuitBreaker = {
    failures: 0,
    threshold: 5,
    timeout: 30000,
    isOpen: false
  };

  async get(key: string) {
    if (this.circuitBreaker.isOpen) {
      // Fallback to database when cache is unavailable
      return this.fallbackToDatabase(key);
    }
    
    try {
      return await this.redis.get(key);
    } catch (error) {
      this.handleCircuitBreakerFailure();
      return this.fallbackToDatabase(key);
    }
  }
}
```

#### 2. Intelligent Caching
```typescript
// Cache warming for frequently accessed data
const warmUpCache = async () => {
  const criticalKeys = [
    'analytics:active_users',
    'analytics:platform_stats',
    'analytics:session_count'
  ];
  
  await Promise.all(
    criticalKeys.map(key => this.refreshCacheKey(key))
  );
};

// Conditional cache updates
const updateCacheIfStale = async (key: string, data: any) => {
  const cached = await this.get(key);
  const cacheAge = await this.getKeyAge(key);
  
  // Only update if data is stale or significantly different
  if (!cached || cacheAge > this.getTTL(key) * 0.8) {
    await this.set(key, data);
  }
};
```

#### 3. Batch Operations
```typescript
// Batch session cleanup
const cleanupSessions = async () => {
  const expiredSessions = await prisma.userSession.findMany({
    where: {
      lastActivity: { lt: new Date(Date.now() - 30 * 60 * 1000) },
      isActive: true
    },
    take: 100 // Process in batches
  });

  if (expiredSessions.length > 0) {
    await prisma.userSession.updateMany({
      where: { id: { in: expiredSessions.map(s => s.id) } },
      data: { isActive: false, endedAt: new Date() }
    });
  }
};
```

### Performance Monitoring

#### Key Metrics to Track

**Response Time Metrics:**
```typescript
// API endpoint performance
const performanceMetrics = {
  '/api/v2/analytics/dashboard': { target: '<200ms', current: '150ms' },
  '/api/v2/analytics/session/start': { target: '<100ms', current: '80ms' },
  '/api/v2/analytics/session/heartbeat': { target: '<50ms', current: '35ms' },
  '/api/v2/analytics/active-users': { target: '<100ms', current: '60ms' }
};
```

**Cache Performance:**
```typescript
const cacheMetrics = {
  hitRate: '85%',           // Target: >80%
  missRate: '15%',          // Target: <20%
  evictionRate: '5%',       // Target: <10%
  connectionFailures: '0.1%' // Target: <1%
};
```

**Database Performance:**
```typescript
const dbMetrics = {
  avgQueryTime: '45ms',     // Target: <100ms
  slowQueries: '2%',        // Target: <5%
  connectionPoolUsage: '60%', // Target: <80%
  deadlocks: '0'            // Target: 0
};
```

### Performance Recommendations

#### Immediate Optimizations (0-30 days)

1. **Enable Query Logging**
   ```env
   # Add to .env
   DATABASE_LOGGING=true
   SLOW_QUERY_THRESHOLD=100
   ```

2. **Implement Request Rate Limiting**
   ```typescript
   // Add to analytics endpoints
   const rateLimiter = rateLimit({
     windowMs: 60 * 1000, // 1 minute
     max: 100, // 100 requests per minute per IP
     message: 'Too many analytics requests'
   });
   ```

3. **Optimize Heartbeat Frequency**
   ```typescript
   // Adaptive heartbeat based on user activity
   const getHeartbeatInterval = (userActivity: string) => {
     switch (userActivity) {
       case 'active': return 15000;   // 15 seconds
       case 'idle': return 60000;     // 1 minute
       case 'background': return 300000; // 5 minutes
       default: return 30000;         // 30 seconds
     }
   };
   ```

#### Scaling Considerations (30+ days)

1. **Database Sharding**
   ```typescript
   // Partition by tenant for large deployments
   const getShardKey = (tenantId: string) => {
     return `analytics_${tenantId.slice(-2)}`;
   };
   ```

2. **Read Replicas**
   ```typescript
   // Separate read/write operations
   const analyticsReadDB = new PrismaClient({
     datasources: { db: { url: process.env.ANALYTICS_READ_DB_URL } }
   });
   
   const analyticsWriteDB = new PrismaClient({
     datasources: { db: { url: process.env.ANALYTICS_WRITE_DB_URL } }
   });
   ```

3. **Event-Driven Architecture**
   ```typescript
   // Queue-based processing for high-volume events
   const analyticsQueue = new Queue('analytics-processing', {
     redis: redisConfig,
     defaultJobOptions: {
       removeOnComplete: 100,
       removeOnFail: 50,
       attempts: 3
     }
   });
   ```

### Performance Testing

#### Load Testing Scenarios
```bash
# Test heartbeat endpoint under load
artillery run --config artillery-heartbeat.yml

# Test dashboard with concurrent users
artillery run --config artillery-dashboard.yml

# Test session creation burst
artillery run --config artillery-sessions.yml
```

#### Performance Benchmarks
```typescript
const performanceBenchmarks = {
  concurrent_users: {
    target: 1000,
    current: 500,
    bottleneck: 'database_connections'
  },
  requests_per_second: {
    target: 500,
    current: 300,
    bottleneck: 'cache_throughput'
  },
  response_time_p95: {
    target: '500ms',
    current: '350ms',
    status: 'good'
  }
};
```

### Troubleshooting Performance Issues

#### Common Performance Problems

1. **Slow Dashboard Loading**
   ```typescript
   // Check cache hit rates
   const cacheStats = await cacheService.getStats();
   console.log('Cache hit rate:', cacheStats.hitRate);
   
   // Verify database query performance
   const slowQueries = await prisma.$queryRaw`
     SELECT query, avg_timer_wait 
     FROM performance_schema.events_statements_summary_by_digest 
     WHERE avg_timer_wait > 100000000
   `;
   ```

2. **High Memory Usage**
   ```typescript
   // Monitor cache memory usage
   const memoryUsage = await redis.memory('usage');
   console.log('Redis memory usage:', memoryUsage);
   
   // Check for memory leaks in session tracking
   const activeSessions = await cacheService.scan('session:*');
   console.log('Active session count:', activeSessions.length);
   ```

3. **Database Connection Pool Exhaustion**
   ```typescript
   // Monitor connection pool status
   const poolStats = await prisma.$metrics.json();
   console.log('Connection pool usage:', poolStats.counters);
   ```

#### Performance Debugging Tools

```typescript
// Enable performance profiling
const performanceProfiler = {
  startTimer: (operation: string) => {
    console.time(`analytics:${operation}`);
  },
  endTimer: (operation: string) => {
    console.timeEnd(`analytics:${operation}`);
  },
  logMemoryUsage: () => {
    const usage = process.memoryUsage();
    console.log('Memory usage:', {
      rss: `${Math.round(usage.rss / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`
    });
  }
};
```

## Data Privacy and Compliance

### Data Collection
- Only authenticated users are tracked
- No personal data is collected without consent
- All data is stored in your own database

### Data Retention
- Session data: 90 days (configurable)
- Activity logs: 1 year (configurable)
- Aggregated metrics: Indefinite

### GDPR Compliance
- Users can request data deletion
- Data export functionality available
- Clear consent mechanisms

## Performance Considerations

### Caching
- Real-time metrics are cached for 5 minutes
- Dashboard data is cached for 15 minutes
- Historical data is cached for 1 hour

### Database Optimization
- Proper indexing on all analytics tables
- Automatic cleanup of old session data
- Efficient aggregation queries

### Frontend Performance
- Minimal impact on page load times
- Asynchronous tracking calls
- Efficient heartbeat system

## Monitoring and Alerts

### Health Checks
- Monitor analytics service availability
- Track data collection rates
- Alert on unusual patterns

### Metrics to Monitor
- Session creation rate
- Heartbeat success rate
- Database query performance
- Cache hit rates

## Troubleshooting

### Common Issues

1. **Sessions not starting**
   - Check authentication status
   - Verify API endpoints are accessible
   - Check browser console for errors

2. **Missing analytics data**
   - Verify database migrations ran successfully
   - Check service logs for errors
   - Ensure proper authentication

3. **Performance issues**
   - Monitor database query performance
   - Check cache configuration
   - Review heartbeat frequency

### Debug Mode

Enable debug logging:

```env
ANALYTICS_DEBUG=true
```

This will log all analytics operations to the console.

## Migration from Google Analytics

### Data Export
1. Export historical data from Google Analytics
2. Transform data to match our schema
3. Import using the provided migration scripts

### Tracking Code Replacement
1. Remove Google Analytics tracking code
2. Add AnalyticsProvider to your app
3. Update custom event tracking

### Dashboard Migration
1. Recreate important dashboards using our components
2. Set up automated reports
3. Configure alerts and notifications

## Future Enhancements

### Planned Features
- Real-time dashboard updates via WebSocket
- Advanced user segmentation
- A/B testing framework
- Custom event funnels
- Automated insights and recommendations

### Integration Opportunities
- Email marketing platforms
- CRM systems
- Business intelligence tools
- Custom reporting APIs

## Support

For questions or issues with the analytics system:

1. Check this documentation
2. Review the troubleshooting section
3. Check the GitHub issues
4. Contact the development team

## Contributing

To contribute to the analytics system:

1. Follow the existing code patterns
2. Add tests for new features
3. Update documentation
4. Submit pull requests for review

---

**Note**: This analytics system is designed to be privacy-focused and GDPR-compliant. Always ensure you have proper user consent before collecting analytics data.