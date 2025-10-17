# Endpoint Performance Tracking

## 🎯 Overview

Track **response time per endpoint** to identify slow APIs and optimize performance.

---

## 📊 What Gets Tracked

Every HTTP request is automatically tracked with:

| Label | Description | Example |
|-------|-------------|---------|
| **method** | HTTP method | `GET`, `POST`, `PUT`, `DELETE` |
| **route** | Normalized endpoint | `/api/v1/gabay-forms/:id` |
| **status_code** | Response status | `200`, `404`, `500` |
| **tenant** | Which tenant | `aans`, `public` |

### **Metrics Available:**

1. **`gabay_http_request_duration_seconds`** - Response time histogram
2. **`gabay_http_requests_total`** - Total request count
3. **`gabay_http_request_errors_total`** - Error count (4xx, 5xx)

---

## 🔍 How to Find Slow Endpoints

### **1. In Prometheus** (`http://localhost:9090`)

#### **Slowest Endpoints (P95 latency):**

```promql
# Top 10 slowest endpoints (95th percentile)
topk(10, 
  histogram_quantile(0.95, 
    sum by (route, method, le) (
      rate(gabay_http_request_duration_seconds_bucket[5m])
    )
  )
)
```

#### **Average Response Time per Endpoint:**

```promql
# Average response time by endpoint
sum by (route, method) (
  rate(gabay_http_request_duration_seconds_sum[5m])
) 
/ 
sum by (route, method) (
  rate(gabay_http_request_duration_seconds_count[5m])
)
```

#### **Endpoints Taking > 1 Second:**

```promql
# Endpoints with P95 > 1s
histogram_quantile(0.95, 
  sum by (route, method, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
) > 1
```

#### **Most Called Endpoints:**

```promql
# Top 10 by request count
topk(10, 
  sum by (route, method) (
    rate(gabay_http_requests_total[5m])
  )
)
```

#### **Endpoints with Most Errors:**

```promql
# Endpoints with highest error rate
topk(10,
  sum by (route, method) (
    rate(gabay_http_request_errors_total[5m])
  )
)
```

---

## 📈 Grafana Queries

### **Panel 1: Slowest Endpoints Table**

**Query:**
```promql
sort_desc(
  histogram_quantile(0.95, 
    sum by (route, method, le) (
      rate(gabay_http_request_duration_seconds_bucket[5m])
    )
  )
)
```

**Panel Type:** Table  
**Format:** Time series  
**Columns:** Route, Method, P95 Latency (seconds)

---

### **Panel 2: Response Time by Endpoint (Line Graph)**

**Query:**
```promql
# P50, P95, P99 for each endpoint
histogram_quantile(0.50, 
  sum by (route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
)

histogram_quantile(0.95, 
  sum by (route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
)

histogram_quantile(0.99, 
  sum by (route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
)
```

**Panel Type:** Time series (Line graph)  
**Legend:** `{{route}} (P50/P95/P99)`

---

### **Panel 3: Requests Per Second by Endpoint**

**Query:**
```promql
sum by (route, method) (
  rate(gabay_http_requests_total[5m])
)
```

**Panel Type:** Bar gauge  
**Legend:** `{{method}} {{route}}`

---

### **Panel 4: Error Rate by Endpoint**

**Query:**
```promql
# Error rate percentage
(
  sum by (route) (
    rate(gabay_http_request_errors_total[5m])
  )
  /
  sum by (route) (
    rate(gabay_http_requests_total[5m])
  )
) * 100
```

**Panel Type:** Time series  
**Legend:** `{{route}}`  
**Unit:** Percent (0-100)

---

### **Panel 5: Heatmap of Response Times**

**Query:**
```promql
sum by (le) (
  rate(gabay_http_request_duration_seconds_bucket[5m])
)
```

**Panel Type:** Heatmap  
**Shows:** Distribution of response times over time

---

## 🚨 Alerting Rules

### **Slow Endpoint Alert**

```yaml
# alerts/endpoint-performance.yml
groups:
  - name: endpoint_performance
    interval: 30s
    rules:
      - alert: SlowEndpoint
        expr: |
          histogram_quantile(0.95, 
            sum by (route, method, le) (
              rate(gabay_http_request_duration_seconds_bucket[5m])
            )
          ) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Slow endpoint detected"
          description: "{{ $labels.method }} {{ $labels.route }} is taking {{ $value }}s (P95)"

      - alert: HighErrorRate
        expr: |
          (
            sum by (route) (rate(gabay_http_request_errors_total[5m]))
            /
            sum by (route) (rate(gabay_http_requests_total[5m]))
          ) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on endpoint"
          description: "{{ $labels.route }} has {{ $value | humanizePercentage }} error rate"
```

---

## 📋 Common Use Cases

### **1. Find Which Endpoint is Slowing Down Your API**

