# Cloudflare Tunnel Setup

Expose n8n securely to the internet — **no port forwarding, no static IP,
free HTTPS automatically**. Cloudflare Tunnel creates an outbound-only
encrypted connection from the Jetson Nano to Cloudflare's network.

---

## Prerequisites

- A Cloudflare account (free) → [cloudflare.com](https://cloudflare.com)
- A domain managed by Cloudflare (add your domain or buy one there)
  - If you don't have a domain, Cloudflare can give you a free `*.trycloudflare.com` URL (no account needed — see bottom of this doc)

---

## Step 1 — Create the Tunnel

1. Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. **Networks → Tunnels → Create a tunnel**
3. Choose **Cloudflared** as the connector type
4. Name it `nano-n8n` → click **Save tunnel**
5. Under **Choose your environment**, select **Docker**
6. Copy the token from the command shown — it looks like:
   ```
   cloudflared tunnel run --token eyJhIjoiABC...
   ```
   You only need the long token string after `--token`

---

## Step 2 — Configure the Public Hostname

Still in the tunnel setup:

1. Click **Next: Configure**
2. Under **Public Hostname**, click **Add a public hostname**
3. Fill in:
   - **Subdomain**: `n8n`
   - **Domain**: your domain (e.g. `yourdomain.com`)
   - **Service Type**: `HTTP`
   - **URL**: `n8n:5678` ← this is the Docker service name + port
4. Click **Save tunnel**

Your n8n will be available at `https://n8n.yourdomain.com`

---

## Step 3 — Update your `.env`

```dotenv
# Paste the token from Step 1
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiABC...your-full-token...

# Update host settings to match your public domain
N8N_HOST=n8n.yourdomain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.yourdomain.com/
```

---

## Step 4 — Restart the stack

```bash
docker compose down && docker compose up -d
```

Cloudflared will connect automatically. Check tunnel status:

```bash
docker compose logs cloudflared
```

You should see:
```
Registered tunnel connection ...
```

Open `https://n8n.yourdomain.com` — you're live with HTTPS. ✓

---

## Step 5 — Recommended security settings in Cloudflare

Go to your tunnel → **Access** to add an extra authentication layer
in front of n8n (in addition to n8n's own basic auth):

1. **Networks → Tunnels → nano-n8n → Edit → Access**
2. Enable **Cloudflare Access** for the hostname
3. Create an **Allow policy** → add your email → Save

This means only your email can reach the login page — everyone else
gets blocked at Cloudflare's edge before hitting your Nano.

---

## Free test URL (no domain required)

If you just want to test without a domain:

```bash
docker run --rm cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:5678
```

Cloudflare prints a temporary `https://random-name.trycloudflare.com` URL.
It's free but the URL changes every time you run it.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `tunnel: token is required` | Make sure `CLOUDFLARE_TUNNEL_TOKEN` is set in `.env` |
| `502 Bad Gateway` | n8n isn't running — check `docker compose ps` |
| `ERR_TOO_MANY_REDIRECTS` | Set `N8N_PROTOCOL=https` in `.env` and restart |
| Webhooks not working | Make sure `WEBHOOK_URL` uses the `https://` public domain |
| Can't reach tunnel | Check `docker compose logs cloudflared` for connection errors |
