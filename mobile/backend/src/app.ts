import cors from 'cors';
import express from 'express';
import helmet from 'helmet';

import type { Environment } from './config/environment.js';
import { AppError } from './errors/app_error.js';
import { errorMiddleware } from './middleware/error_middleware.js';
import { notFoundMiddleware } from './middleware/not_found_middleware.js';
import { createApiRouter } from './routes/index.js';

export function createApp(
  environment: Environment,
): express.Express {
  const app = express();

  app.disable('x-powered-by');

  app.use(helmet());

  app.use(
    cors({
      origin(origin, callback) {
        if (
          !origin ||
          environment.allowedOrigins.includes(
            origin,
          )
        ) {
          callback(null, true);
          return;
        }

        callback(
          new AppError({
            statusCode: 403,
            code: 'origin_not_allowed',
            message:
                `El origen ${origin} no está permitido.`,
          }),
        );
      },
    }),
  );

  app.use(
    express.json({
      limit: '100kb',
    }),
  );

  app.use(
    express.urlencoded({
      extended: false,
      limit: '100kb',
    }),
  );

  app.get('/', (_request, response) => {
    response.status(200).json({
      service: 'App KM Backend',
      status: 'running',
    });
  });

  app.use(
    '/api/v1',
    createApiRouter(environment),
  );

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}