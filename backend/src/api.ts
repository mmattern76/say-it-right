import "dotenv/config";
import { createApp } from "./app.js";
import { prisma, disconnectDb } from "./db.js";

const port = parseInt(process.env["PORT"] ?? "3000", 10);

const app = createApp(prisma);

const server = app.listen(port, () => {
  console.log(`Say-it-right backend listening on port ${port}`);
});

// Graceful shutdown
for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, async () => {
    console.log(`Received ${signal}, shutting down...`);
    server.close();
    await disconnectDb();
    process.exit(0);
  });
}
