import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { ZodError } from 'zod';

import { HttpError } from './middleware/errors';
import { profileRoutes } from './routes/profile.routes';

export const app = express();

app.use(helmet());
app.use(cors()); // tighten to your real origins before deploying
app.use(express.json({ limit: '1mb' }));
app.use(
  rateLimit({
    windowMs: 60_000,
    limit: 120,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.get('/api/v1/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

app.use('/api/v1/profile', profileRoutes);

// Every failure uses one shape: { error: { code, message } }
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: { code: 'not_found', message: 'Route not found' } });
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof HttpError) {
    res.status(err.status).json({ error: { code: err.code, message: err.message } });
    return;
  }
  if (err instanceof ZodError) {
    const message = err.issues
      .map((i) => `${i.path.join('.') || 'body'}: ${i.message}`)
      .join('; ');
    res.status(400).json({ error: { code: 'validation_error', message } });
    return;
  }
  if ((err as { type?: string })?.type === 'entity.parse.failed') {
    res.status(400).json({ error: { code: 'bad_json', message: 'Request body is not valid JSON' } });
    return;
  }
  console.error(err);
  res.status(500).json({ error: { code: 'internal_error', message: 'Something went wrong' } });
});