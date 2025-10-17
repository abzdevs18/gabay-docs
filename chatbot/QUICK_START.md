# 🚀 Quick Start Guide

> Get the Gabay AI Chatbot running in 10 minutes

---

## Prerequisites

- Node.js 20.x+
- PostgreSQL 14+ 
- OpenAI API key

## 1. Clone & Install

```bash
# Clone repository
git clone https://github.com/your-org/gabay
cd gabay

# Install backend dependencies
cd api
npm install

# Install frontend dependencies
cd ../frontend
npm install
```

## 2. Database Setup

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE gabay;
\c gabay

# Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

# Create HNSW index
CREATE INDEX conversation_memory_embedding_hnsw_idx 
ON "ConversationMemory" 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

## 3. Environment Variables

```bash
# api/.env
DATABASE_URL="postgresql://user:pass@localhost:5432/gabay"
OPENAI_API_KEY="sk-..."
DEEPSEEK_API_KEY="sk-..."  # Optional

ENABLE_ASYNC_UPLOAD=true
VISION_API_CONCURRENT_PAGES=6
```

## 4. Run Migrations

```bash
cd api
npx prisma migrate deploy
```

## 5. Start Services

```bash
# Terminal 1: Backend
cd api
npm run dev

# Terminal 2: Frontend
cd frontend
npm run dev
```

## 6. Test

Open http://localhost:3000/chat

1. Upload a PDF document
2. Should return in 2-3 seconds ✅
3. Ask: "Create 5 questions from this document"
4. Watch questions generate in real-time ✅

---

## Troubleshooting

**"pgvector not found"**
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-14-pgvector

# Mac
brew install pgvector
```

**"Connection refused"**
- Check PostgreSQL is running
- Verify DATABASE_URL in .env

**"Invalid API key"**
- Check OPENAI_API_KEY is set
- Verify key is valid at platform.openai.com

---

**Next:** Read [README.md](./README.md) for complete documentation
