import type {
  NextFunction,
  Request,
  Response,
} from 'express';

import { AppError } from '../errors/app_error.js';

interface ErrorResponseBody {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export function errorMiddleware(
  error: unknown,
  _request: Request,
  response: Response<ErrorResponseBody>,
  _next: NextFunction,
): void {
  if (error instanceof AppError) {
    response.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        ...(error.details !== undefined
          ? { details: error.details }
          : {}),
      },
    });

    return;
  }

  console.error('Error no controlado:', error);

  response.status(500).json({
    error: {
      code: 'internal_server_error',
      message:
          'Ocurrió un error interno en el servidor.',
    },
  });
}