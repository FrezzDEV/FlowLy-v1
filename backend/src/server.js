import 'dotenv/config';

import { createApp } from './app.js';
import { env } from './config/env.js';
import { connectMongo } from './db/mongo.js';
import { Song } from './models/song.js';
import { ShulkerProvider } from './providers/shulker_provider.js';
import { YouTubeProvider } from './providers/youtube_provider.js';
import { SongService } from './services/song_service.js';

class FallbackProvider {
  constructor(primary, fallback) {
    this.primary = primary;
    this.fallback = fallback;
  }

  async health() {
    const primary = await this.primary.health();
    if (primary.ok || !this.fallback) return primary;
    const fallback = await this.fallback.health();
    return {
      ok: fallback.ok,
      provider: 'shulker+youtube-fallback',
      primary,
      fallback,
    };
  }

  async run(primaryMethod, ...args) {
    try {
      return await this.primary[primaryMethod](...args);
    } catch (error) {
      if (!this.fallback) throw error;
      console.warn(`Shulker ${primaryMethod} failed; using YouTube fallback: ${error.message}`);
      return this.fallback[primaryMethod](...args);
    }
  }

  search(query) {
    return this.run('search', query);
  }

  trending() {
    return this.run('trending');
  }

  getSong(videoId) {
    return this.run('getSong', videoId);
  }

  getStream(videoId) {
    return this.run('getStream', videoId);
  }
}

async function start() {
  try {
    if (env.mongoUri) {
      try {
        await connectMongo(env.mongoUri);
        console.log('MongoDB connected');
      } catch (error) {
        console.warn(`MongoDB unavailable: ${error.message}`);
      }
    }

    const shulkerProvider = new ShulkerProvider({
      baseUrl: env.shulkerApiUrl,
      timeoutMs: env.shulkerTimeoutMs,
    });

    const youtubeFallback = env.shulkerFallbackYoutube
      ? new YouTubeProvider({
          apiKey: env.youtubeApiKey,
          ytDlpPath: env.ytDlpPath,
          preferYtDlp: env.preferYtDlp,
        })
      : null;

    const provider = new FallbackProvider(shulkerProvider, youtubeFallback);

    const songService = new SongService({
      provider,
      songModel: env.mongoUri ? Song : null,
    });

    const app = createApp({
      corsOrigin: env.corsOrigin,
      songService,
      provider,
    });

    app.listen(env.port, () => {
      console.log(`FlowLy API listening on http://localhost:${env.port}`);
      console.log(`Music provider: Shulker @ ${env.shulkerApiUrl}`);
      if (youtubeFallback) console.log('YouTube fallback: enabled');
    });
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

start();
