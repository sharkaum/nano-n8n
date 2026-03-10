#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# setup-owner.sh
# Automatically creates the n8n owner account on first boot.
# Run this ONCE after "docker compose up -d" on a fresh install.
# Safe to re-run — it exits silently if an owner already exists.
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Load .env if present ─────────────────────────────────────────────────────
if [ -f "$(dirname "$0")/../.env" ]; then
  export $(grep -v '^#' "$(dirname "$0")/../.env" | xargs)
fi

# ── Required variables ───────────────────────────────────────────────────────
N8N_URL="${N8N_PROTOCOL:-http}://${N8N_HOST:-localhost}:${N8N_PORT:-5678}"
OWNER_EMAIL="${N8N_OWNER_EMAIL:?Please set N8N_OWNER_EMAIL in .env}"
OWNER_PASSWORD="${N8N_OWNER_PASSWORD:?Please set N8N_OWNER_PASSWORD in .env}"
OWNER_FIRSTNAME="${N8N_OWNER_FIRSTNAME:-Admin}"
OWNER_LASTNAME="${N8N_OWNER_LASTNAME:-Nano}"

echo "→ Waiting for n8n to be ready at $N8N_URL ..."

# ── Wait until n8n responds ──────────────────────────────────────────────────
MAX_WAIT=60
WAITED=0
until curl -sf "$N8N_URL/healthz" > /dev/null 2>&1; do
  if [ $WAITED -ge $MAX_WAIT ]; then
    echo "✗ n8n did not become ready within ${MAX_WAIT}s. Is it running?"
    exit 1
  fi
  sleep 2
  WAITED=$((WAITED + 2))
done

echo "→ n8n is up. Attempting owner setup..."

# ── Call the first-time setup endpoint ──────────────────────────────────────
RESPONSE=$(curl -sf -X POST "$N8N_URL/api/v1/owner/setup" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":     \"$OWNER_EMAIL\",
    \"password\":  \"$OWNER_PASSWORD\",
    \"firstName\": \"$OWNER_FIRSTNAME\",
    \"lastName\":  \"$OWNER_LASTNAME\"
  }" 2>&1) || true

# ── Interpret response ────────────────────────────────────────────────────────
if echo "$RESPONSE" | grep -q '"id"'; then
  echo "✓ Owner account created: $OWNER_EMAIL"
elif echo "$RESPONSE" | grep -qi '"owner already"'; then
  echo "✓ Owner account already exists — nothing to do."
else
  echo "⚠ Unexpected response (owner may already exist, or check logs):"
  echo "$RESPONSE"
fi
