# Poppler Utils Setup & Testing Guide

## Overview

This guide helps you set up and test the new `pdftoppm`-based PDF processing for scanned PDFs without text layers. This approach replaced the `pdf-poppler` npm package for better Linux compatibility.

## Why This Change?

### Previous Approach (pdf-poppler npm package)
- ❌ Node.js bindings to Poppler
- ❌ Linux compatibility issues
- ❌ Binary dependencies difficult to manage

### New Approach (native pdftoppm)
- ✅ Direct command-line usage via `child_process`
- ✅ Works reliably on Linux, macOS, and Windows
- ✅ Same backend used by Evince and pdf.js
- ✅ No Node.js binding dependencies
- ✅ Easier to deploy in containerized environments

## Installation

### 1. Install Poppler Utils

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y poppler-utils
```

#### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL 7
sudo yum install -y poppler-utils

# CentOS/RHEL 8+ / Fedora
sudo dnf install -y poppler-utils
```

#### macOS
```bash
brew install poppler
```

#### Windows
1. Download from: https://github.com/oschwartz10612/poppler-windows/releases
2. Extract to a folder (e.g., `C:\Program Files\poppler`)
3. Add the `bin` folder to your PATH:
   - Right-click "This PC" → Properties → Advanced System Settings
   - Environment Variables → System Variables → Path → Edit
   - Add: `C:\Program Files\poppler\Library\bin`
   - Click OK and restart your terminal

#### Docker (for deployment)
```dockerfile
FROM node:20-alpine

# Install Poppler Utils
RUN apk add --no-cache poppler-utils

# Rest of your Dockerfile...
```

### 2. Verify Installation

```bash
pdftoppm -v
```

**Expected output:**
```
pdftoppm version 22.02.0
Copyright 2005-2022 The Poppler Developers - http://poppler.freedesktop.org
Copyright 1996-2011 Glyph & Cog, LLC
```

**Test basic conversion:**
```bash
# Create a test PDF (if you have one)
pdftoppm test.pdf output -png

# This should create output-1.png, output-2.png, etc.
```

## How It Works

### Code Flow

1. **PDF Upload** → `upload-document` endpoint
2. **Text Detection** → Try to extract text with `pdf-parse`
3. **If no text layer** → Fallback to Vision API extraction:
   ```typescript
   // Convert PDF to images
   const command = `pdftoppm "${filePath}" "${outputPrefix}" -png`;
   await execAsync(command);
   
   // Process images in parallel batches
   const CONCURRENT_PAGES = 6;
   for (let batch = 0; batch < pages.length; batch += CONCURRENT_PAGES) {
     const batchPages = pages.slice(batch, batch + CONCURRENT_PAGES);
     const results = await Promise.all(
       batchPages.map(page => visionAPI.extract(page))
     );
     pageTexts.push(...results);
   }
   ```

### File Locations

- **Implementation:** `api/src/services/document-ingestion.service.ts`
  - Method: `extractFromScannedPDFWithPoppler()`
  - Lines: ~557-700

## Testing

### Test 1: Verify pdftoppm Installation

```bash
# Check version
pdftoppm -v

# Check help
pdftoppm -h
```

### Test 2: Manual PDF Conversion

```bash
# Create a temp directory
mkdir /tmp/pdf-test

# Convert a sample PDF
pdftoppm sample.pdf /tmp/pdf-test/page -png

# Check output
ls /tmp/pdf-test/
# Should show: page-1.png, page-2.png, etc.
```

### Test 3: Upload a Scanned PDF

1. Start the backend server:
   ```bash
   cd api
   npm run dev
   ```

2. Open the frontend and upload a scanned PDF (no text layer)

3. Check the logs for:
   ```
   [Scanned PDF] Attempting pdftoppm (Poppler Utils) conversion
   [Poppler PDF] Converting 8 pages to images using pdftoppm
   [Poppler PDF] Executing: pdftoppm "/path/to/file.pdf" "/tmp/pdf-xxx/page" -png
   [Poppler PDF] PDF conversion completed
   [Poppler PDF] Generated 8 images
   [Poppler PDF] ⚡ Processing 8 pages with 2 concurrent workers
   ```

4. Expected timing (8-page PDF):
   - PDF to images: ~2-3 seconds
   - Vision API processing: ~40-80 seconds (depending on concurrency)
   - Total: ~1-2 minutes

### Test 4: Error Handling

Test the fallback mechanism when pdftoppm is not available:

