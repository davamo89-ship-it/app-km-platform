import { createServer } from 'node:http';

import { createApp } from './app.js';
import { loadEnvironment } from './config/environment.js';

function startServer(): void {
  const environment = loadEnvironment();
  const app = createApp(environment);
  const server = createServer(app);

  server.listen(environment.port, () => {
    console.log(
      [
        'App KM Backend iniciado.',
        `Entorno: ${environment.nodeEnv}`,
        `Puerto: ${environment.port}`,
        `Health: http://localhost:${environment.port}/api/v1/health`,
      ].join('\n'),
    );
  });

  function shutdown(signal: string): void {
    console.log(
      `${signal} recibido. Cerrando servidor...`,
    );

    server.close((error) => {
      if (error) {
        console.error(
          'No fue posible cerrar el servidor:',
          error,
        );

        process.exitCode = 1;
        return;
      }

      console.log(
        'Servidor cerrado correctamente.',
      );

      process.exitCode = 0;
    });
  }

  process.on('SIGTERM', () => {
    shutdown('SIGTERM');
  });

  process.on('SIGINT', () => {
    shutdown('SIGINT');
  });
}

try {
  startServer();
} catch (error) {
  console.error(
    'No fue posible iniciar App KM Backend:',
    error,
  );

  process.exitCode = 1;
}