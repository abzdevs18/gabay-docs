# Prometheus Metrics - Quick Reference

## 🚀 Quick Commands

### Start Monitoring
```bash
docker-compose -f docker-compose.monitoring.yml up -d
```

### Stop Monitoring
```bash
docker-compose -f docker-compose.monitoring.yml down
```

### View Logs
```bash
docker-compose -f docker-compose.monitoring.yml logs -f prometheus
docker-compose -f docker-compose.monitoring.yml logs -f grafana
```

### Restart Services
```bash
docker-compose -f docker-compose.monitoring.yml restart
```

---

## 🔗 Quick Links

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3002 | admin / admin123 |
| **Prometheus** | http://localhost:9090 | None |
| **Metrics Endpoint** | http://localhost:3001/api/metrics | None |
| **Node Exporter** | http://localhost:9100 | None |

---

## 📊 Most Useful Queries

### Performance Metrics

```promql
# Requests per second (total)
sum(rate(gabay_http_requests_total[5m]))

# Requests per second by tenant
sum by (tenant) (rate(gabay_http_requests_total[5m]))

# P50, P95, P99 response times
histogram_quantile(0.50, sum(rate(gabay_http_request_duration_seconds_bucket[5m])) by (le))
histogram_quantile(0.95, sum(rate(gabay_http_request_duration_seconds_bucket[5m])) by (le))
histogram_quantile(0.99, sum(rate(gabay_http_request_duration_seconds_bucket[5m])) by (le))

# Error rate
sum(rate(gabay_http_request_errors_total[5m])) / sum(rate(gabay_http_requests_total[5m])) * 100
```

### Cache Metrics

```promql
# Overall cache hit rate
sum(rate(gabay_redis_cache_hits_total[5m])) / 
(sum(rate(gabay_redis_cache_hits_total[5m])) + sum(rate(gabay_redis_cache_misses_total[5m]))) * 100

# Tenant cache hit rate by type
sum by (cache_type) (rate(gabay_tenant_cache_hits_total[5m])) / 
(sum by (cache_type) (rate(gabay_tenant_cache_hits_total[5m])) + sum by (cache_type) (rate(gabay_tenant_cache_misses_total[5m]))) * 100

# Bootstrap cache effectiveness
sum(rate(gabay_bootstrap_cache_hits_total[5m])) / 
(sum(rate(gabay_bootstrap_cache_hits_total[5m])) + sum(rate(gabay_bootstrap_cache_misses_total[5m]))) * 100
```

### Tenant Identification Metrics

```promql
# Average tenant identification time
avg(rate(gabay_tenant_identification_duration_seconds_sum[5m])) / 
avg(rate(gabay_tenant_identification_duration_seconds_count[5m]))

# P95 tenant identification time (cached vs uncached)
histogram_quantile(0.95, sum(rate(gabay_tenant_identification_duration_seconds_bucket{cache_hit="true"}[5m])) by (le))
histogram_quantile(0.95, sum(rate(gabay_tenant_identification_duration_seconds_bucket{cache_hit="false"}[5m])) by (le))

# JWT decode operations
sum(rate(gabay_jwt_decode_operations_total[5m]))

# Cache efficiency (operations avoided)
sum(rate(gabay_tenant_cache_hits_total[5m]))
```

### Tenant Analytics

```promql
# Top 10 tenants by request volume
topk(10, sum by (tenant) (rate(gabay_http_requests_total[5m])))

# Active tenants count
count(count by (tenant) (gabay_http_requests_total))

# Requests distribution by tenant
sum by (tenant) (increase(gabay_http_requests_total[1h]))

# Slowest tenants (P95 response time)
topk(10, histogram_quantile(0.95, sum by (tenant, le) (rate(gabay_http_request_duration_seconds_bucket[5m]))))
```

---

## 🎯 Common Use Cases

### Before/After Optimization Comparison

```promql
# Tenant ID overhead reduction
# Before: ~50ms average, After: ~1ms average
avg(rate(gabay_tenant_identification_duration_seconds_sum[5m])) / 
avg(rate(gabay_tenant_identification_duration_seconds_count[5m])) * 1000

# JWT decodes per request
# Before: 3-5, After: ~1
sum(rate(gabay_jwt_decode_operations_total[5m])) / sum(rate(gabay_http_requests_total[5m]))

# Cache hit rate improvement
# Before: 0%, After: 95%+
sum(rate(gabay_tenant_cache_hits_total[5m])) / 
(sum(rate(gabay_tenant_cache_hits_total[5m])) + sum(rate(gabay_tenant_cache_misses_total[5m]))) * 100
```

