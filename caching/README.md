# Gabay Caching System Documentation

**Version:** 3.1.0  
**Last Updated:** 2025-10-14

Welcome to the comprehensive Gabay Caching System documentation. This system implements a **multi-layer, resilient caching architecture** that reduced response times by 60-75% and improved cache hit rates from 20% to 85%.

## 📚 Documentation Structure

This folder contains complete documentation for the Gabay caching system:

### Core Documentation

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and design patterns
   - Multi-layer caching overview
   - Data flow diagrams
   - Component interactions
   
2. **[CIRCUIT_BREAKER.md](./CIRCUIT_BREAKER.md)** - Circuit breaker pattern explained
   - What it is and why we need it
   - State transitions (CLOSED → OPEN → HALF_OPEN)
   - Configuration and monitoring

3. **[TENANT_CACHING.md](./TENANT_CACHING.md)** - Tenant context caching
   - 3-layer cache (WeakMap → LRU → Redis)
   - JWT optimization
   - Performance metrics

4. **[REDIS_INTEGRATION.md](./REDIS_INTEGRATION.md)** - Redis caching layer
   - Connection management
   - Cache keys and TTLs
   - Health checks and resilience

5. **[METRICS.md](./METRICS.md)** - Performance monitoring
   - Prometheus metrics guide
   - Grafana dashboards
   - Alerting rules

6. **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🚀 Quick Start

### Performance Improvements (v3.1.0)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Tenant Cache Hit Rate** | 20.2% | 70-85% | **+3-4x** |
| **Response Time** | 2.01s | 0.5-1.2s | **-60-75%** |
| **Redis Pings** | ~10,000/min | ~12/min | **-99.9%** |
| **Downtime Events** | 18,900/day | <10/day | **-99.9%** |

### Key Features

- 🚀 **Multi-Layer Caching**: Request-scoped → LRU memory → Redis → Database
- 🔄 **Circuit Breaker**: Auto-recovery from Redis failures
- 💾 **LRU Cache**: Cross-request tenant context (5-min TTL, 1000 entries)
- 🛡️ **Graceful Degradation**: Application continues when Redis is down
- 📊 **Observable**: Full Prometheus metrics

## 🏗️ Architecture Overview

```
Request → [L1: WeakMap] → [L2: LRU Cache] → [L3: Redis] → [DB Query]
            <0.001ms         <0.01ms           5-15ms       30-50ms
            
          ├─ Hit: Return immediately
          └─ Miss: Next layer
          
Circuit Breaker monitors Redis health:
  CLOSED → Normal operations
  OPEN → Fast-fail (Redis down)
  HALF_OPEN → Testing recovery
```

## 📖 Reading Guide

### For Developers
1. Start with [ARCHITECTURE.md](./ARCHITECTURE.md)
2. Understand [CIRCUIT_BREAKER.md](./CIRCUIT_BREAKER.md)
3. Learn [TENANT_CACHING.md](./TENANT_CACHING.md)
4. Review [METRICS.md](./METRICS.md) for monitoring

### For DevOps/SRE
1. Read [REDIS_INTEGRATION.md](./REDIS_INTEGRATION.md)
2. Review [METRICS.md](./METRICS.md) for alerts
3. Study [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### For Product/Business
See "Performance Improvements" section above for impact metrics.

## 🔍 Quick Reference

### Cache Layers

| Layer | Type | Speed | Hit Rate | Lifetime |
|-------|------|-------|----------|----------|
| L1 | WeakMap | <0.001ms | 100% (within request) | Request duration |
| L2 | LRU Cache | <0.01ms | 70-85% | 5 minutes |
| L3 | Redis | 5-15ms | 90-95% | 1 hour - 3 days |
| DB | Database | 30-50ms | N/A | N/A |

### Circuit Breaker States

| State | Value | Meaning | Redis Calls? |
|-------|-------|---------|--------------|
| CLOSED | 0 | Healthy | ✅ Yes |
| OPEN | 1 | Redis down | ❌ No (fast-fail) |
| HALF_OPEN | 2 | Testing | ⚠️ One trial |

### Key Metrics

```promql
# Overall cache hit rate
sum(rate(gabay_tenant_cache_hits_total[5m])) / 
(sum(rate(gabay_tenant_cache_hits_total[5m])) + 
 sum(rate(gabay_tenant_cache_misses_total[5m]))) * 100

# Redis health
gabay_redis_health  # 1 = UP, 0 = DOWN

# Circuit breaker state
gabay_cache_circuit_breaker_state  # 0 = CLOSED, 1 = OPEN, 2 = HALF_OPEN
```

## 📊 Monitoring

**Grafana Dashboard:** http://localhost:3002/d/gabay-cache-performance

Critical panels:
- 🟢 Redis Health Status
- 🔴 Circuit Breaker State  
- 📊 Tenant Cache Hit Rate (target: 70-85%)
- 📈 LRU Cache Size (monitor utilization)

## 🚨 Alerts

Key alerts configured in Prometheus:

1. **TenantCacheLowHitRate** - Hit rate <50% for 5 minutes
2. **CircuitBreakerOpen** - Circuit breaker OPEN for >2 minutes
3. **RedisDown** - Redis unreachable
4. **LRUCacheNearFull** - LRU cache >90% capacity

## 🛠️ Common Tasks

### Clear All Caches
```bash
# Redis
redis-cli FLUSHDB

# Application restart (clears in-memory caches)
pm2 restart gabay-api
```

### Check Cache Stats
```bash
# Redis info
redis-cli INFO keyspace

# Prometheus query (via Grafana or API)
curl http://localhost:9090/api/v1/query?query=gabay_cache_lru_size
```

### Force Cache Warm-up
Not needed - automatic every 10-30 minutes

## 📞 Support

Issues? Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) first.

For questions, contact the backend team or create an issue in the repository.

---

**Related Documentation:**
- [Monitoring System](../monitoring/README.md)
- [Tenant Identification](../tenant-identification/README.md)
- [Backend Guide](../../BACKEND_GUIDE.md)
