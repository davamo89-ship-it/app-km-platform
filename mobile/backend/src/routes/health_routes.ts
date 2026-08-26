import { Router } from 'express';

import { getHealth } from '../controllers/health_controller.js';

export const healthRouter = Router();

healthRouter.get('/', getHealth);