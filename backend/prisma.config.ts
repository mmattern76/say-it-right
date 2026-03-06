import path from "node:path";
import { defineConfig } from "prisma/config";

export default defineConfig({
  earlyAccess: true,
  schema: path.join(__dirname, "prisma", "schema.prisma"),
  datasources: {
    db: {
      url: process.env["DATABASE_URL"]!,
    },
  },
  migrate: {
    adapter: async () => {
      const { PrismaPg } = await import("@prisma/adapter-pg");
      const url = process.env["DATABASE_URL"];
      if (!url) throw new Error("DATABASE_URL is required");
      return new PrismaPg({ connectionString: url });
    },
  },
});