```promql
# Show all endpoints slower than 500ms (P95)
histogram_quantile(0.95, 
  sum by (route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
) > 0.5
```

### **2. Compare Response Times Before/After Optimization**

```promql
# Response time change over time
histogram_quantile(0.95, 
  sum by (route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
) offset 1h
```

### **3. See Response Time per Tenant**

```promql
# P95 latency by tenant
histogram_quantile(0.95, 
  sum by (tenant, route, le) (
    rate(gabay_http_request_duration_seconds_bucket[5m])
  )
)
```

### **4. Identify Endpoints with High Traffic**

```promql
# Requests/sec by endpoint
topk(10, 
  sum by (route) (
    rate(gabay_http_requests_total[5m])
  )
)
```

### **5. Track Specific Endpoint Performance**

```promql
# Response time for specific endpoint
histogram_quantile(0.95, 
  sum by (le) (
    rate(gabay_http_request_duration_seconds_bucket{
      route="/api/v1/gabay-forms/:id"
    }[5m])
  )
)
```

---

## 🎨 Route Normalization

Routes are automatically normalized to group similar requests:

| Original Request | Normalized Route |
|------------------|------------------|
| `/api/v1/gabay-forms/123` | `/api/v1/gabay-forms/:id` |
| `/api/v1/gabay-forms/abc-123-def` | `/api/v1/gabay-forms/:id` |
| `/api/v1/users/456` | `/api/v1/users/:id` |
| `/api/v1/forms?page=2` | `/api/v1/forms` (query removed) |

**Why?** This groups similar requests together instead of tracking each ID separately.

---

## 📊 Example Dashboard Layout

```
┌──────────────────────────────────────────────┐
│  Slowest Endpoints (P95)                     │
│  ┌──────────────────────────────────────┐   │
│  │ Route                         │ Time │   │
│  │ /api/v1/gabay-forms/:id      │ 2.3s │   │
│  │ /api/v1/documents/upload     │ 1.8s │   │
│  │ /api/v2/ai/chat              │ 1.2s │   │
│  └──────────────────────────────────────┘   │
├──────────────────────────────────────────────┤
│  Response Time Trends                        │
│  [Line graph showing P50/P95/P99 over time]  │
├──────────────────────────────────────────────┤
│  Requests/Second by Endpoint                 │
│  [Bar chart of top endpoints by traffic]     │
├──────────────────────────────────────────────┤
│  Error Rate by Endpoint                      │
│  [Line graph of error % per endpoint]        │
└──────────────────────────────────────────────┘
```

---

## 🧪 Testing

### **Generate Test Traffic:**

```bash
# Make some requests
curl http://localhost:3001/api/metrics
curl http://localhost:3001/api/v1/gabay-forms/public/test-form
curl http://localhost:3001/api/v2/tenant/bootstrap

# Wait 10-15 seconds for metrics to be scraped

# Check in Prometheus:
http://localhost:9090/graph

# Enter query:
gabay_http_request_duration_seconds_count

# You should see your requests!
```

---

## 📈 Percentile Explanations

| Percentile | Meaning | Use Case |
|------------|---------|----------|
| **P50 (Median)** | 50% of requests are faster | Typical performance |
| **P95** | 95% of requests are faster | User experience |
| **P99** | 99% of requests are faster | Outliers/worst case |
| **P99.9** | 99.9% faster | Finding extreme cases |

**Focus on P95** - It represents what most users experience while filtering out rare outliers.

---

## 🎯 Performance Targets

### **Recommended Targets:**

| Endpoint Type | P50 | P95 | P99 |
|---------------|-----|-----|-----|
| **Simple GET** | < 50ms | < 100ms | < 200ms |
| **Database query** | < 100ms | < 250ms | < 500ms |
| **Complex query** | < 250ms | < 500ms | < 1s |
| **File upload** | < 1s | < 3s | < 5s |
| **AI generation** | < 5s | < 10s | < 15s |

---

## ✅ What You Get

With this tracking, you can:

✅ **Identify slow endpoints** - Find bottlenecks immediately  
✅ **Monitor performance over time** - See trends and regressions  
✅ **Track by tenant** - See if one tenant is slower  
✅ **Measure optimizations** - Verify improvements work  
✅ **Set up alerts** - Get notified of slowdowns  
✅ **Debug production issues** - Real data, not guesses  

---

## 🚀 Quick Start Checklist

- [ ] Restart your API (metrics tracking is now active)
- [ ] Restart monitoring stack: `docker-compose -f docker-compose.monitoring.yml restart`
- [ ] Make some test requests to your API
- [ ] Open Prometheus: http://localhost:9090
- [ ] Try query: `gabay_http_request_duration_seconds_count`
- [ ] See your endpoints tracked!
- [ ] Add panels to Grafana dashboard
- [ ] Set up alerts for slow endpoints

---

**Your API performance is now fully tracked!** 🎉📊
