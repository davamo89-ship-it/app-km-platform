import type {
  Request,
  Response,
} from 'express';

interface HealthResponse {
  status: 'ok';
  service: string;
  timestamp: string;
  uptimeSeconds: number;
}

export function getHealth(
  _request: Request,
  response: Response<HealthResponse>,
): void {
  response.status(200).json({
    status: 'ok',
    service: 'app-km-backend',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(
      process.uptime(),
    ),
  });
}