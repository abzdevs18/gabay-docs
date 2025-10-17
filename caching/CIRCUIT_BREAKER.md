# Circuit Breaker Pattern

**Purpose:** Prevent cascading failures when Redis is unavailable

---

## What is a Circuit Breaker?

A circuit breaker acts like an **electrical circuit breaker** in your home. When it detects too many failures, it "opens the circuit" to prevent further damage, then periodically tests if the system has recovered.

### The Problem Without Circuit Breaker

```
Redis goes down at 10:00 AM

Request 1: Try Redis → Timeout (5s) → Fall back to DB
Request 2: Try Redis → Timeout (5s) → Fall back to DB
Request 3: Try Redis → Timeout (5s) → Fall back to DB
...
Request 1000: Try Redis → Timeout (5s) → Fall back to DB

Total wasted time: 5000 seconds (83 minutes)
User experience: Every request takes 5+ seconds
```

### The Solution With Circuit Breaker

```
Redis goes down at 10:00 AM

Request 1-5: Try Redis → Fail quickly
Request 5 triggers: Circuit OPENS (stop trying)

Request 6-1000: Skip Redis immediately (0.001s check)
Total saved time: 4,995 seconds (83 minutes)
User experience: Requests complete in <1s

At 10:00:30 (after 30s): Circuit goes HALF_OPEN
Request 1001: Try Redis once
  ├─ Success → Circuit CLOSED (back to normal)
  └─ Failure → Circuit stays OPEN (try again in 30s)
```

---

## State Machine

### Three States

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌──────────┐                               │
│  │  CLOSED  │ ◄─── Normal operation         │
│  │   (0)    │      Track failures           │
│  └────┬─────┘                               │
│       │                                     │
│       │ 5 failures detected                 │
│       ↓                                     │
│  ┌──────────┐                               │
│  │   OPEN   │ ◄─── Redis is down            │
│  │   (1)    │      Skip all Redis calls     │
│  └────┬─────┘      (fast-fail)              │
│       │                                     │
│       │ After 30-second timeout             │
│       ↓                                     │
│  ┌──────────┐                               │
│  │ HALF_OPEN│ ◄─── Testing recovery         │
│  │   (2)    │      Allow 1 trial request    │
│  └────┬─────┘                               │
│       │                                     │
│       ├─ Trial succeeds → CLOSED            │
│       └─ Trial fails → OPEN (retry in 30s)  │
│                                             │
└─────────────────────────────────────────────┘
```

---

## State Details

### CLOSED (Value: 0)

**Meaning:** Everything is working normally

**Behavior:**
- All Redis operations are allowed
- Failures are counted
- If 5 consecutive failures occur → transition to OPEN

**Code:**
```typescript
if (this.circuitState === CircuitBreakerState.CLOSED) {
  try {
    return await redis.get(key);
  } catch (error) {
    this.failureCount++;
    if (this.failureCount >= 5) {
      this.circuitState = CircuitBreakerState.OPEN;
      prometheusMetrics.cacheCircuitBreakerState.set(1);
    }
  }
}
```

**Prometheus Metric:** `gabay_cache_circuit_breaker_state = 0`

---

### OPEN (Value: 1)

**Meaning:** Redis is down, stop trying to connect

**Behavior:**
- All Redis operations fail immediately (no network calls)
- Returns `null` without attempting Redis
- After 30 seconds of being OPEN → transition to HALF_OPEN

**Code:**
```typescript
if (this.circuitState === CircuitBreakerState.OPEN) {
  // Check if recovery timeout has passed
  if (Date.now() - this.lastFailureTime > 30000) {
    this.circuitState = CircuitBreakerState.HALF_OPEN;
    // Allow next operation to try Redis
  } else {
    console.error('[CacheService] Circuit is OPEN. Operation skipped.');
    return null; // Fast-fail
  }
}
```

**Benefits:**
- Saves 50-100ms per request during Redis outage
- Prevents connection pool exhaustion
- Application remains responsive

**Prometheus Metric:** `gabay_cache_circuit_breaker_state = 1`

**Alert:**
```yaml
- alert: CacheCircuitBreakerOpen
  expr: gabay_cache_circuit_breaker_state == 1
  for: 2m
  annotations:
    summary: "Redis circuit breaker is OPEN"
    description: "Cache service has opened circuit breaker due to Redis failures"
