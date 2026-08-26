import { Router } from 'express';

export function createHealthRouter({ provider } = {}) {
  const router = Router();

  router.get('/', async (_req, res) => {
    const providerHealth = provider?.health
      ? await provider.health()
      : { ok: false, ytDlp: false };

    res.status(providerHealth.ok ? 200 : 503).json({
      ok: providerHealth.ok,
      service: 'flowly-backend',
      provider: providerHealth,
    });
  });

  return router;
}
