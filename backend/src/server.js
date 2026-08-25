import 'dotenv/config';

import { createApp } from './app.js';
import { env } from './config/env.js';
import { connectMongo } from './db/mongo.js';
import { Song } from './models/song.js';
import { YouTubeProvider } from './providers/youtube_provider.js';
import { SongService } from './services/song_service.js';

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

    const provider = new YouTubeProvider({ apiKey: env.youtubeApiKey });
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
    });
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

start();
