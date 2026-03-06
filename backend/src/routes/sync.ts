import { Router } from "express";
import type { PrismaClient } from "../generated/prisma/client.js";

export function syncRoutes(prisma: PrismaClient): Router {
  const router = Router();

  // Pull: get all data newer than client's last sync timestamp
  router.get("/:deviceId", async (req, res) => {
    const { deviceId } = req.params;
    const since = req.query["since"] as string | undefined;
    const sinceDate = since ? new Date(since) : new Date(0);

    try {
      const [profile, sessions, seenTexts] = await Promise.all([
        prisma.learnerProfile.findFirst({
          where: { deviceId, updatedAt: { gt: sinceDate } },
        }),
        prisma.sessionSummary.findMany({
          where: { deviceId, updatedAt: { gt: sinceDate } },
          orderBy: { createdAt: "desc" },
        }),
        prisma.seenText.findMany({
          where: { deviceId, createdAt: { gt: sinceDate } },
        }),
      ]);

      res.json({
        profile,
        sessions,
        seenTexts,
        serverTime: new Date().toISOString(),
      });
    } catch (err) {
      res.status(500).json({ error: { code: "SYNC_PULL_FAILED", message: String(err) } });
    }
  });

  // Push: client sends local changes
  router.post("/:deviceId", async (req, res) => {
    const { deviceId } = req.params;
    const { profile, sessions, seenTexts } = req.body as {
      profile?: Record<string, unknown>;
      sessions?: Record<string, unknown>[];
      seenTexts?: { textId: string; sessionType: string; seenAt: string }[];
    };

    try {
      // Upsert learner profile
      if (profile) {
        await prisma.learnerProfile.upsert({
          where: { deviceId },
          update: { ...profile, updatedAt: new Date() },
          create: { ...profile, deviceId, updatedAt: new Date() } as never,
        });
      }

      // Append session summaries (idempotent by clientSessionId)
      if (sessions?.length) {
        for (const session of sessions) {
          const clientId = session["clientSessionId"] as string;
          if (!clientId) continue;
          const existing = await prisma.sessionSummary.findUnique({
            where: { clientSessionId: clientId },
          });
          if (!existing) {
            await prisma.sessionSummary.create({
              data: { ...session, deviceId, clientSessionId: clientId } as never,
            });
          }
        }
      }

      // Append seen texts (idempotent by composite key)
      if (seenTexts?.length) {
        for (const st of seenTexts) {
          await prisma.seenText.upsert({
            where: {
              deviceId_textId_sessionType: {
                deviceId,
                textId: st.textId,
                sessionType: st.sessionType,
              },
            },
            update: {},
            create: {
              deviceId,
              textId: st.textId,
              sessionType: st.sessionType,
              seenAt: new Date(st.seenAt),
            },
          });
        }
      }

      res.json({ ok: true, serverTime: new Date().toISOString() });
    } catch (err) {
      res.status(500).json({ error: { code: "SYNC_PUSH_FAILED", message: String(err) } });
    }
  });

  return router;
}
