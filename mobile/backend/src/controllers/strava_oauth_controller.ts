import type {
  NextFunction,
  Request,
  Response,
} from 'express';

import { AppError } from '../errors/app_error.js';
import type { StravaOAuthService } from '../services/strava/strava_oauth_service.js';
import type {
  StravaAuthorizationTokenResponse,
  StravaRefreshTokenResponse,
} from '../services/strava/strava_types.js';

interface ExchangeRequestBody {
  code?: unknown;
}

interface RefreshRequestBody {
  refreshToken?: unknown;
  refresh_token?: unknown;
}

export class StravaOAuthController {
  constructor(
    oauthService: StravaOAuthService,
  ) {
    this.oauthService = oauthService;
  }

  private readonly oauthService:
    StravaOAuthService;

  exchangeAuthorizationCode = async (
    request: Request<
      Record<string, never>,
      StravaAuthorizationTokenResponse,
      ExchangeRequestBody
    >,
    response:
      Response<StravaAuthorizationTokenResponse>,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const code = requireNonEmptyString(
        request.body.code,
        'code',
      );

      const token =
        await this.oauthService
          .exchangeAuthorizationCode(code);

      response.status(200).json(token);
    } catch (error) {
      next(error);
    }
  };

  refreshAccessToken = async (
    request: Request<
      Record<string, never>,
      StravaRefreshTokenResponse,
      RefreshRequestBody
    >,
    response:
      Response<StravaRefreshTokenResponse>,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const candidate =
        request.body.refreshToken ??
        request.body.refresh_token;

      const refreshToken =
        requireNonEmptyString(
          candidate,
          'refreshToken',
        );

      const token =
        await this.oauthService
          .refreshAccessToken(refreshToken);

      response.status(200).json(token);
    } catch (error) {
      next(error);
    }
  };
}

function requireNonEmptyString(
  value: unknown,
  field: string,
): string {
  if (
    typeof value !== 'string' ||
    value.trim().length === 0
  ) {
    throw new AppError({
      statusCode: 400,
      code: 'invalid_request',
      message:
          `El campo ${field} es obligatorio.`,
      details: {
        field,
      },
    });
  }

  return value.trim();
}