```

---

### HALF_OPEN (Value: 2)

**Meaning:** Testing if Redis has recovered

**Behavior:**
- Allows **one trial operation** to attempt Redis
- If trial succeeds → transition to CLOSED (recovery complete)
- If trial fails → transition back to OPEN (wait another 30s)

**Code:**
```typescript
if (this.circuitState === CircuitBreakerState.HALF_OPEN) {
  try {
    const result = await redis.get(key);
    // Success! Redis is back
    this.circuitState = CircuitBreakerState.CLOSED;
    this.failureCount = 0;
    prometheusMetrics.cacheCircuitBreakerState.set(0);
    console.info('[CacheService] Circuit breaker CLOSED - Redis recovered');
    return result;
  } catch (error) {
    // Still down, go back to OPEN
    this.circuitState = CircuitBreakerState.OPEN;
    this.lastFailureTime = Date.now();
    prometheusMetrics.cacheCircuitBreakerState.set(1);
    return null;
  }
}
```

**Prometheus Metric:** `gabay_cache_circuit_breaker_state = 2`

---

## Configuration

```typescript
const CACHE_CONFIG = {
  FAILURE_THRESHOLD: 5,      // Open circuit after 5 failures
  RECOVERY_TIMEOUT: 30000,   // Test recovery after 30 seconds
  MAX_RETRIES: 3,            // Retry failed operations 3 times
  RETRY_DELAY: 1000          // Wait 1 second between retries
};
```

### Tuning Guidelines

| Parameter | Increase if... | Decrease if... |
|-----------|---------------|---------------|
| `FAILURE_THRESHOLD` | Transient errors are common | Want faster failure detection |
| `RECOVERY_TIMEOUT` | Redis takes long to restart | Want faster recovery attempts |
| `MAX_RETRIES` | Network is unstable | Want faster failure response |

---

## Reconnection with Exponential Backoff

When Redis connection is lost, the system attempts automatic reconnection with **exponential backoff**:

```typescript
private async attemptReconnection(): Promise<void> {
  if (this.reconnectAttempts >= 10) {
    console.error('[CacheService] Max reconnection attempts reached.');
    return; // Give up after 10 attempts (~5 minutes)
  }
  
  this.reconnectAttempts++;
  
  // Calculate backoff: 2s, 4s, 8s, 16s, 30s (capped)
  const backoffDelay = Math.min(
    1000 * Math.pow(2, this.reconnectAttempts), 
    30000
  );
  
  console.warn(
    `[CacheService] Reconnection attempt ${this.reconnectAttempts}/10 in ${backoffDelay}ms`
  );
  
  setTimeout(() => {
    this.checkRedisConnection();
  }, backoffDelay);
}
```

### Backoff Schedule

| Attempt | Delay | Cumulative Time |
|---------|-------|-----------------|
| 1 | 2s | 2s |
| 2 | 4s | 6s |
| 3 | 8s | 14s |
| 4 | 16s | 30s |
| 5 | 30s | 60s |
| 6 | 30s | 90s |
| 7 | 30s | 120s |
| 8 | 30s | 150s |
| 9 | 30s | 180s |
| 10 | 30s | 210s |

**After 10 attempts (~5 minutes):** Manual intervention required

---

## Real-World Example

### Scenario: Redis Server Restart

```
10:00:00 - Redis restart initiated
10:00:01 - Request 1 fails (failure count: 1/5)
10:00:02 - Request 2 fails (failure count: 2/5)
10:00:03 - Request 3 fails (failure count: 3/5)
10:00:04 - Request 4 fails (failure count: 4/5)
10:00:05 - Request 5 fails (failure count: 5/5)
         → Circuit OPENS
         → Prometheus: gabay_cache_circuit_breaker_state = 1
         → Alert fires: CacheCircuitBreakerOpen

10:00:06 - Requests 6-100: Fast-fail (no Redis calls)
         → Saved: 95 × 50ms = 4,750ms
         → Users experience: Normal speed (no Redis delay)

10:00:35 - 30 seconds elapsed since circuit opened
         → Circuit transitions to HALF_OPEN
         → Prometheus: gabay_cache_circuit_breaker_state = 2

