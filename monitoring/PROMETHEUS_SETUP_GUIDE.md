# Prometheus + Grafana Monitoring Setup Guide

## 🎯 Overview

This guide will help you set up complete monitoring for the Gabay multi-tenant system using Prometheus and Grafana.

**What you'll get:**
- Real-time performance metrics
- Multi-tenant usage analytics
- Cache performance monitoring
- API response time tracking
- Database query analytics
- Beautiful Grafana dashboards

---

## 📋 Prerequisites

- Docker and Docker Compose installed
- Node.js and npm installed
- Gabay API running on port 3001

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Dependencies

```bash
cd api
npm install prom-client
```

### Step 2: Start Monitoring Stack

```bash
# From the root directory
docker-compose -f docker-compose.monitoring.yml up -d
```

### Step 3: Access Dashboards

- **Grafana**: http://localhost:3002
  - Username: `admin`
  - Password: `admin123` (change this in production!)

- **Prometheus**: http://localhost:9090

### Step 4: Verify Metrics

1. Open your browser to: http://localhost:3001/api/metrics
2. You should see Prometheus-formatted metrics

---

## 📊 Available Dashboards

### 1. Multi-Tenant Overview
**URL:** http://localhost:3002/d/gabay-multi-tenant

**Shows:**
- Total requests per second
- P95 response times
- Cache hit rates
- Active tenants
- Request volume per tenant
- Response time per tenant
- Top 10 tenants by usage

### 2. Cache Performance
**URL:** http://localhost:3002/d/gabay-cache-performance

**Shows:**
- Redis cache hit rate
- Tenant cache hit rate
- Bootstrap cache hit rate
- Cache operations over time
- Cache latency metrics
- Cache effectiveness comparison

---

## 🔧 Configuration

### Change Grafana Password

Edit `docker-compose.monitoring.yml`:

```yaml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=your_secure_password_here
```

### Adjust Scrape Interval

Edit `monitoring/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s  # Change to your desired interval
```

### Add More Metrics Endpoints

Edit `monitoring/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'your-service'
    static_configs:
      - targets: ['host.docker.internal:PORT']
    metrics_path: '/metrics'
```

---

## 📈 Key Metrics

### HTTP Request Metrics
```promql
# Total requests per second
sum(rate(gabay_http_requests_total[5m]))

# P95 response time
histogram_quantile(0.95, sum(rate(gabay_http_request_duration_seconds_bucket[5m])) by (le))

# Requests by tenant
sum by (tenant) (rate(gabay_http_requests_total[5m]))
```

### Cache Metrics
```promql
# Cache hit rate
sum(rate(gabay_redis_cache_hits_total[5m])) / 
(sum(rate(gabay_redis_cache_hits_total[5m])) + sum(rate(gabay_redis_cache_misses_total[5m]))) * 100

# Tenant cache hit rate
sum by (tenant) (rate(gabay_tenant_cache_hits_total[5m])) / 
(sum by (tenant) (rate(gabay_tenant_cache_hits_total[5m])) + sum by (tenant) (rate(gabay_tenant_cache_misses_total[5m]))) * 100
```

### Tenant Identification Metrics
```promql
# Tenant identification time (p95)
histogram_quantile(0.95, sum(rate(gabay_tenant_identification_duration_seconds_bucket[5m])) by (le))

# JWT decode operations
sum(rate(gabay_jwt_decode_operations_total[5m]))
```

---

## 🐛 Troubleshooting

### Metrics endpoint returns 404

**Check:**
1. API is running: `http://localhost:3001`
2. Metrics endpoint exists: `http://localhost:3001/api/metrics`
3. `prom-client` is installed: `npm list prom-client`

### Prometheus shows "Connection Refused"

**Fix:**
```bash
# Check if API is accessible from Docker
curl http://host.docker.internal:3001/api/metrics

# If not, ensure host.docker.internal works
# On Linux, add to docker-compose.monitoring.yml:
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### Grafana shows "No Data"

**Check:**
1. Prometheus is scraping successfully:
   - Open http://localhost:9090/targets
   - Check if `gabay-api` shows as "UP"

2. Verify metrics are being generated:
   - Make some API requests
   - Check http://localhost:3001/api/metrics for data

### Dashboards are empty

**Solutions:**
```bash
# Restart Grafana
docker-compose -f docker-compose.monitoring.yml restart grafana

