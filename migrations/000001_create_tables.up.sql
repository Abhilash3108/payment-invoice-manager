Create TABLE users (
    id serial PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT
);

CREATE TABLE invoice(
    id serial PRIMARY KEY,
    user_id INTEGER NOT NULL references users(id)
    amount NUMERIC NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPS NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id serial PRIMARY KEY,
    invoice_id INTEGER NOT NULL references invoice(id),
    transaction_id TEXT,
    status TEXT NOT NULL,
    payment_method TEXT,
    amount NUMERIC NOT NULL,
    created_at TIMESTAMPS NOT NULL DEFAULT NOW()
);