10:00:36 - Request 101 (trial request)
         → Redis is back up!
         → Trial succeeds
         → Circuit CLOSES
         → Prometheus: gabay_cache_circuit_breaker_state = 0
         → Alert resolves: CacheCircuitBreakerOpen

10:00:37 - Normal operation resumed
```

**Total downtime for users:** 0 seconds (graceful degradation worked)  
**Time saved:** 4.75 seconds of Redis timeout attempts

---

## Monitoring

### Grafana Panel

**Metric:** `gabay_cache_circuit_breaker_state`

**Panel Configuration:**
```json
{
  "type": "gauge",
  "title": "Circuit Breaker State",
  "mappings": [
    { "value": 0, "text": "CLOSED", "color": "green" },
    { "value": 1, "text": "OPEN", "color": "red" },
    { "value": 2, "text": "HALF-OPEN", "color": "yellow" }
  ]
}
```

### Prometheus Queries

```promql
# Current state
gabay_cache_circuit_breaker_state

# How many times circuit opened in last 24h
changes(gabay_cache_circuit_breaker_state[24h]) / 2

# Average time circuit is OPEN
avg_over_time(gabay_cache_circuit_breaker_state[1h]) > 0.5

# Reconnection attempts
gabay_cache_reconnection_attempts
```

---

## Troubleshooting

### Circuit Keeps Opening

**Symptoms:** `gabay_cache_circuit_breaker_state` frequently equals 1

**Possible Causes:**
1. Redis server is unstable
2. Network issues between API and Redis
3. Redis memory maxed out (evicting connections)
4. Firewall blocking connections

**Debug Steps:**
```bash
# Check Redis logs
docker logs redis

# Test Redis connection
redis-cli -h localhost -p 6379 PING

# Check Redis memory
redis-cli INFO memory

# Check network latency
ping -c 10 redis-host
```

### Circuit Never Closes After Redis Recovery

**Symptoms:** Circuit stays OPEN even though Redis is back up

**Cause:** Reconnection attempts may have exceeded max (10)

**Solution:**
```bash
# Restart API to reset circuit breaker
pm2 restart gabay-api

# Or wait for automatic recovery (circuit checks every 30s)
```

### False Positives

**Symptoms:** Circuit opens during normal operation

**Cause:** `FAILURE_THRESHOLD` is too low (currently 5)

**Solution:**
```typescript
// Increase threshold in cache.service.ts
const CACHE_CONFIG = {
  FAILURE_THRESHOLD: 10,  // Changed from 5
  // ...
};
```

---

## Best Practices

### 1. Always Monitor Circuit State

```typescript
// Log state changes
if (this.circuitState === CircuitBreakerState.OPEN) {
  console.error('[CacheService] Circuit breaker OPEN - Redis unavailable');
  // Send alert to monitoring system
}
```

### 2. Set Appropriate Timeouts

```typescript
// Redis client configuration
const redis = new Redis({
  host: 'localhost',
  port: 6379,
  connectTimeout: 5000,      // 5s max to connect
  commandTimeout: 3000,      // 3s max per command
  retryStrategy: (times) => {
    return Math.min(times * 50, 2000); // Max 2s
  }
});
```

### 3. Implement Graceful Degradation

```typescript
async get<T>(key: string): Promise<T | null> {
  if (!this.isRedisConnected || this.circuitState === CircuitBreakerState.OPEN) {
    // Don't throw error, just return null
    // Application continues without cache
    return null;
  }
  
  return await redis.get(key);
}
```

### 4. Test Circuit Breaker

```bash
# Simulate Redis failure
docker stop redis

# Make requests - should see circuit open after 5 failures
curl http://localhost:3001/api/some-endpoint

# Check circuit state
curl http://localhost:9090/api/v1/query?query=gabay_cache_circuit_breaker_state

# Restart Redis
docker start redis

# Circuit should close within 30-60 seconds
```

---

## Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall caching architecture
- [REDIS_INTEGRATION.md](./REDIS_INTEGRATION.md) - Redis configuration
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues

---

**Summary:** The circuit breaker protects your application from cascading failures by detecting Redis outages early and failing fast, saving 50-100ms per request during downtime and preventing connection pool exhaustion.
