import { Router } from 'express';

export function createSongsRouter({ songService }) {
  const router = Router();

  router.get('/:videoId', async (req, res) => {
    try {
      res.json(await songService.getByVideoId(req.params.videoId));
    } catch (error) {
      res.status(404).json({ error: 'song_not_found', message: error.message });
    }
  });

  return router;
}
