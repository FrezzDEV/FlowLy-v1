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

### Endpoints

- `GET /health`
- `GET /api/search?q=...`
- `GET /api/songs/:videoId`
- `GET /api/stream/:videoId`

`YOUTUBE_API_KEY` is optional. When it is present, `/api/search` uses the YouTube Data API `search.list`; otherwise the backend falls back to `youtubei.js` search. The stream endpoint resolves an audio-only format with `youtubei.js` and returns an HTTP redirect to the resolved media URL.

`MONGODB_URI` is optional for the first run. When configured, search results and song metadata are cached in MongoDB.

For production, put the API behind HTTPS and configure `CORS_ORIGIN` to the Flutter app's allowed web origin(s).

## Legal / platform note

Only stream content that your application is authorized to access and distribute. YouTube Data API is used for metadata/search; the application must follow the applicable YouTube and content-owner terms.