# Re-import dashboards manually:
# 1. Go to Grafana UI
# 2. Click "+" > "Import"
# 3. Upload JSON files from monitoring/grafana/dashboards/
```

---

## 🔒 Security Considerations

### Production Deployment

1. **Restrict Metrics Endpoint**

```typescript
// api/src/pages/api/metrics.ts
export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow from internal networks
  const allowedIPs = ['127.0.0.1', '::1', '10.0.0.0/8'];
  const clientIP = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  
  if (!isIPAllowed(clientIP, allowedIPs)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  // ... rest of the code
}
```

2. **Enable Authentication**

Add to `monitoring/prometheus.yml`:
```yaml
basic_auth:
  username: 'prometheus'
  password: 'secure_password'
```

3. **Use HTTPS**

Configure reverse proxy (nginx/traefik) with SSL certificates.

---

## 📊 Custom Metrics

### Adding New Metrics

1. **Define the metric** in `prometheus-metrics.service.ts`:

```typescript
public myCustomMetric: Counter<string>;

this.myCustomMetric = new Counter({
  name: 'gabay_my_custom_metric_total',
  help: 'Description of my custom metric',
  labelNames: ['tenant', 'type'],
  registers: [this.registry]
});
```

2. **Track the metric** in your code:

```typescript
import { prometheusMetrics } from '@/services/prometheus-metrics.service';

// Increment counter
prometheusMetrics.myCustomMetric.inc({ tenant: 'aans', type: 'example' });

// Observe histogram
prometheusMetrics.someHistogram.observe({ tenant: 'aans' }, durationInSeconds);

// Set gauge
prometheusMetrics.someGauge.set({ tenant: 'aans' }, currentValue);
```

3. **Query in Prometheus**:

```promql
sum(rate(gabay_my_custom_metric_total[5m])) by (tenant)
```

---

## 📦 Data Retention

### Configure Prometheus Retention

Edit `docker-compose.monitoring.yml`:

```yaml
command:
  - '--storage.tsdb.retention.time=30d'  # Keep data for 30 days
  - '--storage.tsdb.retention.size=10GB' # Or limit by size
```

### Backup Grafana Dashboards

```bash
# Export dashboards
docker exec gabay-grafana grafana-cli admin export-dashboard

# Backup Grafana data
docker run --rm --volumes-from gabay-grafana \
  -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz /var/lib/grafana
```

---

## 🎯 Performance Impact

### Metrics Collection Overhead

- **CPU:** < 1% additional overhead
- **Memory:** ~50-100MB for Prometheus metrics service
- **Network:** Minimal (metrics scraped every 15s)
- **API Latency:** < 0.1ms per request

### Optimization Tips

1. **Reduce cardinality:**
   - Don't use high-cardinality labels (user IDs, UUIDs)
   - Use tenant tags, not individual user tags

2. **Adjust scrape interval:**
   - Production: 15-30 seconds
   - Development: 10 seconds
   - Critical services: 5 seconds

3. **Use recording rules:**

```yaml
# monitoring/prometheus.yml
rule_files:
  - 'rules/*.yml'

# monitoring/rules/aggregations.yml
groups:
  - name: gabay_aggregations
    interval: 30s
    rules:
      - record: tenant:requests:rate5m
        expr: sum by (tenant) (rate(gabay_http_requests_total[5m]))
```

---

## 🔄 Updating

### Update Metrics Service

```bash
cd api
npm update prom-client
```

### Update Prometheus/Grafana

```bash
docker-compose -f docker-compose.monitoring.yml pull
docker-compose -f docker-compose.monitoring.yml up -d
```

---

## 📚 Further Reading

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [PromQL Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

---

## 🆘 Support

**Issues?**
- Check the troubleshooting section above
- Review Prometheus targets: http://localhost:9090/targets
- Check container logs: `docker-compose -f docker-compose.monitoring.yml logs`

**Questions?**
- Review the configuration files in `monitoring/`
- Check example queries in Grafana dashboards
- Consult the team documentation

---

## ✅ Next Steps

1. ✅ Install prom-client package
2. ✅ Start Docker containers
3. ✅ Access Grafana dashboards
4. ✅ Make some API requests to generate metrics
5. ✅ Explore the dashboards
6. 📊 Create custom dashboards for your use cases
7. 🔔 Set up alerts (see Alerting Guide)
8. 📈 Monitor and optimize based on metrics

---

**Congratulations! Your monitoring system is now live!** 🎉

You can now see real-time metrics proving the effectiveness of your tenant identification optimizations!
