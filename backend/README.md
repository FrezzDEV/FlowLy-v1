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

```bash
cd backend
docker compose up --build
```

This starts the API, MongoDB, `yt-dlp`, and FFmpeg in a reproducible stack.

## Endpoints

- `GET /health` — backend + media-provider health.
- `GET /api/search?q=...` — search tracks.
- `GET /api/songs/:videoId` — track metadata.
- `GET /api/stream/:videoId` — resolve an audio stream and redirect to it.

## Media provider

FlowLy separates metadata/search from audio delivery.

- Search uses YouTube Data API when `YOUTUBE_API_KEY` is configured; otherwise it uses `youtubei.js`.
- Audio streaming prefers `yt-dlp` and falls back to `youtubei.js` when `PREFER_YTDLP=true`.
- `YTDLP_PATH` controls the executable name/path; default is `yt-dlp`.
- The provider has an explicit health check so a missing `yt-dlp` binary is visible at `/health`.

The provider layout follows the architecture seen in open-source YouTube API projects such as `0xrama/yt-api`: metadata/search stays separate from actual media URL resolution. `guilhermehfr/just-audio` is a useful future reference if FlowLy later needs HLS/FFmpeg/S3-style delivery instead of direct URL redirects.

### yt-dlp / YouTube extraction

Use a current `yt-dlp` build. Recent YouTube extraction flows can require a supported JavaScript runtime plus the `yt-dlp-ejs` challenge-solver components. The Docker image installs `yt-dlp` and FFmpeg; if a deployment reports an EJS/JavaScript challenge error, add the runtime/components recommended by the current upstream `yt-dlp` documentation.

## MongoDB

`MONGODB_URI` is optional for a local first run. When configured, search results and song metadata are cached in MongoDB.

## Flutter development

For the Android Emulator, the Flutter client uses `http://10.0.2.2:4000/api`, which maps to the development machine's localhost.

For production, put the API behind HTTPS and configure `CORS_ORIGIN` to the app's allowed web origin(s).

## Legal / platform note

Only stream content that your application is authorized to access and distribute. The provider layer is intentionally replaceable so FlowLy can use licensed or first-party media sources without changing the Flutter API contract.
