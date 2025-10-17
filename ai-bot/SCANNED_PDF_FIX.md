# Scanned PDF Processing Fix Documentation

## Issue Description
When processing scanned PDFs (documents with no text layer, such as those exported from CamScanner), the document ingestion service was failing with the error:
```
TypeError: pdf2pic is not a function
```

## Root Cause Analysis

### Problem Location
- **File**: `/api/src/services/document-ingestion.service.ts`
- **Method**: `extractFromScannedPDF`
- **Line**: 528 (before fix)

### Issue Details
The `pdf2pic` library was being imported incorrectly:
```typescript
// INCORRECT (old code)
const { pdf2pic } = require('pdf2pic');
const converter = pdf2pic({...});
```

### Correct Import Pattern
According to the pdf2pic documentation, the correct import pattern is:
```typescript
// CORRECT (new code)
const { fromPath } = require('pdf2pic');
const converter = fromPath(filePath, options);
```

## Implementation Fix

### Changes Applied

1. **Import Statement Fix**
   - Changed from destructuring `pdf2pic` to destructuring `fromPath`
   - Updated the converter initialization to use `fromPath(filePath, options)`

2. **Option Properties Update**
   - Changed `savename` to `saveFilename` (correct property name)
   - Changed `savedir` to `savePath` (correct property name)

3. **Method Call Update**
   - Changed from `converter.convertBulk(filePath, [pageNum])` 
   - To: `converter(pageNum, { responseType: 'image' })`

4. **Error Handling Enhancement**
   - Added try-catch block around pdf2pic initialization
   - Improved error messages for debugging

### Complete Fixed Code
```typescript
// Convert PDF to images using pdf2pic
let converter: any;
try {
  const { fromPath } = require('pdf2pic');
  converter = fromPath(filePath, {
    density: 200,           // DPI for image quality
    saveFilename: 'page',   // Correct property name
    savePath: tempDir,      // Correct property name
    format: 'png',
    width: 2048,            // Max width for Vision API
    height: 2048            // Max height for Vision API
  });
} catch (pdf2picError) {
  console.error(`[Scanned PDF] pdf2pic initialization failed:`, pdf2picError);
  throw new Error(`PDF to image conversion failed: ${pdf2picError instanceof Error ? pdf2picError.message : 'Unknown error'}`);
}

// Convert page to image
converter(pageNum, { responseType: 'image' })
  .then(async (output: any) => {
    if (output && output.path) {
      const imagePath = output.path;
      // Process with Vision API...
    }
  });
```

## Processing Flow for Scanned PDFs

1. **Text Layer Detection**
   - System first attempts to extract text from PDF
   - If text content is < 100 characters per page (average), PDF is treated as scanned

2. **Vision API Processing**
   - PDF is converted to images page by page using pdf2pic
   - Each page image is processed with Vision API for OCR
   - Text from all pages is combined

3. **Fallback Options**
   - If Vision API fails, system falls back to Tesseract OCR
   - If all methods fail, error is returned to user

## Frontend Comparison

The frontend (`AIAssistantChat.tsx`) handles document processing differently:

### Frontend Approach
1. Attempts text extraction first
2. If text extraction fails, converts document to images
3. Routes to appropriate AI model:
   - Text extraction success → Deepseek (text model)
   - Image conversion → GPT Vision (vision model)

### Key Differences
- Frontend uses `pdf-poppler` for PDF to image conversion
- Frontend implementation is currently incomplete (returns placeholder)
- Frontend has better user feedback with progress logs and toast notifications

## Testing Recommendations

### Test Scenarios
1. **Scanned PDF from CamScanner**
   - Upload a PDF exported from CamScanner
   - Verify successful conversion to images
   - Confirm text extraction via Vision API

2. **Mixed Content PDF**
   - Upload PDF with both text and scanned pages
   - Verify appropriate processing method selection

3. **Large Scanned PDF**
   - Upload multi-page scanned document (10+ pages)
   - Verify batch processing works correctly
   - Check memory management

### Expected Logs
```
[PDF] No meaningful text layer found (only X chars for Y pages). Treating as scanned PDF.
[PDF] Attempting Vision API extraction for scanned PDF
[Scanned PDF] Converting PDF to images for Vision API processing
[Scanned PDF] Processing Y pages
[Scanned PDF] Processing page 1/Y
...
[Scanned PDF] Successfully extracted Z characters from Y pages
```

## Dependencies

### Required npm packages
- `pdf2pic`: ^3.2.0
- `pdf-parse`: ^1.1.1
- `canvas`: ^2.11.2 (already installed)
- `sharp`: ^0.34.4 (already installed)

### System Dependencies (CRITICAL)
**Important**: pdf2pic requires these system dependencies to be installed:

#### Windows Installation:
1. **GraphicsMagick**
   - Download from: https://sourceforge.net/projects/graphicsmagick/files/
   - Choose the Q8 version for your system (32-bit or 64-bit)
   - During installation, ensure "Update executable search path" is checked
   
2. **Ghostscript**
   - Download from: https://www.ghostscript.com/download/gsdnld.html
   - Install the version matching your system architecture
   - Add Ghostscript bin directory to system PATH

#### Alternative Solution (No System Dependencies)
If you cannot install GraphicsMagick/Ghostscript, install pdfjs-dist instead:
```bash
npm install pdfjs-dist
```
Then uncomment the canvas-based conversion code in document-ingestion.service.ts

## Future Improvements

1. **Frontend Enhancement**
   - Complete the `convertWithPdfPoppler` implementation
   - Add proper error handling and retry logic

2. **Performance Optimization**
   - Implement caching for converted images
   - Optimize batch size based on document characteristics

3. **Alternative Solutions**
   - Consider using `sharp` or `canvas` for PDF rendering
   - Evaluate cloud-based OCR services for better accuracy

## Related Files

- **Backend Service**: `/api/src/services/document-ingestion.service.ts`
- **Frontend Component**: `/frontend/src/components/AIAssistantChat.tsx`
- **Frontend API**: `/frontend/src/pages/api/documents/parse-chunked.ts`
- **Documentation**: `/docs/ai-bot/DOCUMENT_ATTACHMENT_IMPLEMENTATION.md`

## Support Notes

If issues persist after this fix:

1. **Check System Dependencies**
   ```bash
   # Verify GraphicsMagick installation
   gm version
   
   # Verify Ghostscript installation
   gs --version
   ```

2. **Check File Permissions**
   - Ensure temp directory is writable
   - Verify PDF file is readable

3. **Monitor Memory Usage**
   - Large PDFs may require increased Node.js memory limit
   - Consider adjusting batch size for processing

## Conclusion

This fix resolves the immediate issue with scanned PDF processing by correctly implementing the pdf2pic library. The solution maintains backward compatibility while improving error handling and providing better debugging information.
