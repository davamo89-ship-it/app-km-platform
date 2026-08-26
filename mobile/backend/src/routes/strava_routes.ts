import { Router } from 'express';

import type { Environment } from '../config/environment.js';
import { StravaOAuthController } from '../controllers/strava_oauth_controller.js';
import { StravaOAuthService } from '../services/strava/strava_oauth_service.js';

export function createStravaRouter(
  environment: Environment,
): Router {
  const router = Router();

  const oauthService =
    new StravaOAuthService(environment);

  const oauthController =
    new StravaOAuthController(oauthService);

  router.get('/callback', (request, response) => {
    const code = request.query.code;
    const scope = request.query.scope;
    const state = request.query.state;
    const error = request.query.error;

    const parameters = new URLSearchParams();

    if (typeof code === 'string') {
      parameters.set('code', code);
    }

    if (typeof scope === 'string') {
      parameters.set('scope', scope);
    }

    if (typeof state === 'string') {
      parameters.set('state', state);
    }

    if (typeof error === 'string') {
      parameters.set('error', error);
    }

    const redirectUri =
      `appkm://strava-callback?${parameters.toString()}`;

    response.redirect(302, redirectUri);
  });

  router.post(
    '/oauth/exchange',
    oauthController.exchangeAuthorizationCode,
  );

  router.post(
    '/oauth/refresh',
    oauthController.refreshAccessToken,
  );

  return router;
}