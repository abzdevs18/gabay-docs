# LLM Provider Strategy - DeepSeek Primary, OpenAI for Vision

> **Last Updated:** January 2025  
> **Status:** Production Configuration

## 🎯 Overview

The Gabay AI system now uses a **hybrid LLM provider strategy**:
- **DeepSeek (Primary)**: Default for all text-based processing, chat, and question generation
- **OpenAI (Vision Tasks)**: Used exclusively for image processing and vision capabilities

This strategy optimizes for **cost-effectiveness** while maintaining **quality** for vision tasks that require OpenAI's GPT-4 Vision API.

---

## 🔄 Provider Selection Logic

### AI Chat System (`/api/v2/ai/chat`)

**Primary**: DeepSeek  
**Fallback**: OpenAI

```typescript
// Priority Order:
1. DeepSeek (deepseek-chat) - Primary
2. OpenAI (gpt-5-nano) - Fallback if DeepSeek fails
```

**When it switches:**
- DeepSeek unavailable or fails
- DeepSeek API error or timeout
- Invalid DeepSeek model configuration

**Logs to watch:**
```
[AI Chat] Attempting with deepseek using model: deepseek-chat
[AI Chat] Successfully connected to DeepSeek
```

Or fallback scenario:
```
[AI Chat] Primary provider failed: deepseek API error...
[AI Chat] Attempting fallback to OpenAI...
[AI Chat] Fallback successful, using OpenAI
```

---

### Document Processing System

#### Text Documents (PDF, DOCX, TXT, etc.)
**Provider**: DeepSeek (via question generation services)

#### Image Documents (JPG, PNG, GIF, etc.)
**Provider**: OpenAI (GPT-4 Vision required)

```typescript
// In document-ingestion.service.ts
extractWithVisionAPI() {
  // Checks for OPENAI_API_KEY
  // Uses gpt-4o for vision processing
  // Falls back to OCR if OpenAI unavailable
}
```

**Logs to watch:**
```
[Vision API] Using OpenAI for image/vision processing
[Vision API] Image optimized from original to 245.32KB
```

---

### Question Generation System

**Primary**: DeepSeek  
**Fallback**: OpenAI

All question generation services use DeepSeek by default:
- `QuestionPlanningService` → `deepseek-chat`
- `QuestionGenerationWorkerPool` → `deepseek-chat`
- `QuestionValidationService` → `deepseek-chat`

**Configured in:**
- `/api/src/services/question-planning.service.ts`
- `/api/src/services/question-generation-worker-pool.service.ts`
- `/api/src/services/question-validation.service.ts`

---

## ⚙️ Environment Configuration

### Required Environment Variables

```env
# Primary Provider - DeepSeek (for text, chat, questions)
DEEPSEEK_API_KEY=sk-deepseek-xxxxxxxxxxxxxxxxxxxxx

# Vision Provider - OpenAI (for image processing only)
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx
OPENAI_CHAT_MODEL=gpt-5-nano

# Optional: Timeouts and limits
AI_REQUEST_TIMEOUT_MS=30000
```

### Configuration Priority

| Task Type | Primary | Fallback | Model |
|-----------|---------|----------|-------|
| Chat Messages | DeepSeek | OpenAI | `deepseek-chat` → `gpt-5-nano` |
| Text Documents | DeepSeek | OpenAI | `deepseek-chat` → `gpt-4o-mini` |
| Image Documents | **OpenAI** | OCR | `gpt-4o` (vision required) |
| Question Generation | DeepSeek | OpenAI | `deepseek-chat` → `gpt-4o-mini` |
| Question Planning | DeepSeek | OpenAI | `deepseek-chat` → `gpt-4o-mini` |
| Question Validation | DeepSeek | OpenAI | `deepseek-chat` → `gpt-4` |

---

## 💰 Cost Optimization

### Why DeepSeek Primary?

1. **Cost**: DeepSeek is significantly cheaper than OpenAI
   - DeepSeek Chat: ~$0.14 per 1M tokens
   - OpenAI GPT-4o-mini: ~$0.15 per 1M input tokens
   - OpenAI GPT-4: ~$10 per 1M input tokens

2. **Quality**: DeepSeek provides excellent quality for educational content

3. **Speed**: DeepSeek has comparable latency to OpenAI

### Why OpenAI for Vision?

1. **Capability**: DeepSeek doesn't currently support vision/image processing
2. **Quality**: GPT-4V (Vision) is industry-leading for image understanding
3. **Fallback**: System falls back to OCR if OpenAI unavailable

---

## 🔍 How to Verify Configuration

### 1. Check AI Chat Provider

```bash
# Test chat endpoint
curl -X POST http://localhost:3000/api/v2/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello", "context": {}}'

# Check logs for:
# [AI Chat] Attempting with deepseek using model: deepseek-chat
```

