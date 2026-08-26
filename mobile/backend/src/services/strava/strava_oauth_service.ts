import type { Environment } from '../../config/environment.js';
import { AppError } from '../../errors/app_error.js';
import type {
  StravaApiErrorResponse,
  StravaAuthorizationTokenResponse,
  StravaRefreshTokenResponse,
} from './strava_types.js';

const STRAVA_TOKEN_URL =
  'https://www.strava.com/oauth/token';

const REQUEST_TIMEOUT_MILLISECONDS = 15_000;

type JsonRecord = Record<string, unknown>;

export class StravaOAuthService {
  constructor(
    environment: Environment,
  ) {
    this.clientId = environment.strava.clientId;
    this.clientSecret =
      environment.strava.clientSecret;
  }

  private readonly clientId: string;
  private readonly clientSecret: string;

  async exchangeAuthorizationCode(
    code: string,
  ): Promise<StravaAuthorizationTokenResponse> {
    const response = await this.requestToken({
      client_id: this.clientId,
      client_secret: this.clientSecret,
      code,
      grant_type: 'authorization_code',
    });

    return parseAuthorizationTokenResponse(
      response,
    );
  }

  async refreshAccessToken(
    refreshToken: string,
  ): Promise<StravaRefreshTokenResponse> {
    const response = await this.requestToken({
      client_id: this.clientId,
      client_secret: this.clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    });

    return parseRefreshTokenResponse(response);
  }

