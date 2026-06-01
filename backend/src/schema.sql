CREATE TABLE IF NOT EXISTS professionals (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  service_title TEXT NOT NULL,
  public_slug TEXT UNIQUE NOT NULL,
  phone TEXT,
  city TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS availability_days (
  id SERIAL PRIMARY KEY,
  professional_id INTEGER NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('available', 'booked', 'unavailable')),
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (professional_id, work_date)
);

CREATE TABLE IF NOT EXISTS booking_requests (
  id SERIAL PRIMARY KEY,
  professional_id INTEGER NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  requested_date DATE NOT NULL,
  client_name TEXT NOT NULL,
  client_phone TEXT NOT NULL,
  address TEXT,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'accepted', 'declined', 'done')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS financial_transactions (
  id SERIAL PRIMARY KEY,
  professional_id INTEGER NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category TEXT NOT NULL,
  transaction_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_availability_professional_date ON availability_days(professional_id, work_date);
CREATE INDEX IF NOT EXISTS idx_booking_professional_status ON booking_requests(professional_id, status);
CREATE INDEX IF NOT EXISTS idx_financial_professional_date ON financial_transactions(professional_id, transaction_date);
