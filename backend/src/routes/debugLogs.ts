import { Router } from "express";
import type { PrismaClient } from "../generated/prisma/client.js";

export function debugLogRoutes(prisma: PrismaClient): Router {
  const router = Router();

  // POST /debug-logs/:deviceId — upload debug log entries
  router.post("/:deviceId", async (req, res) => {
    const { deviceId } = req.params;
    const { entries } = req.body as {
      entries: { timestamp: string; kind: string; data: Record<string, string> }[];
    };

    if (!entries?.length) {
      res.status(400).json({ error: { code: "EMPTY_PAYLOAD", message: "No entries" } });
      return;
    }

    try {
      await prisma.debugLog.createMany({
        data: entries.map((e) => ({
          deviceId,
          timestamp: new Date(e.timestamp),
          kind: e.kind,
          data: e.data,
        })),
      });

      res.json({ ok: true, count: entries.length });
    } catch (err) {
      res.status(500).json({ error: { code: "LOG_UPLOAD_FAILED", message: String(err) } });
    }
  });

  // GET /debug-logs/:deviceId — retrieve debug logs
  router.get("/:deviceId", async (req, res) => {
    const { deviceId } = req.params;
    const limit = Math.min(parseInt(req.query["limit"] as string) || 100, 500);

    try {
      const logs = await prisma.debugLog.findMany({
        where: { deviceId },
        orderBy: { timestamp: "desc" },
        take: limit,
      });
      res.json({ logs });
    } catch (err) {
      res.status(500).json({ error: { code: "LOG_FETCH_FAILED", message: String(err) } });
    }
  });

  return router;
}
