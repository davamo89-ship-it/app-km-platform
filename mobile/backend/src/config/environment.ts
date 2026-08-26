type NodeEnvironment = 'development' | 'test' | 'production';

interface Environment {
  nodeEnv: NodeEnvironment;
  port: number;
  strava: {
    clientId: string;
    clientSecret: string;
    redirectUri: string;
  };
  allowedOrigins: string[];
}

function readRequiredEnvironmentVariable(
  name: string,
): string {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new Error(
      `La variable de entorno ${name} no está configurada.`,
    );
  }

  return value;
}

function readOptionalEnvironmentVariable(
  name: string,
  fallback: string,
): string {
  const value = process.env[name]?.trim();

  return value || fallback;
}

function parseNodeEnvironment(
  value: string,
): NodeEnvironment {
  if (
    value === 'development' ||
    value === 'test' ||
    value === 'production'
  ) {
    return value;
  }

  throw new Error(
    `NODE_ENV tiene un valor inválido: ${value}.`,
  );
}

function parsePort(value: string): number {
  const port = Number.parseInt(value, 10);

  if (
    !Number.isInteger(port) ||
    port < 1 ||
    port > 65535
  ) {
    throw new Error(
      `PORT tiene un valor inválido: ${value}.`,
    );
  }

  return port;
}

function parseAllowedOrigins(
  value: string,
): string[] {
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

export function loadEnvironment(): Environment {
  const nodeEnv = parseNodeEnvironment(
    readOptionalEnvironmentVariable(
      'NODE_ENV',
      'development',
    ),
  );

  const port = parsePort(
    readOptionalEnvironmentVariable(
      'PORT',
      '3000',
    ),
  );

  const redirectUri =
      readOptionalEnvironmentVariable(
        'STRAVA_REDIRECT_URI',
        'appkm://strava-callback',
      );

  const allowedOrigins = parseAllowedOrigins(
    readOptionalEnvironmentVariable(
      'ALLOWED_ORIGINS',
      'http://localhost:3000',
    ),
  );

  return {
    nodeEnv,
    port,
    strava: {
      clientId:
          readRequiredEnvironmentVariable(
            'STRAVA_CLIENT_ID',
          ),
      clientSecret:
          readRequiredEnvironmentVariable(
            'STRAVA_CLIENT_SECRET',
          ),
      redirectUri,
    },
    allowedOrigins,
  };
}

export type { Environment };