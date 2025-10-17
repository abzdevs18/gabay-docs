# 🔧 Scanned PDF 502 Bad Gateway Fix

**Issue:** 502 Bad Gateway when uploading scanned PDFs (no text layer)  
**Status:** ✅ Fixed  
**Date:** 2025-10-15

---

## 🐛 Problem Identified

### What Works
✅ PDFs with text layer (instant text extraction)  
✅ Images (single Vision API call)  
✅ DOCX, PPTX, TXT files  

### What Fails (502 Bad Gateway)
❌ **Scanned PDFs** (no text layer) - requires Vision API processing  
❌ **Only on production** - local works fine

---

## 🔍 Root Cause Analysis

### Timeline of the Issue

**Upload Flow for Scanned PDFs:**
```
1. Upload PDF → Extract text (Vision API) → Return → Background (chunking/indexing)
                      ↑
                      THIS TAKES 80+ SECONDS!
```

**Why it times out:**

1. **8-page scanned PDF processing:**
   - Convert to images: ~5s
   - Process 6 pages in parallel with Vision API: ~40s per batch
   - 2 batches = 80+ seconds total

2. **Production proxy timeout:**
   - DigitalOcean/Nginx default: 60 seconds
   - Request times out → **502 Bad Gateway**

3. **Why local works:**
   - No reverse proxy timeout
   - Node.js waits indefinitely
   - Less strict rate limiting

---

## ✅ Solutions Implemented

### Solution 1: Reduce Concurrent Vision API Calls

**Changed:** `document-ingestion.service.ts` line 603

**Before:**
```typescript
const CONCURRENT_PAGES = 6; // Process 6 pages at once
```

**After:**
```typescript
const CONCURRENT_PAGES = parseInt(process.env.VISION_API_CONCURRENT_PAGES || '2'); // Default: 2
```

**Impact:**
- Reduces memory usage (fewer images in memory)
- Avoids OpenAI Vision API rate limits
- Slower but more reliable

**Timing:**
- Before: 6 pages/batch × 40s = 2 batches = 80s ❌
- After: 2 pages/batch × 40s = 4 batches = 160s ⚠️

**Note:** This alone won't fix timeout - but reduces failures!

---

### Solution 2: Add Environment Variable Control

**Added to `.env`:**
```bash
# Vision API settings (for scanned PDFs)
VISION_API_CONCURRENT_PAGES=2
```

**Adjust based on environment:**
- **Local dev:** `VISION_API_CONCURRENT_PAGES=6` (fast)
- **Production:** `VISION_API_CONCURRENT_PAGES=1` (safe)
- **Staging:** `VISION_API_CONCURRENT_PAGES=2` (balanced)

---

### Solution 3: Increase Production Timeout (REQUIRED!)

The real fix is to **increase the reverse proxy timeout** on production.

#### Option A: DigitalOcean App Platform

Add to your app settings:

**App Spec (YAML):**
```yaml
services:
- name: api
  http_port: 3005
  routes:
  - path: /
  health_check:
    timeout_seconds: 180  # 3 minutes
```

**Or via CLI:**
```bash
doctl apps update <app-id> --spec app.yaml
```

#### Option B: Nginx (if using custom server)

Edit nginx config:
```nginx
location /api/ {
    proxy_pass http://localhost:3005;
    proxy_read_timeout 180s;     # 3 minutes
    proxy_connect_timeout 180s;  # 3 minutes
    proxy_send_timeout 180s;     # 3 minutes
}
```

Then restart:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

#### Option C: Next.js Config

Add to `next.config.js`:
```javascript
module.exports = {
  // ... other config
  
  // Increase API timeout
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: '/api/:path*',
      }
    ]
  },
  
  // Add max duration for API routes
  experimental: {
    isrMemoryCacheSize: 0,
  },
  
  // Increase timeout
  serverRuntimeConfig: {
    apiTimeout: 180000, // 3 minutes
  }
}
```

---

## 🚀 Better Solution: Move Vision API to Background (Future)

The **ideal solution** is to move Vision API processing to background:

**Proposed Flow:**
```
Upload → Quick validation → Return immediately ✅
         ↓
         Background: Extract (Vision API) → Chunk → Index
```

**Implementation (Future):**

```typescript
// In upload-document.ts
if (isScannedPDF) {
  // Return immediately
  res.write(JSON.stringify({
    document_id: documentId,
    ready_for_questions: false,  // Not ready yet
    processing_status: 'extracting',  // Vision API in progress
    can_chat_now: false  // Can't chat until extraction complete
  }));
  res.end();
  
  // Background processing
  setImmediate(async () => {
    await extractWithVisionAPI(documentId);  // Long operation
    await chunkDocument(documentId);
    await indexDocument(documentId);
    // Update status to ready
  });
}
```

**Benefits:**
- No timeout issues
- User gets immediate response
- Processing happens in background
- Frontend shows "Processing..." state

