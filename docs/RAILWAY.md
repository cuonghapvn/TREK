# Deploy TREK on Railway

TREK is best deployed on Railway as a Dockerfile service with one persistent volume. The app stores its SQLite database, secrets, logs, backups, and uploaded files on disk, so a volume is required for production use.

## 1. Deploy the GitHub repo

1. In Railway, create a new project from the TREK GitHub repository.
2. Railway will detect `railway.json` and build the root `Dockerfile`.
3. Open the service settings and generate a public Railway domain.

## 2. Add a persistent volume

Create a volume for the TREK service and mount it at:

```text
/app/storage
```

The Railway start script maps this single volume to TREK's runtime paths:

```text
/app/storage/data    -> /app/data
/app/storage/uploads -> /app/uploads
```

Do not mount a Railway volume at `/app`, because that hides the built application files inside the container.

## 3. Set variables

Recommended service variables:

```text
NODE_ENV=production
TZ=UTC
LOG_LEVEL=info
TRUST_PROXY=1
FORCE_HTTPS=true
COOKIE_SECURE=true
APP_URL=https://your-trek-domain.up.railway.app
ALLOWED_ORIGINS=https://your-trek-domain.up.railway.app
ENCRYPTION_KEY=<64 hex characters>
```

Generate `ENCRYPTION_KEY` locally:

```bash
openssl rand -hex 32
```

Optional first-boot admin credentials:

```text
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=<strong password>
```

If these are omitted, TREK prints generated admin credentials in the deployment logs on first boot.

## 4. Verify

After deploy, Railway should pass the configured healthcheck:

```text
/api/health
```

Open the public domain and sign in with the first-boot admin account.
