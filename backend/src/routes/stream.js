import { Router } from 'express';

async function proxyStream(req, res, streamUrl) {
  const headers = {};
  if (req.headers.range) headers.Range = req.headers.range;

  const response = await fetch(streamUrl, {
    method: req.method === 'HEAD' ? 'HEAD' : 'GET',
    headers,
    signal: AbortSignal.timeout(30_000),
  });

  if (!response.ok && response.status !== 206) {
    const body = await response.text().catch(() => '');
    throw new Error(`Shulker stream failed: ${response.status} ${body.slice(0, 200)}`);
  }

  res.status(response.status);
  for (const name of ['content-type', 'content-length', 'content-range', 'accept-ranges', 'etag']) {
    const value = response.headers.get(name);
    if (value) res.setHeader(name, value);
  }
  res.setHeader('Cache-Control', 'no-store');

  if (req.method === 'HEAD' || !response.body) {
    res.end();
    return;
  }

  for await (const chunk of response.body) {
    if (res.destroyed) break;
    if (!res.write(chunk)) await new Promise((resolve) => res.once('drain', resolve));
  }
  res.end();
}

export function createStreamRouter({ provider }) {
  const router = Router();

  router.get('/:videoId', async (req, res) => {
    try {
      const stream = await provider.getStream(req.params.videoId);
      if (stream.proxy) {
        await proxyStream(req, res, stream.url);
        return;
      }
      res.setHeader('Cache-Control', 'no-store');
      res.redirect(302, stream.url);
    } catch (error) {
      console.error(error);
      if (!res.headersSent) res.status(502).json({ error: 'stream_failed', message: error.message });
      else res.destroy(error);
    }
  });

  router.head('/:videoId', async (req, res) => {
    try {
      const stream = await provider.getStream(req.params.videoId);
      if (stream.proxy) {
        await proxyStream(req, res, stream.url);
        return;
      }
      res.set('Location', stream.url).status(302).end();
    } catch (error) {
      res.status(502).json({ error: 'stream_failed', message: error.message });
    }
  });

  return router;
}
