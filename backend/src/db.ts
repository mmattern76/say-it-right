import { PrismaClient } from "./generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";

const databaseUrl = process.env["DATABASE_URL"];

function createPrismaClient(): PrismaClient {
  if (!databaseUrl) {
    throw new Error("DATABASE_URL environment variable is required");
  }
  const adapter = new PrismaPg({ connectionString: databaseUrl });
  return new PrismaClient({ adapter });
}

export const prisma = createPrismaClient();

export async function disconnectDb(): Promise<void> {
  await prisma.$disconnect();
}
