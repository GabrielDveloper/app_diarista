import cors from 'cors';
import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3000);
const professional = {
  id: 1,
  name: 'Sara Lima',
  service_title: 'Empregada domestica e diarista',
  public_slug: 'sara-lima',
  city: 'Sua cidade',
};

app.use(cors());
app.use(express.json());

const pad = (value) => String(value).padStart(2, '0');
const isoDate = (date) => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
const today = new Date();
const nowMonth = `${today.getFullYear()}-${pad(today.getMonth() + 1)}`;
const availability = [];

for (let day = 1; day <= 31; day += 1) {
  const date = new Date(today.getFullYear(), today.getMonth(), day);
  if (date.getMonth() !== today.getMonth() || date.getDay() === 0) continue;
  availability.push({
    id: day,
    work_date: isoDate(date),
    status: date.getDay() === 6 || day % 5 === 0 ? 'booked' : 'available',
    note: null,
  });
}

const bookingRequests = [
  {
    id: 1,
    requested_date: `${nowMonth}-08`,
    client_name: 'Ana Souza',
    client_phone: '(11) 99999-1234',
    address: 'Centro',
    details: 'Limpeza completa do apartamento',
    status: 'new',
    created_at: new Date().toISOString(),
  },
];

const transactions = [
  {
    id: 1,
    title: 'Diarista - Ana',
    amount: 180,
    type: 'income',
    category: 'Diarista',
    transaction_date: `${nowMonth}-02`,
  },
  {
    id: 2,
    title: 'Produtos de limpeza',
    amount: 42.5,
    type: 'expense',
    category: 'Materiais',
    transaction_date: `${nowMonth}-03`,
  },
];

function monthRows(rows, month, field) {
  const selectedMonth = /^\d{4}-\d{2}$/.test(month || '') ? month : nowMonth;
  return rows.filter((item) => item[field].startsWith(selectedMonth));
}

app.get('/health', (_req, res) => res.json({ ok: true, service: 'gestao-domestica-demo' }));

app.get('/api/v1/public/:slug/profile', (req, res) => {
  if (req.params.slug !== professional.public_slug) return res.status(404).json({ message: 'Profissional nao encontrada.' });
  return res.json({ professional });
});

app.get('/api/v1/public/:slug/availability', (req, res) => {
  if (req.params.slug !== professional.public_slug) return res.status(404).json({ message: 'Profissional nao encontrada.' });
  return res.json({ days: monthRows(availability, req.query.month, 'work_date') });
});

app.post('/api/v1/public/:slug/booking-requests', (req, res) => {
  const day = availability.find((item) => item.work_date === req.body.requestedDate);
  if (!day || day.status !== 'available') return res.status(409).json({ message: 'Esta data nao esta disponivel para solicitacao.' });
  const request = {
    id: bookingRequests.length + 1,
    requested_date: req.body.requestedDate,
    client_name: req.body.clientName,
    client_phone: req.body.clientPhone,
    address: req.body.address,
    details: req.body.details,
    status: 'new',
    created_at: new Date().toISOString(),
  };
  bookingRequests.unshift(request);
  return res.status(201).json({ request });
});

app.get('/api/v1/availability', (req, res) => {
  res.json({ days: monthRows(availability, req.query.month, 'work_date'), publicSlug: professional.public_slug });
});

app.post('/api/v1/availability', (req, res) => {
  const current = availability.find((item) => item.work_date === req.body.workDate);
  if (current) {
    current.status = req.body.status;
    current.note = req.body.note;
    return res.status(201).json({ day: current });
  }
  const day = { id: availability.length + 1, work_date: req.body.workDate, status: req.body.status, note: req.body.note };
  availability.push(day);
  return res.status(201).json({ day });
});

app.get('/api/v1/booking-requests', (_req, res) => res.json({ requests: bookingRequests }));

app.patch('/api/v1/booking-requests/:id', (req, res) => {
  const request = bookingRequests.find((item) => item.id === Number(req.params.id));
  if (!request) return res.status(404).json({ message: 'Solicitacao nao encontrada.' });
  request.status = req.body.status;
  if (request.status === 'accepted') {
    const day = availability.find((item) => item.work_date === request.requested_date);
    if (day) {
      day.status = 'booked';
      day.note = 'Contratacao aceita';
    } else {
      availability.push({
        id: availability.length + 1,
        work_date: request.requested_date,
        status: 'booked',
        note: 'Contratacao aceita',
      });
    }
  }
  return res.json({ request });
});

app.get('/api/v1/financial-transactions', (req, res) => {
  res.json({ transactions: monthRows(transactions, req.query.month, 'transaction_date') });
});

app.post('/api/v1/financial-transactions', (req, res) => {
  const transaction = {
    id: transactions.length + 1,
    title: req.body.title,
    amount: Number(req.body.amount),
    type: req.body.type,
    category: req.body.category,
    transaction_date: req.body.transactionDate,
  };
  transactions.unshift(transaction);
  return res.status(201).json({ transaction });
});

app.get('/api/v1/financial-summary', (req, res) => {
  const rows = monthRows(transactions, req.query.month, 'transaction_date');
  const income = rows.filter((item) => item.type === 'income').reduce((sum, item) => sum + item.amount, 0);
  const expense = rows.filter((item) => item.type === 'expense').reduce((sum, item) => sum + item.amount, 0);
  res.json({ income, expense, balance: income - expense });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`API demo rodando em http://localhost:${port}`);
});
