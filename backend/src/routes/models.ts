import { Router } from "express";
import Anthropic from "@anthropic-ai/sdk";

let cachedModels: { id: string; displayName: string; createdAt: string }[] = [];
let cacheTimestamp = 0;
const CACHE_TTL_MS = 3600_000; // 1 hour

export function modelRoutes(): Router {
  const router = Router();

  // GET /models — returns available Anthropic models
  router.get("/", async (_req, res) => {
    try {
      const now = Date.now();
      if (cachedModels.length > 0 && now - cacheTimestamp < CACHE_TTL_MS) {
        res.json({ models: cachedModels, cached: true });
        return;
      }

      const anthropic = new Anthropic();
      const response = await anthropic.models.list({ limit: 100 });

      cachedModels = response.data
        .filter((m) => m.type === "model" && m.id.startsWith("claude-"))
        .map((m) => ({
          id: m.id,
          displayName: m.display_name,
          createdAt: m.created_at,
        }))
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt));

      cacheTimestamp = now;
      res.json({ models: cachedModels, cached: false });
    } catch (err) {
      // Return cached data if available, even if stale
      if (cachedModels.length > 0) {
        res.json({ models: cachedModels, cached: true, stale: true });
        return;
      }
      res.status(502).json({
        error: { code: "MODELS_FETCH_FAILED", message: String(err) },
      });
    }
  });

  return router;
}
