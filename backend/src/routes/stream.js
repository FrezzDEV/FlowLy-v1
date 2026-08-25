import { Router } from 'express';

export function createStreamRouter({ provider }) {
  const router = Router();

  router.get('/:videoId', async (req, res) => {
    try {
      const stream = await provider.getStream(req.params.videoId);
      res.setHeader('Cache-Control', 'no-store');
      res.redirect(302, stream.url);
    } catch (error) {
      console.error(error);
      res.status(502).json({ error: 'stream_failed', message: error.message });
    }
  });

  return router;
}
