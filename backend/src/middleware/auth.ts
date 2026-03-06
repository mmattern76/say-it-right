import type { Request, Response, NextFunction } from "express";

export function requireApiKey(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const apiKey = process.env["API_KEY"];
  if (!apiKey) {
    res.status(500).json({
      error: { code: "SERVER_ERROR", message: "API key not configured" },
    });
    return;
  }

  const provided = req.headers["x-api-key"];
  if (provided !== apiKey) {
    res.status(401).json({
      error: { code: "UNAUTHORIZED", message: "Invalid or missing API key" },
    });
    return;
  }

  next();
}
