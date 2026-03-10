# AI Companion — Configuration & Parameter Reference

This document describes every configurable parameter for the AI companion
running inside n8n on the Jetson Nano. All values live in your `.env` file
(never committed to git). Refer to `.env.example` for the template.

---

## 1. Identity & Persona

| Parameter | `.env` key | Default | Description |
|---|---|---|---|
| Name | `AI_COMPANION_NAME` | `Nano` | Name used in system prompts and UI labels |
| Persona | `AI_COMPANION_PERSONA` | `a helpful, concise, and resourceful AI assistant` | Short description injected at the start of every system prompt. Be specific — e.g. *"a friendly home automation assistant who prefers short answers"* |

**Example persona strings:**
- `"a concise technical assistant that avoids jargon"`
- `"a home automation expert focused on local-first solutions"`
- `"a multilingual assistant, always respond in the user's language"`

---

## 2. Provider & Model

| Parameter | `.env` key | Default | Notes |
|---|---|---|---|
| Default provider | `AI_DEFAULT_PROVIDER` | `ollama` | `ollama` · `openai` · `anthropic` · `google` · `groq` · `huggingface` |
| Default model | `AI_DEFAULT_MODEL` | `llama3` | Must match a model available on the chosen provider |

### Recommended models for Jetson Nano (Ollama / local)

The Jetson Nano has limited RAM (~4 GB). Prefer quantized models:

| Model | Size | RAM needed | Good for |
|---|---|---|---|
| `phi3:mini` | ~2.3 GB | ~3 GB | Fast responses, low RAM |
| `llama3:8b-q4` | ~4.7 GB | ~5 GB | Best quality within limits |
| `mistral:7b-q4` | ~4.1 GB | ~5 GB | General purpose |
| `gemma2:2b` | ~1.6 GB | ~2 GB | Ultralight, fastest |
| `tinyllama` | ~0.6 GB | ~1 GB | Minimal footprint |

Pull a model on the host Jetson before starting n8n:
```bash
ollama pull phi3:mini
```

### Cloud provider model examples

| Provider | `AI_DEFAULT_MODEL` example |
|---|---|
| OpenAI | `gpt-4o-mini` · `gpt-4o` |
| Anthropic | `claude-3-5-haiku-20241022` · `claude-3-7-sonnet-20250219` |
| Google | `gemini-2.0-flash` |
| Groq | `llama-3.3-70b-versatile` · `mixtral-8x7b-32768` |

---

## 3. Generation Parameters

| Parameter | `.env` key | Default | Range | Notes |
|---|---|---|---|---|
| Max tokens | `AI_MAX_TOKENS` | `2048` | 256 – 8192 | Maximum tokens in each AI response. Lower = faster on Nano |
| Temperature | `AI_TEMPERATURE` | `0.7` | 0.0 – 1.0 | 0 = deterministic · 1 = creative/random |

**Temperature guidance:**
- `0.0 – 0.3` → Factual Q&A, code generation, structured data extraction
- `0.4 – 0.7` → Balanced — general assistant use
- `0.8 – 1.0` → Creative writing, brainstorming, varied responses

---

## 4. Memory & Context

| Parameter | `.env` key | Default | Description |
|---|---|---|---|
| Memory enabled | `AI_MEMORY_ENABLED` | `true` | Stores conversation history between workflow runs |

When `AI_MEMORY_ENABLED=true`, n8n uses the **Window Buffer Memory** node to
maintain a rolling chat history. The default window is **10 messages** — this
can be adjusted directly inside the n8n workflow node.

For Jetson Nano, keep the memory window small (5–10 messages) to avoid
exceeding the context window of smaller local models.

---

## 5. Ollama Local LLM (Recommended for Jetson Nano)

| Parameter | `.env` key | Default |
|---|---|---|
| Ollama base URL | `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` |

### Installing Ollama on Jetson Nano

```bash
# Install Ollama (ARM64 build)
curl -fsSL https://ollama.com/install.sh | sh

# Verify it is running
ollama list

# Pull your model (example)
ollama pull phi3:mini

# Test
ollama run phi3:mini "hello, are you running on ARM?"
```

The `host.docker.internal` hostname in Docker Compose automatically resolves
to the Jetson Nano host IP, so n8n can call Ollama even though Ollama runs
outside the container.

---

## 6. n8n Workflow Design Tips for AI Companion

### Minimum required nodes for a chat workflow

```
[Chat Trigger]  →  [AI Agent]  →  [Window Buffer Memory]
                       ↓
               [Ollama / OpenAI / Anthropic model node]
```

### System prompt template

In the AI Agent node → **System Message** field, use:

```
You are {{ $env.AI_COMPANION_NAME }}, {{ $env.AI_COMPANION_PERSONA }}.
Today's date is {{ $now.format('YYYY-MM-DD') }}.
Be concise. If you don't know something, say so.
```

### Enabling the n8n chat UI

The built-in chat widget is available at:
```
http://<jetson-ip>:5678/webhook/<your-webhook-path>/chat
```

Enable it in the **Chat Trigger** node → toggle **"Add chat interface"**.

---

## 7. Security Notes

- The `.env` file is listed in `.gitignore` and must **never** be pushed to GitHub.
- API keys are passed as environment variables inside Docker — they are not
  stored in the n8n database.
- n8n Basic Auth (`N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD`) protects
  the UI. For internet-facing deployments, place an NGINX reverse proxy with
  HTTPS in front of n8n.
- The `N8N_ENCRYPTION_KEY` encrypts all credentials stored in the PostgreSQL
  database. **Back this key up securely** — losing it means losing all saved
  credentials.

---

## 8. Environment Variable Quick Reference

```bash
# View current values loaded inside the n8n container (without secrets)
docker exec nano-n8n env | grep -v "PASSWORD\|KEY\|SECRET" | sort

# Restart after changing .env
docker compose down && docker compose up -d

# Follow logs
docker compose logs -f n8n
```
