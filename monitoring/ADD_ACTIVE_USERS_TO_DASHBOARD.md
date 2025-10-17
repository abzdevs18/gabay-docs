# Adding Active Users to Grafana Dashboard

## 🎯 Quick Guide

Since the dashboard is already created, let's add active user panels manually in Grafana UI.

---

## 📊 Panel 1: Total Active Users (Stat)

1. **Open your Multi-Tenant Overview dashboard**
2. **Click "Add panel" → "Add new panel"**
3. **Configure:**

**Query:**
```promql
sum(gabay_active_users_5m)
```

**Panel Settings:**
- **Title:** Active Users (Last 5 min)
- **Type:** Stat
- **Color:** Value
- **Graph mode:** Area
- **Unit:** Users

4. **Click "Apply"**

---

## 📊 Panel 2: Active Users Per Tenant (Time Series)

1. **Add another panel**
2. **Configure:**

**Query:**
```promql
sum by (tenant) (gabay_active_users_15m)
```

**Panel Settings:**
- **Title:** Active Users by Tenant (15 min)
- **Type:** Time series
- **Legend:** {{tenant}}
- **Y-axis label:** Active Users

3. **Click "Apply"**

---

## 📊 Panel 3: Active Users Gauge (5m, 15m, 1h)

1. **Add another panel**
2. **Configure THREE queries:**

**Query A:**
```promql
sum(gabay_active_users_5m)
```

**Query B:**
```promql
sum(gabay_active_users_15m)
```

**Query C:**
```promql
sum(gabay_active_users_1h)
```

**Panel Settings:**
- **Title:** Active Users (All Time Windows)
- **Type:** Stat
- **Display:** Rows
- **Legends:** 
  - A: Last 5 min
  - B: Last 15 min
  - C: Last 1 hour

3. **Click "Apply"**

---

## 📊 Panel 4: Top Tenants by Active Users (Table)

1. **Add another panel**
2. **Configure:**

**Query:**
```promql
topk(10, gabay_active_users_5m)
```

**Panel Settings:**
- **Title:** Top 10 Tenants by Active Users
- **Type:** Table
- **Transform:** Organize fields
  - Rename "tenant" → "Tenant"
  - Rename "Value" → "Active Users (5m)"

3. **Click "Apply"**

---

## 📊 Panel 5: Activity Heatmap

1. **Add another panel**
2. **Configure:**

**Query:**
```promql
sum by (tenant) (gabay_active_users_5m)
```

**Panel Settings:**
- **Title:** Tenant Activity Heatmap
- **Type:** Heatmap
- **Legend:** Show
- **Color scheme:** Green-Yellow-Red

3. **Click "Apply"**

---

## 🎨 Recommended Dashboard Layout

```
Row 1 (Stats):
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  Total      │   P95       │   Cache     │   Active    │
│  Requests   │  Response   │   Hit Rate  │   Tenants   │
│  125 req/s  │   85ms      │   94%       │      5      │
└─────────────┴─────────────┴─────────────┴─────────────┘

Row 2 (Active Users):
┌─────────────────────────────────────────────────────────┐
│  Active Users (5m, 15m, 1h)                             │
│  42 │ 67 │ 125                                          │
└─────────────────────────────────────────────────────────┘

Row 3 (Graphs):
┌──────────────────────────┬──────────────────────────────┐
│  Requests Per Tenant     │  Active Users by Tenant      │
│  (line graph)            │  (line graph)                │
└──────────────────────────┴──────────────────────────────┘

Row 4 (More Graphs):
┌──────────────────────────┬──────────────────────────────┐
│  Response Time/Tenant    │  Top 10 Tenants (table)      │
│  (line graph)            │  by Active Users             │
└──────────────────────────┴──────────────────────────────┘
```

---

## ⚡ Quick Copy-Paste Queries

### For Stat Panels

```promql
# Total active users (5 min)
sum(gabay_active_users_5m)

# Total active users (15 min)
sum(gabay_active_users_15m)

# Total active users (1 hour)
sum(gabay_active_users_1h)

# Active tenants count
count(gabay_active_users_5m > 0)
```

### For Time Series

```promql
# Active users per tenant
sum by (tenant) (gabay_active_users_15m)

# Compare 5m vs 15m vs 1h
sum(gabay_active_users_5m)
sum(gabay_active_users_15m)
sum(gabay_active_users_1h)
```

### For Tables

```promql
# Top 10 by current activity
topk(10, gabay_active_users_5m)

# Top 10 by 1-hour activity
topk(10, gabay_active_users_1h)

# All tenants with activity
gabay_active_users_5m > 0
```

### For Alerts

```promql
# Alert if no users active (system issue)
sum(gabay_active_users_5m) < 1

# Alert if specific tenant has zero activity
gabay_active_users_15m{tenant="aans"} < 1

# Alert on unusual spike (>1000 users suddenly)
sum(gabay_active_users_5m) > 1000
```

---

## 🔍 Testing Your Panels

After adding the panels:

1. **Login to your Gabay app**
2. **Navigate around** (trigger some requests)
3. **Wait 30 seconds** (for gauge update)
4. **Refresh Grafana** - you should see yourself counted!

---

## 💡 Pro Tips

### Variable for Tenant Selection

Add a dashboard variable:

**Name:** `tenant`  
**Type:** Query  
**Query:**
```promql
label_values(gabay_active_users_5m, tenant)
```

Then use `$tenant` in queries:
```promql
gabay_active_users_5m{tenant="$tenant"}
```

### Auto-Refresh

Set dashboard auto-refresh:
- Click ⚙️ (Settings) → Time options
- Set "Refresh" to `30s` or `1m`

### Panel Links

Link panels to drill down:
- Add data link to tenant panels
- Link to detailed tenant dashboard
- Pass tenant variable: `/d/tenant-detail?var-tenant=$__field_labels.tenant`

---

## ✅ Verification

Your panels are working if you see:

- ✅ Numbers > 0 after making requests
- ✅ Values update every ~30 seconds
- ✅ Different values for 5m / 15m / 1h windows
- ✅ Your tenant appears in the table
- ✅ Graphs show activity over time

---

**Enjoy your new active user tracking!** 👥📊✨
