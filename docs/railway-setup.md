# Railway Setup — Say it right! Backend

## Prerequisites

- [Railway CLI](https://docs.railway.com/guides/cli) installed: `brew install railway`
- Railway account at https://railway.com

## 1. Create the project

```bash
railway login
cd backend
railway init          # creates a new project, name it "say-it-right"
```

## 2. Add PostgreSQL

```bash
railway add --plugin postgresql
```

Railway auto-provisions the database and sets `DATABASE_URL` in the service environment.

## 3. Set environment variables

In the Railway dashboard (or via CLI):

```bash
railway variables set API_KEY="$(openssl rand -hex 32)"
railway variables set ANTHROPIC_API_KEY="sk-ant-your-key-here"
railway variables set NODE_ENV="production"
```

`DATABASE_URL` and `PORT` are set automatically by Railway.

## 4. Deploy

Railway auto-detects Node.js. It will run:

1. `npm install`
2. `npm run db:generate` (add to build command — see below)
3. `npm run start`

### Configure build command

In Railway dashboard → Service → Settings → Build:

```
Build Command: npm install && npx prisma generate && npx prisma migrate deploy
Start Command: npm run start
```

Or set via `railway.toml` in the backend directory:

```toml
[build]
builder = "nixpacks"
buildCommand = "npm install && npx prisma generate && npx prisma migrate deploy"

[deploy]
startCommand = "npm run start"
healthcheckPath = "/api/v1/health"
restartPolicyType = "on_failure"
```

## 5. Create initial migration

Locally, with a running Postgres (or using Railway's connection):

```bash
# Connect to Railway's database locally
railway link
railway run npx prisma migrate dev --name init
```

This creates the migration files in `prisma/migrations/` which should be committed to git.

## 6. Verify deployment

```bash
# Get the deployment URL
railway open

# Test health endpoint
curl https://your-app.up.railway.app/api/v1/health

# Test authenticated endpoint
curl -H "X-API-Key: your-api-key" \
  https://your-app.up.railway.app/api/v1/models
```

## 7. Update iOS Config.plist

Copy values into your local `Config.plist`:

```xml
<key>BackendURL</key>
<string>https://your-app.up.railway.app</string>

<key>BackendAPIKey</key>
<string>your-api-key-from-step-3</string>
```

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/health` | No | Health check |
| GET | `/api/v1/sync/:deviceId?since=ISO` | Yes | Pull changes since timestamp |
| POST | `/api/v1/sync/:deviceId` | Yes | Push local changes |
| GET | `/api/v1/models` | Yes | List available Anthropic models |
| POST | `/api/v1/debug-logs/:deviceId` | Yes | Upload debug log entries |
| GET | `/api/v1/debug-logs/:deviceId?limit=N` | Yes | Retrieve debug logs |

## Monitoring

- Railway dashboard shows logs, metrics, and deployment history
- Health endpoint returns service status and version
- Debug logs are persisted in the database (uploaded from iOS when debug mode is enabled)