### Capacity Planning

```promql
# Request rate trend (predict scaling needs)
predict_linear(sum(rate(gabay_http_requests_total[1h]))[1w:], 86400 * 7)

# Memory usage per tenant (if tracked)
sum by (tenant) (process_resident_memory_bytes)

# Connection pool utilization
avg(gabay_db_connection_pool_active)
```

### Alerting Thresholds

```promql
# High error rate (> 5%)
sum(rate(gabay_http_request_errors_total[5m])) / sum(rate(gabay_http_requests_total[5m])) > 0.05

# Slow response time (P95 > 500ms)
histogram_quantile(0.95, sum(rate(gabay_http_request_duration_seconds_bucket[5m])) by (le)) > 0.5

# Low cache hit rate (< 80%)
sum(rate(gabay_redis_cache_hits_total[5m])) / 
(sum(rate(gabay_redis_cache_hits_total[5m])) + sum(rate(gabay_redis_cache_misses_total[5m]))) < 0.8
```

---

## 🔧 Useful Grafana Features

### Variables

Add to dashboard settings:
```
Name: tenant
Label: Tenant
Query: label_values(gabay_http_requests_total, tenant)
```

Use in queries:
```promql
sum by (method) (rate(gabay_http_requests_total{tenant="$tenant"}[5m]))
```

### Annotations

Mark deployments:
```json
{
  "datasource": "Prometheus",
  "enable": true,
  "expr": "changes(process_start_time_seconds[1m]) > 0",
  "tagKeys": "deployment",
  "textFormat": "Deployment",
  "titleFormat": "API Restarted"
}
```

---

## 📈 Metric Types Reference

### Counters (always increasing)
- `gabay_http_requests_total` - Total HTTP requests
- `gabay_tenant_cache_hits_total` - Total cache hits
- `gabay_jwt_decode_operations_total` - Total JWT decodes

### Histograms (for percentiles)
- `gabay_http_request_duration_seconds` - Request duration
- `gabay_tenant_identification_duration_seconds` - Tenant ID time
- `gabay_redis_operation_duration_seconds` - Redis operation time

### Gauges (current value)
- `gabay_db_connection_pool_active` - Active connections
- `gabay_redis_connection_pool_active` - Active Redis connections

---

## 🎨 Dashboard Shortcuts

| Action | Shortcut |
|--------|----------|
| **Time range picker** | `Ctrl + T` |
| **Refresh dashboard** | `Ctrl + R` |
| **Zoom out** | `Ctrl + Z` |
| **Share panel** | `Ctrl + S` |
| **Save dashboard** | `Ctrl + S` (while in edit mode) |
| **Add panel** | `Ctrl + A` |
| **Duplicate panel** | `Ctrl + D` (while hovering) |

---

## 🔍 Debugging Tips

### No Metrics Showing?

1. Check if Prometheus is scraping:
   ```bash
   curl http://localhost:9090/api/v1/targets
   ```

2. Check if metrics endpoint works:
   ```bash
   curl http://localhost:3001/api/metrics
   ```

3. Verify data exists:
   ```promql
   gabay_http_requests_total
   ```

### Metrics Look Wrong?

1. Check scrape interval alignment
2. Verify rate() time window (should be >= 4x scrape interval)
3. Check for resets (use `increase()` instead of `rate()`)

### Dashboard Performance Issues?

1. Reduce time range
2. Increase scrape interval
3. Use recording rules for complex queries
4. Limit number of series returned

---

## 📝 Quick Notes

**Best Practices:**
- Use `rate()` for counters
- Use `histogram_quantile()` for percentiles
- Always specify time ranges: `[5m]`, `[1h]`, etc.
- Label wisely - avoid high cardinality

**Common Mistakes:**
- ❌ Using `increase()` with short time windows
- ❌ Missing `by (label)` in aggregations
- ❌ Forgetting `sum()` before `rate()`
- ❌ Using too many labels (>10)

---

## 🎯 Success Metrics

**Your optimization is working if you see:**

✅ Tenant cache hit rate > 90%  
✅ P95 tenant identification < 2ms  
✅ JWT decodes/request ≈ 1  
✅ Bootstrap cache hit rate > 95%  
✅ Redis cache hit rate > 85%

**Before optimization:**
- Tenant ID: ~50ms avg
- Cache hit rate: 0%
- JWT decodes/request: 3-5

**After optimization:**
- Tenant ID: ~1ms avg ⚡ **(50x faster!)**
- Cache hit rate: 95%+ 💾
- JWT decodes/request: 1 🎯

---

**Happy Monitoring!** 📊✨