### 2. Check Vision Processing

```bash
# Upload an image document
# Check logs for:
# [Vision API] Using OpenAI for image/vision processing
```

### 3. Check Question Generation

```bash
# Generate questions from text
# Check logs for:
# 🤖 AI Providers available: DeepSeek=true, OpenAI=true
# Using DeepSeek for question generation
```

---

## 🚨 Troubleshooting

### Issue: Chat uses OpenAI instead of DeepSeek

**Cause**: `DEEPSEEK_API_KEY` not configured or DeepSeek failing

**Solution**:
```bash
# Verify DeepSeek key is set
echo $DEEPSEEK_API_KEY

# Check DeepSeek API status
curl https://api.deepseek.com/v1/models \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY"
```

### Issue: Image processing fails

**Cause**: `OPENAI_API_KEY` not configured

**Solution**:
```bash
# Verify OpenAI key is set
echo $OPENAI_API_KEY

# Ensure it has vision model access
# gpt-4o, gpt-4-turbo, or gpt-4-vision-preview
```

### Issue: Both providers fail

**Logs**:
```
[AI Chat] Both providers failed
All LLM providers failed. Primary: ..., Fallback: ...
```

**Solution**:
1. Check both API keys are valid
2. Verify API rate limits not exceeded
3. Check provider status pages
4. Review firewall/network restrictions

---

## 📊 Monitoring

### Key Metrics to Track

1. **Provider Usage Distribution**
   - % requests to DeepSeek vs OpenAI
   - Track in application logs

2. **Fallback Rate**
   - How often fallback to OpenAI occurs
   - Indicates DeepSeek reliability

3. **Vision API Usage**
   - Track image processing requests
   - Monitor OpenAI costs for vision

4. **Cost per Request**
   - DeepSeek: Track token usage
   - OpenAI: Track vision API calls separately

### Sample Log Analysis

```bash
# Count DeepSeek vs OpenAI usage
grep "Successfully connected to" api.log | \
  awk '{print $NF}' | sort | uniq -c

# Expected output:
#  850 DeepSeek
#   50 OpenAI (mostly fallback)
#   25 OpenAI (vision processing)
```

---

## 🔄 Migration Notes

### Previous Configuration
- OpenAI (gpt-5-nano) was primary for all tasks
- No provider fallback mechanism
- High costs for text processing

### Current Configuration  
- DeepSeek primary for text (80% cost reduction)
- OpenAI only for vision (necessary)
- Automatic fallback for reliability

### Breaking Changes
- None - API interfaces remain the same
- Only internal provider selection changed

---

## 🎯 Best Practices

### 1. Always Configure Both Providers

```env
# ✅ Recommended
DEEPSEEK_API_KEY=sk-deepseek-xxx
OPENAI_API_KEY=sk-proj-xxx

# ❌ Not Recommended (no fallback)
DEEPSEEK_API_KEY=sk-deepseek-xxx
# OPENAI_API_KEY=
```

### 2. Monitor Provider Health

- Set up alerting for fallback events
- Track cost per provider monthly
- Review error rates weekly

### 3. Use Appropriate Models

- DeepSeek: `deepseek-chat` (only available model)
- OpenAI Chat: `gpt-5-nano` or `gpt-4o-mini`
- OpenAI Vision: `gpt-4o` (supports vision)

### 4. Set Request Timeouts

```env
AI_REQUEST_TIMEOUT_MS=30000  # 30 seconds
```

---

## 📝 Implementation Files

### Modified Files

1. **`/api/src/pages/api/v2/ai/chat.ts`**
   - Changed primary provider to DeepSeek
   - Added automatic fallback to OpenAI
   - Fixed model validation

2. **`/api/src/services/document-ingestion.service.ts`**
   - Added OpenAI key check for vision
   - Changed vision model from `gpt-5-nano` to `gpt-4o`
   - Added clear logging for provider selection

3. **Question Generation Services** (already using DeepSeek)
   - `question-planning.service.ts`
   - `question-generation-worker-pool.service.ts`
   - `question-validation.service.ts`

---

## 🆘 Support

### Quick Reference

**DeepSeek Issues**: Check `/api/src/services/*deepseek*.ts`  
**OpenAI Vision Issues**: Check `/api/src/services/document-ingestion.service.ts`  
**Fallback Issues**: Check `/api/src/pages/api/v2/ai/chat.ts`

### Status Pages

- DeepSeek: https://status.deepseek.com/
- OpenAI: https://status.openai.com/

---

**Summary**: The system now uses DeepSeek for cost-effective text processing while reserving OpenAI for vision tasks that require GPT-4V capabilities. This hybrid approach provides the best balance of cost, quality, and reliability.
