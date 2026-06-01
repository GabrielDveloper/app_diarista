import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import { getDefaultProfessional, getProfessionalBySlug, initDatabase, pool } from './db.js';

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

function monthRange(month) {
  const value = month && /^\d{4}-\d{2}$/.test(month) ? month : new Date().toISOString().slice(0, 7);
  const start = `${value}-01`;
  const next = new Date(`${start}T00:00:00.000Z`);
  next.setUTCMonth(next.getUTCMonth() + 1);
  return { start, end: next.toISOString().slice(0, 10) };
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'gestao-domestica-api' });
});

app.get('/api/v1/public/:slug/profile', asyncRoute(async (req, res) => {
  const professional = await getProfessionalBySlug(req.params.slug);
  if (!professional) return res.status(404).json({ message: 'Profissional nao encontrada.' });
  return res.json({ professional });
}));

app.get('/api/v1/public/:slug/availability', asyncRoute(async (req, res) => {
  const professional = await getProfessionalBySlug(req.params.slug);
  if (!professional) return res.status(404).json({ message: 'Profissional nao encontrada.' });

  const { start, end } = monthRange(req.query.month);
  const result = await pool.query(
    `SELECT id, work_date, status, note
     FROM availability_days
     WHERE professional_id = $1 AND work_date >= $2 AND work_date < $3
     ORDER BY work_date ASC`,
    [professional.id, start, end],
  );

  return res.json({ days: result.rows });
}));

app.post('/api/v1/public/:slug/booking-requests', asyncRoute(async (req, res) => {
  const professional = await getProfessionalBySlug(req.params.slug);
  if (!professional) return res.status(404).json({ message: 'Profissional nao encontrada.' });

  const { requestedDate, clientName, clientPhone, address, details } = req.body;
  if (!requestedDate || !clientName || !clientPhone) {
    return res.status(400).json({ message: 'Data, nome e telefone sao obrigatorios.' });
  }

  const available = await pool.query(
    `SELECT status FROM availability_days
     WHERE professional_id = $1 AND work_date = $2`,
    [professional.id, requestedDate],
  );

  if (available.rows[0]?.status !== 'available') {
    return res.status(409).json({ message: 'Esta data nao esta disponivel para solicitacao.' });
  }

  const result = await pool.query(
    `INSERT INTO booking_requests
      (professional_id, requested_date, client_name, client_phone, address, details)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [professional.id, requestedDate, clientName, clientPhone, address || null, details || null],
  );

  return res.status(201).json({ request: result.rows[0] });
}));

app.get('/api/v1/availability', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { start, end } = monthRange(req.query.month);
  const result = await pool.query(
    `SELECT id, work_date, status, note
     FROM availability_days
     WHERE professional_id = $1 AND work_date >= $2 AND work_date < $3
     ORDER BY work_date ASC`,
    [professional.id, start, end],
  );
  res.json({ days: result.rows, publicSlug: professional.public_slug });
}));

app.post('/api/v1/availability', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { workDate, status, note } = req.body;
  if (!workDate || !['available', 'booked', 'unavailable'].includes(status)) {
    return res.status(400).json({ message: 'Data e status valido sao obrigatorios.' });
  }

  const result = await pool.query(
    `INSERT INTO availability_days (professional_id, work_date, status, note)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (professional_id, work_date)
     DO UPDATE SET status = EXCLUDED.status, note = EXCLUDED.note, updated_at = NOW()
     RETURNING *`,
    [professional.id, workDate, status, note || null],
  );

  res.status(201).json({ day: result.rows[0] });
}));

app.get('/api/v1/booking-requests', asyncRoute(async (_req, res) => {
  const professional = await getDefaultProfessional();
  const result = await pool.query(
    `SELECT *
     FROM booking_requests
     WHERE professional_id = $1
     ORDER BY created_at DESC`,
    [professional.id],
  );
  res.json({ requests: result.rows });
}));

app.patch('/api/v1/booking-requests/:id', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { status } = req.body;
  if (!['new', 'accepted', 'declined', 'done'].includes(status)) {
    return res.status(400).json({ message: 'Status invalido.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `UPDATE booking_requests
       SET status = $1
       WHERE id = $2 AND professional_id = $3
       RETURNING *`,
      [status, req.params.id, professional.id],
    );

    if (!result.rows[0]) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Solicitacao nao encontrada.' });
    }

    if (status === 'accepted') {
      await client.query(
        `INSERT INTO availability_days (professional_id, work_date, status, note)
         VALUES ($1, $2, 'booked', 'Contratacao aceita')
         ON CONFLICT (professional_id, work_date)
         DO UPDATE SET status = 'booked', note = 'Contratacao aceita', updated_at = NOW()`,
        [professional.id, result.rows[0].requested_date],
      );
    }

    await client.query('COMMIT');
    return res.json({ request: result.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}));

app.get('/api/v1/financial-transactions', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { start, end } = monthRange(req.query.month);
  const result = await pool.query(
    `SELECT *
     FROM financial_transactions
     WHERE professional_id = $1 AND transaction_date >= $2 AND transaction_date < $3
     ORDER BY transaction_date DESC, id DESC`,
    [professional.id, start, end],
  );
  res.json({ transactions: result.rows });
}));

app.post('/api/v1/financial-transactions', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { title, amount, type, category, transactionDate, notes } = req.body;
  if (!title || !amount || !['income', 'expense'].includes(type) || !category || !transactionDate) {
    return res.status(400).json({ message: 'Titulo, valor, tipo, categoria e data sao obrigatorios.' });
  }

  const result = await pool.query(
    `INSERT INTO financial_transactions
      (professional_id, title, amount, type, category, transaction_date, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [professional.id, title, amount, type, category, transactionDate, notes || null],
  );
  res.status(201).json({ transaction: result.rows[0] });
}));

app.get('/api/v1/financial-summary', asyncRoute(async (req, res) => {
  const professional = await getDefaultProfessional();
  const { start, end } = monthRange(req.query.month);
  const result = await pool.query(
    `SELECT
       COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
       COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
     FROM financial_transactions
     WHERE professional_id = $1 AND transaction_date >= $2 AND transaction_date < $3`,
    [professional.id, start, end],
  );
  const income = Number(result.rows[0].income);
  const expense = Number(result.rows[0].expense);
  res.json({ income, expense, balance: income - expense });
}));

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ message: 'Erro interno do servidor.' });
});

await initDatabase();

app.listen(port, '0.0.0.0', () => {
  console.log(`API rodando em http://localhost:${port}`);
});
