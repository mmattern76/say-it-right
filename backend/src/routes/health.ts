import { Router } from "express";

const router = Router();

router.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "say-it-right",
    version: process.env["npm_package_version"] ?? "1.0.0",
    timestamp: new Date().toISOString(),
  });
});

export default router;