  private async requestToken(
    parameters: Record<string, string>,
  ): Promise<unknown> {
    let response: Response;

    try {
      response = await fetch(
        STRAVA_TOKEN_URL,
        {
          method: 'POST',
          headers: {
            accept: 'application/json',
            'content-type':
              'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams(parameters),
          signal: AbortSignal.timeout(
            REQUEST_TIMEOUT_MILLISECONDS,
          ),
        },
      );
    } catch (error) {
      if (
        error instanceof Error &&
        error.name === 'TimeoutError'
      ) {
        throw new AppError({
          statusCode: 504,
          code: 'strava_timeout',
          message:
              'Strava tardó demasiado en responder.',
          cause: error,
        });
      }

      throw new AppError({
        statusCode: 502,
        code: 'strava_unavailable',
        message:
            'No fue posible comunicarse con Strava.',
        cause: error,
      });
    }

    const responseBody =
      await readJsonResponse(response);

    if (!response.ok) {
      const stravaError =
        parseStravaErrorResponse(responseBody);

      throw new AppError({
        statusCode: mapStravaStatusCode(
          response.status,
        ),
        code: 'strava_oauth_error',
        message:
            stravaError.message ??
            'Strava rechazó la solicitud OAuth.',
        details: {
          stravaStatusCode: response.status,
          errors: stravaError.errors ?? [],
        },
      });
    }

    return responseBody;
  }
}

async function readJsonResponse(
  response: Response,
): Promise<unknown> {
  try {
    return await response.json();
  } catch (error) {
    throw new AppError({
      statusCode: 502,
      code: 'invalid_strava_response',
      message:
          'Strava devolvió una respuesta inválida.',
      cause: error,
    });
  }
}

function parseStravaErrorResponse(
  value: unknown,
): StravaApiErrorResponse {
  if (!isJsonRecord(value)) {
    return {};
  }

  const errorResponse: StravaApiErrorResponse = {};

  if (typeof value.message === 'string') {
    errorResponse.message = value.message;
  }

  if (Array.isArray(value.errors)) {
    errorResponse.errors = value.errors
      .filter(isJsonRecord)
      .map((item) => ({
        ...(typeof item.resource === 'string'
          ? { resource: item.resource }
          : {}),
        ...(typeof item.field === 'string'
          ? { field: item.field }
          : {}),
        ...(typeof item.code === 'string'
          ? { code: item.code }
          : {}),
      }));
  }

  return errorResponse;
}

function parseAuthorizationTokenResponse(
  value: unknown,
): StravaAuthorizationTokenResponse {
  const record = requireJsonRecord(
    value,
    'la respuesta de autorización',
  );

  const athleteRecord = requireJsonRecord(
    record.athlete,
    'el atleta de Strava',
  );

  return {
    token_type: requireString(
      record,
      'token_type',
    ),
    expires_at: requireNumber(
      record,
      'expires_at',
    ),
    expires_in: requireNumber(
      record,
      'expires_in',
    ),
    refresh_token: requireString(
      record,
      'refresh_token',
    ),
    access_token: requireString(
      record,
      'access_token',
    ),
    athlete: {
      id: requireNumber(
        athleteRecord,
        'id',
      ),
      username: optionalNullableString(
        athleteRecord,
        'username',
      ),
      resource_state: optionalNumber(
        athleteRecord,
        'resource_state',
        0,
      ),
      firstname: optionalString(
        athleteRecord,
        'firstname',
      ),
      lastname: optionalString(
        athleteRecord,
        'lastname',
      ),
      bio: optionalString(
        athleteRecord,
        'bio',
      ),
      city: optionalString(
        athleteRecord,
        'city',
      ),
      state: optionalString(
        athleteRecord,
        'state',
      ),
      country: optionalString(
        athleteRecord,
        'country',
      ),
      sex: optionalNullableString(
        athleteRecord,
        'sex',
      ),
      premium: optionalBoolean(
        athleteRecord,
        'premium',
      ),
      summit: optionalBoolean(
        athleteRecord,
        'summit',
      ),
      created_at: optionalString(
        athleteRecord,
        'created_at',
      ),
      updated_at: optionalString(
        athleteRecord,
        'updated_at',
      ),
      badge_type_id: optionalNumber(
        athleteRecord,
        'badge_type_id',
        0,
      ),
      weight: optionalNumber(
        athleteRecord,
        'weight',
        0,
      ),
      profile_medium: optionalString(
        athleteRecord,
        'profile_medium',
      ),
      profile: optionalString(
        athleteRecord,
        'profile',
      ),
    },
  };
}

function parseRefreshTokenResponse(
  value: unknown,
): StravaRefreshTokenResponse {
  const record = requireJsonRecord(
    value,
    'la respuesta de renovación',
  );

  return {
    token_type: requireString(
      record,
      'token_type',
    ),
    expires_at: requireNumber(
      record,
      'expires_at',
    ),
    expires_in: requireNumber(
      record,
      'expires_in',
    ),
    refresh_token: requireString(
      record,
      'refresh_token',
    ),
    access_token: requireString(
      record,
      'access_token',
    ),
  };
}

function requireJsonRecord(
  value: unknown,
  description: string,
): JsonRecord {
  if (!isJsonRecord(value)) {
    throw invalidResponseError(description);
  }

  return value;
}

function requireString(
  record: JsonRecord,
  field: string,
): string {
  const value = record[field];

  if (
    typeof value !== 'string' ||
    value.length === 0
  ) {
    throw invalidResponseError(field);
  }

  return value;
}

function requireNumber(
  record: JsonRecord,
  field: string,
): number {
  const value = record[field];

  if (
    typeof value !== 'number' ||
    !Number.isFinite(value)
  ) {
    throw invalidResponseError(field);
  }

  return value;
}

function optionalString(
  record: JsonRecord,
  field: string,
): string {
  const value = record[field];

  return typeof value === 'string' ? value : '';
}

function optionalNullableString(
  record: JsonRecord,
  field: string,
): string | null {
  const value = record[field];

  return typeof value === 'string' ? value : null;
}

function optionalNumber(
  record: JsonRecord,
  field: string,
  fallback: number,
): number {
  const value = record[field];

  return typeof value === 'number' &&
    Number.isFinite(value)
    ? value
    : fallback;
}

function optionalBoolean(
  record: JsonRecord,
  field: string,
): boolean {
  return record[field] === true;
}

function isJsonRecord(
  value: unknown,
): value is JsonRecord {
  return (
    typeof value === 'object' &&
    value !== null &&
    !Array.isArray(value)
  );
}

function invalidResponseError(
  field: string,
): AppError {
  return new AppError({
    statusCode: 502,
    code: 'invalid_strava_response',
    message:
        `La respuesta de Strava no contiene correctamente ${field}.`,
  });
}

function mapStravaStatusCode(
  statusCode: number,
): number {
  if (
    statusCode === 400 ||
    statusCode === 401 ||
    statusCode === 403
  ) {
    return 401;
  }

  if (statusCode === 429) {
    return 429;
  }

  return 502;
}