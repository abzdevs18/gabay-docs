# Gabay Form - Data Flow Diagrams

> Visual representation of data flow through the system

---

## Form Submission Flow

```
Student → Form Page → Submit → API Server
                                    ↓
                          1. Validate & Save
                          2. LRN Lookup
                          3. Notify Teacher (Socket.IO)
                          4. Queue AI Job (Redis)
                          5. Auto-grade (if linked)
                                    ↓
                          Return Success (201)
                                    ↓
                          Background Worker
                                    ↓
                          Generate AI Feedback
                                    ↓
                          Send Email (Brevo)
```

**Key Points:**
- Response saved immediately (synchronous)
- AI feedback generated asynchronously
- Email delivery ~5-8 seconds after submission
- Multi-tenant context preserved throughout

---

## Form Builder Flow

```
Teacher → Builder Page → Make Changes → Auto-save (2s debounce)
                              ↓
                        dispatch(action)
                              ↓
                        Reducer updates state
                              ↓
                        React re-renders
                              ↓
                        API PATCH request
                              ↓
                        Clear caches
```

**Key Points:**
- Client-side state management with useReducer
- Auto-save prevents data loss
- Cache invalidation ensures consistency

---

## AI Feedback Generation

```
Job Queued → Worker → Fetch Form → Analyze Answers
                          ↓
                    Generate Prompt
                          ↓
                    Call OpenAI API
                          ↓
                    Create Email HTML
                          ↓
                    Send via Brevo
```

**Timing:**
- Job queue: <50ms
- Fetch data: ~100ms
- AI generation: 3-5s
- Email send: 1-2s
- **Total: 5-8s**

---

## Related Documentation

- [Architecture Diagrams](./architecture-diagrams.md)
- [AI Feedback System](./ai-feedback-system.md)
