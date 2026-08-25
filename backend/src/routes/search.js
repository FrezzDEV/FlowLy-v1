import { Router } from 'express';

export function createSearchRouter({ songService }) {
  const router = Router();

  router.get('/', async (req, res) => {
    const query = String(req.query.q ?? '').trim();
    if (!query) return res.status(400).json({ error: 'q is required' });

    try {
      res.json({ query, results: await songService.search(query) });
    } catch (error) {
      console.error(error);
      res.status(502).json({ error: 'search_failed', message: error.message });
    }
  });

  return router;
}