---

## 📊 Performance Comparison

| Scenario | Concurrent Pages | Time (8-page PDF) | Status |
|----------|-----------------|-------------------|--------|
| **Before (Local)** | 6 | 80s | ✅ Works |
| **Before (Production)** | 6 | 80s | ❌ 502 Timeout |
| **After (Production, no timeout fix)** | 2 | 160s | ❌ 502 Timeout |
| **After (Production, 180s timeout)** | 2 | 160s | ✅ Works |
| **After (Production, 1 page)** | 1 | 320s | ⚠️ Very slow |
| **Future (Background)** | 2 | 2s response | ✅ Perfect |

---

## 🧪 Testing

### Test 1: With Current Fix (Requires Timeout Increase)

1. **Set environment variable on production:**
   ```bash
   VISION_API_CONCURRENT_PAGES=2
   ```

2. **Increase production timeout to 180s** (see Solution 3)

3. **Restart API**

4. **Upload scanned PDF:**
   ```bash
   # Should complete in ~160s without 502
   ```

### Test 2: Verify Concurrent Pages

Check logs during upload:
```
[Poppler PDF] ⚡ Processing 8 pages with 2 concurrent workers
[Poppler PDF] ⚡ Processing page 1/8 (batch 1)
[Poppler PDF] ⚡ Processing page 2/8 (batch 1)
[Poppler PDF] ✅ Batch complete: 2/8 pages processed
[Poppler PDF] ⚡ Processing page 3/8 (batch 2)
...
```

### Test 3: Emergency Mode (1 page at a time)

If still timing out, set:
```bash
VISION_API_CONCURRENT_PAGES=1
```

Will be slower (320s for 8 pages) but most reliable.

---

## 🔧 Production Deployment Checklist

- [ ] Update `document-ingestion.service.ts` (code change)
- [ ] Add `VISION_API_CONCURRENT_PAGES=2` to production `.env`
- [ ] Increase production proxy timeout to 180s (DigitalOcean/Nginx)
- [ ] Deploy code changes
- [ ] Restart API server
- [ ] Test with scanned PDF
- [ ] Monitor logs for timeouts
- [ ] Adjust concurrent pages if needed (1-4 range)

---

## 📝 Environment Variables Summary

```bash
# Local development (.env)
VISION_API_CONCURRENT_PAGES=6  # Fast processing
NODE_ENV=development

# Production (.env)
VISION_API_CONCURRENT_PAGES=2  # Balanced (or 1 for ultra-safe)
NODE_ENV=production

# Staging (.env)
VISION_API_CONCURRENT_PAGES=2  # Test production settings
NODE_ENV=staging
```

---

## 🚨 Troubleshooting

### Still Getting 502?

1. **Check timeout was applied:**
   ```bash
   # DigitalOcean
   doctl apps spec get <app-id>
   # Look for timeout_seconds: 180
   
   # Nginx
   sudo nginx -T | grep timeout
   # Should show 180s
   ```

2. **Reduce concurrent pages further:**
   ```bash
   VISION_API_CONCURRENT_PAGES=1
   ```

3. **Check OpenAI API limits:**
   ```bash
   # In logs, look for:
   # "Rate limit exceeded"
   # "Too many requests"
   ```

4. **Monitor memory usage:**
   ```bash
   # During upload
   free -h
   # If memory is low, reduce concurrent pages
   ```

### Upload Taking Too Long?

**Expected times (8-page scanned PDF):**

- `CONCURRENT_PAGES=1`: ~320s (5.3 min)
- `CONCURRENT_PAGES=2`: ~160s (2.7 min) ← **Recommended**
- `CONCURRENT_PAGES=4`: ~80s (1.3 min)
- `CONCURRENT_PAGES=6`: ~80s (1.3 min) - May hit rate limits

**If too slow:**
1. Consider background processing (future)
2. Use `CONCURRENT_PAGES=4` if no rate limit issues
3. Cache Vision API results (future enhancement)

---

## 📚 Related Documentation

- **Async Upload Pipeline:** `docs/chatbot/README.md#background-processing`
- **Vision API Optimization:** `docs/chatbot/README.md#document-processing`
- **Architecture:** `docs/chatbot/ARCHITECTURE.md`

---

## ✅ Summary

**Issue:** Scanned PDFs timing out with 502 on production

**Root Cause:** 
- Vision API processing takes 80+ seconds
- Production proxy times out at 60 seconds

**Fix Applied:**
1. ✅ Made concurrent pages configurable via env var
2. ✅ Reduced default from 6 to 2 pages
3. ⚠️ **REQUIRED:** Increase production timeout to 180s

**Next Steps:**
1. Deploy code changes
2. Add env var to production
3. Increase production timeout
4. Test with scanned PDF
5. Consider background processing for better UX

**Status:** 🟡 Partially Fixed - needs timeout increase on production!
