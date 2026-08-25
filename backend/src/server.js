import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import mongoose from 'mongoose';
import { Innertube } from 'youtubei.js';

const app = express();
const port = Number(process.env.PORT || 4000);
const origin = process.env.CORS_ORIGIN || '*';

app.use(cors({ origin }));
app.use(express.json());

const SongSchema = new mongoose.Schema(
  {
    videoId: { type: String, unique: true, index: true },
    title: String,
    artist: String,
    thumbnail: String,
    durationSeconds: Number,
  },
  { timestamps: true },
);
const Song = mongoose.models.Song || mongoose.model('Song', SongSchema);

let youtubePromise;
function youtube() {
  youtubePromise ??= Innertube.create();
  return youtubePromise;
}

async function searchYoutubeApi(query) {
  const key = process.env.YOUTUBE_API_KEY;
  if (!key) return null;

  const url = new URL('https://www.googleapis.com/youtube/v3/search');
  url.searchParams.set('part', 'snippet');
  url.searchParams.set('q', query);
  url.searchParams.set('type', 'video');
  url.searchParams.set('maxResults', '12');
  url.searchParams.set('key', key);

  const response = await fetch(url);
  if (!response.ok) throw new Error(`YouTube Data API failed: ${response.status}`);
  const data = await response.json();
  return data.items.map((item) => ({
    videoId: item.id.videoId,
    title: item.snippet.title,
    artist: item.snippet.channelTitle,
    thumbnail: item.snippet.thumbnails?.high?.url ?? item.snippet.thumbnails?.default?.url,
  }));
}

async function searchWithYoutubeJs(query) {
  const yt = await youtube();
  const result = await yt.search(query, { type: 'video' });
  return (result.results ?? []).filter((item) => item.video_id).slice(0, 12).map((item) => ({
    videoId: item.video_id,
    title: item.title ?? 'Unknown track',
    artist: item.author?.name ?? item.owner?.name ?? 'Unknown artist',
    thumbnail: item.best_thumbnail?.url ?? item.thumbnails?.[0]?.url,
    durationSeconds: item.duration?.seconds,
  }));
}

async function getStreamUrl(videoId) {
  const yt = await youtube();
  const info = await yt.getBasicInfo(videoId);
  const format = info.chooseFormat({ type: 'audio', quality: 'best' });
  if (!format) throw new Error('No compatible audio format found');

  const url = typeof format.decipher === 'function'
    ? format.decipher(yt.session.player)
    : format.url;
  if (!url) throw new Error('Unable to resolve audio stream URL');
  return { url: String(url), mimeType: format.mime_type, bitrate: format.bitrate };
}

app.get('/health', (_req, res) => res.json({ ok: true, service: 'flowly-backend' }));

app.get('/api/search', async (req, res) => {
  const query = String(req.query.q ?? '').trim();
  if (!query) return res.status(400).json({ error: 'q is required' });

  try {
    const apiResults = await searchYoutubeApi(query);
    const results = apiResults ?? await searchWithYoutubeJs(query);

    if (results.length) {
      await Song.bulkWrite(
        results.map((song) => ({
          updateOne: { filter: { videoId: song.videoId }, update: { $set: song }, upsert: true },
        })),
        { ordered: false },
      ).catch(() => {});
    }

    res.json({ query, results });
  } catch (error) {
    console.error(error);
    res.status(502).json({ error: 'search_failed', message: error.message });
  }
});

app.get('/api/songs/:videoId', async (req, res) => {
  try {
    const song = await Song.findOne({ videoId: req.params.videoId }).lean();
    if (song) return res.json(song);

    const yt = await youtube();
    const info = await yt.getBasicInfo(req.params.videoId);
    const result = {
      videoId: req.params.videoId,
      title: info.basic_info?.title ?? 'Unknown track',
      artist: info.basic_info?.author ?? 'Unknown artist',
      thumbnail: info.basic_info?.thumbnail?.[0]?.url,
      durationSeconds: info.basic_info?.duration,
    };
    await Song.findOneAndUpdate({ videoId: result.videoId }, result, { upsert: true, new: true });
    res.json(result);
  } catch (error) {
    res.status(404).json({ error: 'song_not_found', message: error.message });
  }
});

app.get('/api/stream/:videoId', async (req, res) => {
  try {
    const stream = await getStreamUrl(req.params.videoId);
    res.setHeader('Cache-Control', 'no-store');
    res.redirect(302, stream.url);
  } catch (error) {
    console.error(error);
    res.status(502).json({ error: 'stream_failed', message: error.message });
  }
});

async function start() {
  if (process.env.MONGODB_URI) {
    try {
      await mongoose.connect(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 5000 });
      console.log('MongoDB connected');
    } catch (error) {
      console.warn(`MongoDB unavailable: ${error.message}`);
    }
  }

  app.listen(port, () => console.log(`FlowLy API listening on http://localhost:${port}`));
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
