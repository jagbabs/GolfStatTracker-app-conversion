import express, { Request, Response, NextFunction } from 'express';
import session from 'express-session';
import MemoryStore from 'memorystore';
import { Server } from 'http';
import { api } from './routes';
import { setupVite, serveStatic, log } from './vite';

async function main(): Promise<Server> {
  const app = express();
  const server = new Server(app);

  // Add session management
  const MemoryStoreSession = MemoryStore(session);
  app.use(
    session({
      secret: process.env.SESSION_SECRET || 'sample-secret',
      resave: false,
      saveUninitialized: false,
      cookie: { secure: process.env.NODE_ENV === 'production' },
      store: new MemoryStoreSession({
        checkPeriod: 86400000, // 24h
      }),
    })
  );
  
  // JSON parsing
  app.use(express.json());

  // Register API routes
  app.use('/api', api);

  // Global error handler
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    console.error(err.stack);
    res.status(500).json({ error: err.message || 'Something went wrong!' });
  });

  // Let Vite handle everything else (during development)
  if (process.env.NODE_ENV !== 'production') {
    await setupVite(app, server);
  } else {
    serveStatic(app);
  }

  const port = process.env.PORT || 5000;
  server.listen(port, () => {
    log(`serving on port ${port}`);
  });

  return server;
}

// Automatically run the main function in development
main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

export { main };