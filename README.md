# nano-n8n

n8n workflow automation running on a **Jetson Nano** (ARM64) via Docker Compose,
with PostgreSQL persistence and a configurable AI companion powered by local
(Ollama) or cloud LLMs.

---

## Repository structure

```
nano-n8n/
├── docker-compose.yml           # Main service definitions (n8n + PostgreSQL)
├── .env.example                 # Secret template — copy to .env and fill in
├── .env                         # ⛔ SECRET — never committed (in .gitignore)
├── .gitignore
├── AI_COMPANION_INSTRUCTIONS.md # Full AI companion parameter reference
├── custom-nodes/                # (optional) drop custom n8n nodes here
└── README.md
```

---

## Prerequisites — Jetson Nano

| Requirement | Version | Notes |
|---|---|---|
| JetPack / Ubuntu | 18.04 or 20.04 | |
| Docker | 20.10+ | `sudo apt install docker.io` |
| Docker Compose | v2 | `sudo apt install docker-compose-plugin` |
| Ollama *(optional)* | latest | Only if using local LLMs |

---

## Quick start

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/nano-n8n.git
cd nano-n8n
```

### 2. Create your secret `.env` file

```bash
cp .env.example .env
nano .env          # or use any editor
```

Fill in **every** value marked `CHANGE_ME`. See `.env.example` for guidance.

Generate a strong encryption key with:
```bash
openssl rand -hex 32
```

### 3. (Optional) Install Ollama for local AI

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull phi3:mini     # ~2.3 GB, good fit for Jetson Nano 4 GB
```

### 4. Start n8n

```bash
docker compose up -d
```

### 5. Open n8n

```
http://<jetson-nano-ip>:5678
```

Log in with the `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD` you set
in `.env`.

---

## AI companion setup (inside n8n)

1. Go to **Settings → Credentials** and add a credential for your chosen
   AI provider (Ollama, OpenAI, Anthropic, etc.).
2. Create a new workflow.
3. Add a **Chat Trigger** node → enable the built-in chat UI.
4. Add an **AI Agent** node and connect it to a model node + memory node.
5. Set the system prompt using the template in `AI_COMPANION_INSTRUCTIONS.md`.
6. Save & activate the workflow.

For detailed parameter tuning (models, temperature, memory window, persona)
see **[AI_COMPANION_INSTRUCTIONS.md](./AI_COMPANION_INSTRUCTIONS.md)**.

---

## Common commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f n8n
docker compose logs -f postgres

# Restart after editing .env
docker compose down && docker compose up -d

# Check running containers
docker compose ps

# Shell into n8n container
docker exec -it nano-n8n sh
```

---

## Updating n8n

```bash
docker compose pull
docker compose up -d
```

---

## Backup

n8n data (workflows, credentials) lives in the `n8n_data` Docker volume.
PostgreSQL data lives in `postgres_data`.

```bash
# Backup PostgreSQL
docker exec nano-n8n-db pg_dump -U n8n_user n8n > backup_$(date +%Y%m%d).sql

# Restore
docker exec -i nano-n8n-db psql -U n8n_user n8n < backup_YYYYMMDD.sql
```

---

## Security reminders

- `.env` is **gitignored** — never force-add it
- Back up your `N8N_ENCRYPTION_KEY` securely — losing it means losing all
  saved credentials in the database
- For public/internet access, put an HTTPS reverse proxy (e.g. NGINX +
  Certbot) in front of port 5678

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| n8n won't start | Check `docker compose logs n8n` — usually a missing or wrong `.env` value |
| Database connection refused | Wait 10 s for PostgreSQL healthcheck, then retry |
| Ollama unreachable from n8n | Confirm Ollama is running on host: `ollama list`; check `OLLAMA_BASE_URL` in `.env` |
| ARM64 image not found | Add `platform: linux/arm64` (already in compose file) |
| Port 5678 already in use | Change the host port in `docker-compose.yml` e.g. `"5679:5678"` |
