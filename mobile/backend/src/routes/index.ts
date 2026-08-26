import { Router } from 'express';

import type { Environment } from '../config/environment.js';
import { healthRouter } from './health_routes.js';
import { createStravaRouter } from './strava_routes.js';

export function createApiRouter(
  environment: Environment,
): Router {
  const router = Router();

  router.use('/health', healthRouter);

  router.use(
    '/strava',
    createStravaRouter(environment),
  );

  return router;
}