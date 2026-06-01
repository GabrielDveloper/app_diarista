import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const { Pool } = pg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export async function initDatabase() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const schema = await fs.readFile(schemaPath, 'utf8');
  await pool.query(schema);

  const slug = process.env.PUBLIC_SLUG || 'sara-lima';
  const name = process.env.PROFESSIONAL_NAME || 'Sara Lima';
  const service = process.env.PROFESSIONAL_SERVICE || 'Empregada domestica e diarista';

  await pool.query(
    `INSERT INTO professionals (name, service_title, public_slug, city)
     VALUES ($1, $2, $3, 'Sua cidade')
     ON CONFLICT (public_slug)
     DO UPDATE SET name = EXCLUDED.name, service_title = EXCLUDED.service_title`,
    [name, service, slug],
  );
}

export async function getDefaultProfessional() {
  const slug = process.env.PUBLIC_SLUG || 'sara-lima';
  const result = await pool.query('SELECT * FROM professionals WHERE public_slug = $1 LIMIT 1', [slug]);
  return result.rows[0];
}

export async function getProfessionalBySlug(slug) {
  const result = await pool.query('SELECT * FROM professionals WHERE public_slug = $1 LIMIT 1', [slug]);
  return result.rows[0];
}
