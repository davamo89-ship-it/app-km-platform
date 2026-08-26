import type {
  NextFunction,
  Request,
  Response,
} from 'express';

import { AppError } from '../errors/app_error.js';

export function notFoundMiddleware(
  request: Request,
  _response: Response,
  next: NextFunction,
): void {
  next(
    new AppError({
      statusCode: 404,
      code: 'route_not_found',
      message:
          `No existe la ruta ${request.method} ${request.originalUrl}.`,
    }),
  );
}