```bash
# Temporarily rename pdftoppm (requires sudo)
sudo mv /usr/bin/pdftoppm /usr/bin/pdftoppm.bak

# Upload a scanned PDF
# Should see:
# [Scanned PDF] pdftoppm conversion failed: ...
# [Scanned PDF] Falling back to direct Vision API on PDF

# Restore pdftoppm
sudo mv /usr/bin/pdftoppm.bak /usr/bin/pdftoppm
```

## Troubleshooting

### Issue: "pdftoppm: command not found"

**Solution:**
```bash
# Check if installed
which pdftoppm

# If not found, install
sudo apt-get install -y poppler-utils  # Ubuntu/Debian
sudo yum install -y poppler-utils      # CentOS/RHEL
brew install poppler                   # macOS
```

### Issue: "Permission denied" on pdftoppm

**Solution:**
```bash
# Check permissions
ls -l $(which pdftoppm)

# Should be executable:
# -rwxr-xr-x 1 root root 123456 ... /usr/bin/pdftoppm

# If not, fix it:
sudo chmod +x /usr/bin/pdftoppm
```

### Issue: Slow Processing

**Solution 1: Increase Concurrency**
```bash
# In .env file
VISION_API_CONCURRENT_PAGES=6  # Default: 2, Max: 10
```

**Solution 2: Check Network Speed**
- Vision API calls are network-dependent
- Ensure stable connection to OpenAI/Google Vision API

**Solution 3: Monitor Logs**
```bash
# Check processing time per page
grep "Processing page" api.log

# Check batch timing
grep "Batch complete" api.log
```

### Issue: Images Not Generated

**Solution:**
```bash
# Test manually
pdftoppm test.pdf /tmp/test -png

# Check temp directory
ls /tmp/pdf-*

# Check disk space
df -h /tmp
```

## Performance Optimization

### Environment Variables

```bash
# api/.env

# Concurrent pages (higher = faster, but more memory/API load)
VISION_API_CONCURRENT_PAGES=6  # Default: 2

# DPI for image conversion (higher = better quality, slower)
PDFTOPPM_DPI=150  # Default: 150 (good balance)

# Image format (png or jpg)
PDFTOPPM_FORMAT=png  # Default: png
```

### Expected Performance

| Pages | Concurrent | Time | 
|-------|-----------|------|
| 1 | 1 | ~10-15s |
| 5 | 2 | ~40-60s |
| 8 | 2 | ~60-90s |
| 8 | 6 | ~40-50s |
| 20 | 6 | ~90-120s |

## Integration with Docker/Kubernetes

### Dockerfile

```dockerfile
FROM node:20-alpine

# Install Poppler Utils
RUN apk add --no-cache poppler-utils

# Verify installation
RUN pdftoppm -v

# Copy application
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .

# Build
RUN npm run build

# Start
CMD ["npm", "start"]
```

### Health Check

```bash
# Add to your health check script
if ! command -v pdftoppm &> /dev/null; then
  echo "ERROR: pdftoppm not found"
  exit 1
fi

echo "✅ Poppler Utils installed"
```

## Comparison: Before vs After

### Before (pdf-poppler npm package)

```typescript
const pdfPoppler = require('pdf-poppler');
const opts = {
  format: 'png',
  out_dir: tempDir,
  out_prefix: 'page',
  page: null,
  r: 150,
};
await pdfPoppler.convert(filePath, opts);
```

❌ Issues:
- Node.js binding issues on Linux
- Binary compatibility problems
- Harder to debug

### After (native pdftoppm)

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);

const command = `pdftoppm "${filePath}" "${outputPrefix}" -png`;
await execAsync(command);
```

✅ Benefits:
- Works reliably on all platforms
- Easier to debug (can test command directly)
- No binary dependencies
- Simpler deployment

## Additional Resources

- **Poppler Homepage:** https://poppler.freedesktop.org/
- **pdftoppm Manual:** `man pdftoppm` or https://linux.die.net/man/1/pdftoppm
- **Chatbot Documentation:** `docs/chatbot/README.md`
- **Implementation File:** `api/src/services/document-ingestion.service.ts`

## Support

If you encounter issues:

1. Check installation: `pdftoppm -v`
2. Review logs: Look for `[Poppler PDF]` entries
3. Test manually: Try converting a PDF with `pdftoppm` command
4. Check disk space: Ensure `/tmp` has enough space
5. Verify permissions: Ensure the Node.js process can execute `pdftoppm`

---

**Status:** ✅ Production Ready  
**Compatibility:** Linux, macOS, Windows  
**Last Updated:** 2025-10-15
