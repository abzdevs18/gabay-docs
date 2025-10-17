# GraphicsMagick and Ghostscript Installation Guide for Windows

## Quick Fix Options

### Option 1: Install System Dependencies (Recommended)

#### Step 1: Install Ghostscript
1. Download Ghostscript from: https://www.ghostscript.com/download/gsdnld.html
   - For 64-bit Windows: Download `gs10031w64.exe` or latest version
   - For 32-bit Windows: Download `gs10031w32.exe` or latest version

2. Run the installer with Administrator privileges
3. Use default installation path (e.g., `C:\Program Files\gs\gs10.03.1\`)
4. After installation, add to PATH:
   - Open System Properties → Advanced → Environment Variables
   - Edit the `Path` variable
   - Add: `C:\Program Files\gs\gs10.03.1\bin`

#### Step 2: Install GraphicsMagick
1. Download from: https://sourceforge.net/projects/graphicsmagick/files/
   - Navigate to the latest version folder
   - Download: `GraphicsMagick-1.3.42-Q8-win64-dll.exe` (for 64-bit)
   - Or: `GraphicsMagick-1.3.42-Q8-win32-dll.exe` (for 32-bit)

2. Run the installer with Administrator privileges
3. **Important**: During installation, check these options:
   - ✅ Update executable search path
   - ✅ Associate supported file extensions
   - ✅ Install development headers and libraries

4. Verify installation:
   ```powershell
   gm version
   gs --version
   ```

### Option 2: Use Alternative Library (No System Dependencies)

If you cannot or prefer not to install system dependencies:

1. Install pdfjs-dist:
   ```bash
   cd api
   npm install pdfjs-dist
   ```

2. Update the code in `document-ingestion.service.ts`:
   ```typescript
   private async extractFromScannedPDFWithCanvas(
     filePath: string,
     tempDir: string,
     options: IngestionOptions
   ): Promise<{
     success: boolean;
     text?: string;
     pageCount?: number;
     error?: string;
   }> {
     const pdfjs = require('pdfjs-dist/legacy/build/pdf.js');
     const { createCanvas } = require('canvas');
     const sharp = require('sharp');
     // ... rest of the implementation
   }
   ```

### Option 3: Use Cloud-Based OCR Service

For production environments, consider using cloud OCR services:

1. **Google Cloud Vision API** (already partially implemented)
2. **AWS Textract**
3. **Azure Computer Vision API**

## Troubleshooting

### Error: "gm/convert binaries can't be found"
**Cause**: GraphicsMagick not installed or not in PATH

**Solution**:
1. Verify installation: `gm version`
2. If command not found, reinstall with "Update executable search path" checked
3. Restart your terminal/IDE after installation

### Error: "Could not execute GraphicsMagick/ImageMagick"
**Cause**: Missing Ghostscript for PDF processing

**Solution**:
1. Install Ghostscript first, then GraphicsMagick
2. Verify: `gs --version`
3. Ensure both are in system PATH

### Error: "write EPIPE"
**Cause**: Process communication failure, usually due to missing dependencies

**Solution**:
1. Reinstall both Ghostscript and GraphicsMagick
2. Restart the Node.js server
3. Check Windows Defender/Antivirus isn't blocking the executables

## Verification Script

Create a test file `test-pdf-conversion.js`:

```javascript
const { fromPath } = require('pdf2pic');
const path = require('path');

async function testConversion() {
  try {
    const converter = fromPath('test.pdf', {
      density: 100,
      saveFilename: 'test',
      savePath: './temp',
      format: 'png',
      width: 600,
      height: 600
    });
    
    const result = await converter(1);
    console.log('Success! Conversion working:', result);
  } catch (error) {
    console.error('Conversion failed:', error.message);
    console.log('\nPlease install:');
    console.log('1. Ghostscript: https://www.ghostscript.com/download/');
    console.log('2. GraphicsMagick: https://sourceforge.net/projects/graphicsmagick/');
  }
}

testConversion();
```

Run with: `node test-pdf-conversion.js`

## Production Deployment

For production servers:

### Docker Solution
```dockerfile
FROM node:20

# Install Ghostscript and GraphicsMagick
RUN apt-get update && apt-get install -y \
    ghostscript \
    graphicsmagick \
    && rm -rf /var/lib/apt/lists/*

# Rest of your Dockerfile
```

### Windows Server
Use Chocolatey package manager:
```powershell
# Install Chocolatey first if not installed
choco install ghostscript
choco install graphicsmagick
```

## Alternative Libraries Comparison

| Library | System Deps | Quality | Speed | Notes |
|---------|------------|---------|--------|--------|
| pdf2pic | Yes (GM+GS) | High | Fast | Requires system installation |
| pdfjs-dist | No | Medium | Medium | Pure JavaScript, larger bundle |
| pdf-poppler | Yes | High | Fast | Good for Linux, tricky on Windows |
| canvas + pdfjs | No* | Medium | Slow | *Canvas may need build tools |

## Conclusion

For the Gabay system:
1. **Development**: Install GraphicsMagick + Ghostscript for best results
2. **Production**: Use Docker with dependencies pre-installed
3. **Fallback**: Implement pdfjs-dist as backup when system deps unavailable

The current implementation includes fallback mechanisms:
1. Try pdf2pic (requires system deps)
2. Fall back to canvas-based conversion (no system deps)
3. Final fallback to direct Vision API processing
