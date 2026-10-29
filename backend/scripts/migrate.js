// scripts/migrate.js
// Lightweight SQL migrator for MySQL using mysql2/promise.
import fs from 'fs';
import path from 'path';
import mysql from 'mysql2/promise';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Look in /app/backend/migrations (relative to this script)
const MIGRATIONS_DIR = path.join(__dirname, '..', 'migrations');
console.log('MIGRATIONS_DIR =', MIGRATIONS_DIR); // keep for sanity


async function main() {
  // Connect using your existing envs
  const conn = await mysql.createConnection({
    host: process.env.MYSQL_HOST,
    port: process.env.MYSQL_PORT ? Number(process.env.MYSQL_PORT) : 3306,
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE,
    multipleStatements: true,
  });

  // Ensure tracking table
  await conn.execute(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id INT AUTO_INCREMENT PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `);

  // Read applied list
  const [rows] = await conn.execute(
    `SELECT filename FROM schema_migrations ORDER BY applied_at ASC;`
  );
  const applied = new Set(rows.map((r) => r.filename));

  // Find pending .sql files (sorted)
  const candidates = fs.existsSync(MIGRATIONS_DIR)
    ? fs
        .readdirSync(MIGRATIONS_DIR)
        .filter((f) => f.endsWith(".sql"))
        .sort()
    : [];

  const pending = candidates.filter((f) => !applied.has(f));

  if (pending.length === 0) {
    console.log("No pending migrations.");
    await conn.end();
    return;
  }

  for (const file of pending) {
    const full = path.join(MIGRATIONS_DIR, file);
    const sql = fs.readFileSync(full, "utf8");
    console.log(`Applying migration: ${file}`);
    await conn.beginTransaction();
    try {
      await conn.query(sql);
      await conn.execute(
        `INSERT INTO schema_migrations (filename) VALUES (?);`,
        [file]
      );
      await conn.commit();
      console.log(`✓ Applied: ${file}`);
    } catch (err) {
      await conn.rollback();
      console.error(`✗ Failed: ${file}`);
      console.error(err);
      process.exit(1);
    }
  }

  await conn.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
