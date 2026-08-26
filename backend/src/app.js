import cors from 'cors';
import express from 'express';

import { createHealthRouter } from './routes/health.js';
import { createSearchRouter } from './routes/search.js';
import { createSongsRouter } from './routes/songs.js';
import { createStreamRouter } from './routes/stream.js';

export function createApp({ corsOrigin, songService, provider }) {
  const app = express();
  app.use(cors({ origin: corsOrigin }));
  app.use(express.json());

  app.use('/health', createHealthRouter({ provider }));
  app.use('/api/search', createSearchRouter({ songService }));
  app.use('/api/trending', createTrendingRouter({ provider }));
  app.use('/api/songs', createSongsRouter({ songService }));
  app.use('/api/stream', createStreamRouter({ provider }));

  return app;
}

function createTrendingRouter({ provider }) {
  const router = express.Router();

  router.get('/', async (_req, res) => {
    try {
      res.json({ results: await provider.trending() });
    } catch (error) {
      console.error(error);
      res.status(502).json({ error: 'trending_failed', message: error.message });
    }
  });

  return router;
}
