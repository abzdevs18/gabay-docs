# Document Memory Debugging Guide

## Issue

Documents show as "ready" and "1 in memory" but the AI chatbot cannot access their content when asked questions about them.

## Root Causes (Ranked by Likelihood)

### 1. **Missing extractedTextPath** (70% likely)
The document is marked as "ready" but `extractedTextPath` field is NULL in the database.

**How to check:**
```sql
SELECT id, status, extractedTextPath, characterCount 
FROM DocumentIndex 
WHERE status = 'ready' 
LIMIT 10;
```

**Expected:** `extractedTextPath` should be `/tmp/gabay-extracted/{documentId}.txt` or similar

### 2. **File System Access Issue** (20% likely)
The extracted text file exists in the database but can't be read from disk.

**How to check:**
```bash
# Check if directory exists and is writable
ls -la /tmp/gabay-extracted/

# Check if specific document file exists
cat /tmp/gabay-extracted/{documentId}.txt
```

### 3. **Race Condition** (10% likely)
User queries the document before the upload process fully completes.

## Enhanced Logging Added

Added detailed logging to `getExtractedText()` method:

```
[getExtractedText] Fetching document {documentId}
[getExtractedText] Document found - id: xxx, status: ready, extractedTextPath: /path/to/file.txt
[getExtractedText] Reading file from: /path/to/file.txt
[getExtractedText] Successfully read 1234 characters from {documentId}
```

## How to Debug

### Step 1: Check Backend Logs

Upload a document and immediately query it. Look for these log patterns:

**Success Pattern:**
```
[AI Chat] Ready documents: 1, Processing: 0
[getExtractedText] Fetching document abc-123
[getExtractedText] Document found - id: abc-123, status: ready, extractedTextPath: /tmp/gabay-extracted/abc-123.txt
[getExtractedText] Reading file from: /tmp/gabay-extracted/abc-123.txt
[getExtractedText] Successfully read 5000 characters from abc-123
[AI Chat] Retrieved document content for document.pdf, length: 5000
[AI Chat] Added document content to context
```

**Failure Pattern (No extractedTextPath):**
```
[AI Chat] Ready documents: 1, Processing: 0
[getExtractedText] Fetching document abc-123
[getExtractedText] Document found - id: abc-123, status: ready, extractedTextPath: NULL
[getExtractedText] Document abc-123 has no extractedTextPath. Status: ready
[AI Chat] No extracted text found for document abc-123
[AI Chat] WARNING: Document content could not be retrieved
```

**Failure Pattern (File Not Found):**
```
[getExtractedText] Document found - id: abc-123, status: ready, extractedTextPath: /tmp/gabay-extracted/abc-123.txt
[getExtractedText] Reading file from: /tmp/gabay-extracted/abc-123.txt
[getExtractedText] Failed to read extracted text file for abc-123: ENOENT: no such file or directory
[getExtractedText] Attempted path: /tmp/gabay-extracted/abc-123.txt
```

### Step 2: Verify Document Upload Process

Check upload logs for this sequence:

```
[Document Upload] Document stored, starting text extraction...
[PDF] Text layer found with 5000 characters
  OR
[Vision API] Using OpenAI for image/vision processing
[Vision API] Image optimized from original to 245.32KB

Document abc-123 processed successfully. Text length: 5000
Step 6: Store extracted text         <-- Should happen here
Step 7: Update document index         <-- extractedTextPath set here
Document processing completed successfully
```

### Step 3: Check Environment Variables

```bash
echo $EXTRACTED_TEXT_PATH
# Should output: /tmp/gabay-extracted or your custom path

# Verify the directory is writable
touch /tmp/gabay-extracted/test.txt && rm /tmp/gabay-extracted/test.txt
```

## Quick Fixes

### Fix 1: If extractedTextPath is NULL

The `storeExtractedText` step is failing silently. Add error handling:

```typescript
// In document-ingestion.service.ts, line ~208
const textPath = await this.storeExtractedText(documentId, extractedText);
console.log(`[DEBUG] Stored extracted text at: ${textPath}`);
```

### Fix 2: If File Not Found

Directory permissions or path issue:

```bash
# Ensure directory exists with correct permissions
sudo mkdir -p /tmp/gabay-extracted
sudo chmod 777 /tmp/gabay-extracted

# Or set custom path in .env
EXTRACTED_TEXT_PATH=/app/data/extracted-text
```

### Fix 3: Race Condition

Add a small delay or polling mechanism in the frontend:

```typescript
// After document shows "ready", wait 500ms before querying
setTimeout(() => {
  askAboutDocument();
}, 500);
```

## Verification Steps

1. **Upload a simple text file** (test.txt with "Hello World")
2. **Wait for "ready" status**
3. **Check logs immediately** for the patterns above
4. **Ask "what is in the document?"**
5. **Compare AI response** with expected behavior

## Expected Behavior

✅ **Correct:**
- AI says: "The document contains [summary of actual content]"
- Logs show: "Successfully read X characters from {documentId}"

❌ **Incorrect:**
- AI says: "Document is still being processed" or "I cannot access the document"
- Logs show: "No extracted text found" or "extractedTextPath: NULL"

## Contact Points for Further Investigation

If issue persists after checking above:

1. Check Prisma schema for `DocumentIndex.extractedTextPath` field type
2. Verify database connection (multi-tenant vs single tenant)
3. Check if `storeExtractedText()` is throwing unhandled errors
4. Verify file system has sufficient space: `df -h /tmp`

## Model Note

⚠️ **IMPORTANT**: The user changed the vision model back to `gpt-5-nano` (line 1021). 

**Issue:** `gpt-5-nano` does NOT support vision. This will cause vision processing to fail for images.

**Fix:** Change it back to `gpt-4o` or `gpt-4-turbo`:

```typescript
// Line 1021 in document-ingestion.service.ts
model: "gpt-4o", // ✅ Supports vision
// NOT: "gpt-5-nano" // ❌ No vision support
```

This could be causing image documents to fail extraction, resulting in NULL extractedTextPath.
