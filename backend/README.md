# FlowLy backend

Node.js + Express API for search, metadata and audio streaming.

## Run locally

```bash
cd backend
npm install
cp .env.example .env
npm start
```

The API listens on `http://localhost:4000` by default.

## Run with Docker

Start your self-hosted Shulker API on `http://localhost:8000`, then:

```bash
cd backend
docker compose up --build
```

FlowLy connects to Shulker through `SHULKER_API_URL`. In Docker the default is `http://host.docker.internal:8000` so a Shulker instance running on the development machine is reachable from the API container.

## Endpoints

- `GET /health` — FlowLy + Shulker provider health.
- `GET /api/search?q=...` — search tracks through Shulker.
- `GET /api/songs/:videoId` — track metadata through Shulker.
- `GET /api/stream/:videoId` — redirect to Shulker's `/api/stream/{id}/audio` endpoint.

## Shulker integration

FlowLy uses the self-hosted [Shulker](https://github.com/picklem0b/shulker) API as its primary music source.

Shulker documents these endpoints:

- `GET /api/search?q=&filter=`
- `GET /api/tracks/{id}`
- `GET /api/stream/{id}/audio`
- `GET /api/health`

Its search is backed by YouTube Music/`ytmusicapi`, and its stream endpoint serves local cached audio when available or pipes audio from `yt-dlp`.

FlowLy normalizes Shulker responses into its stable Flutter-facing track model, so the Flutter app does not depend on Shulker's internal response shape.

### Environment

```env
SHULKER_API_URL=http://127.0.0.1:8000
SHULKER_TIMEOUT_MS=12000
SHULKER_FALLBACK_YOUTUBE=false
```

Set `SHULKER_FALLBACK_YOUTUBE=true` only when you explicitly want FlowLy to use its old YouTube provider when Shulker is unavailable.

## MongoDB

`MONGODB_URI` is optional for local development. When configured, FlowLy caches normalized search results and track metadata in MongoDB.

## Flutter development

For the Android Emulator, the Flutter client uses `http://10.0.2.2:4000/api`, which maps to the development machine's localhost.

For production, put both services behind HTTPS and configure the appropriate network addresses. Only stream content that your application is authorized to access and distribute.
