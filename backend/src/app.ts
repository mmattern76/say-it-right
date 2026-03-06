import express from "express";
import cors from "cors";
import type { PrismaClient } from "./generated/prisma/client.js";
import { requireApiKey } from "./middleware/auth.js";
import { errorHandler } from "./middleware/errorHandler.js";
import healthRouter from "./routes/health.js";
import { syncRoutes } from "./routes/sync.js";
import { modelRoutes } from "./routes/models.js";
import { debugLogRoutes } from "./routes/debugLogs.js";

export function createApp(prisma: PrismaClient): express.Express {
  const app = express();

  // Middleware
  app.use(cors());
  app.use(express.json({ limit: "2mb" }));

  // Public routes (no auth)
  app.use("/api/v1", healthRouter);

  // Authenticated routes
  app.use("/api/v1/sync", requireApiKey, syncRoutes(prisma));
  app.use("/api/v1/models", requireApiKey, modelRoutes());
  app.use("/api/v1/debug-logs", requireApiKey, debugLogRoutes(prisma));

  // Error handler
  app.use(errorHandler);

  return app;
}
