# FlowLy backend

Node.js + Express API for search, metadata and audio streaming.

## Run

```bash
cd backend
npm install
cp .env.example .env
npm start
```

The API listens on `http://localhost:4000` by default.

## Endpoints

- `GET /health`
- `GET /api/search?q=...`
- `GET /api/songs/:videoId`
- `GET /api/stream/:videoId`

## Media provider

FlowLy separates metadata/search from audio delivery.

- Search uses YouTube Data API when `YOUTUBE_API_KEY` is configured; otherwise it uses `youtubei.js`.
- Audio streaming prefers `yt-dlp` and falls back to `youtubei.js` when `PREFER_YTDLP=true`.
- `YTDLP_PATH` controls the executable name/path; default is `yt-dlp`.

The `yt-dlp` approach is modeled after the architecture used by the open-source `0xrama/yt-api` project, which uses InnerTube for metadata/search and yt-dlp for actual audio delivery. The `guilhermehfr/just-audio` project is another useful reference for a later HLS/FFmpeg/S3 production architecture.

### Installing yt-dlp

Install a current `yt-dlp` binary on the backend host and make sure it is available on `PATH`, or set `YTDLP_PATH` to its full path.

Recent yt-dlp releases may require a supported JavaScript runtime plus the yt-dlp EJS challenge-solver components for YouTube extraction. See the upstream yt-dlp EJS setup guide when an extraction error mentions JavaScript challenges.

## MongoDB

`MONGODB_URI` is optional for the first run. When configured, search results and song metadata are cached in MongoDB.

## Flutter development

For the Android Emulator, the Flutter client uses `http://10.0.2.2:4000/api`, which maps to the development machine's localhost.

For production, put the API behind HTTPS and configure `CORS_ORIGIN` to the app's allowed web origin(s).

## Legal / platform note

Only stream content that your application is authorized to access and distribute. The provider layer is intentionally replaceable so FlowLy can use licensed or first-party media sources without changing the Flutter API contract.
