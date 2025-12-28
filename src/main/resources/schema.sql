CREATE TABLE IF NOT EXISTS users (
                                     id SERIAL PRIMARY KEY,
                                     name VARCHAR(255),
                                     email VARCHAR(255)
);

-- Optional: Add some seed data
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com') ON CONFLICT DO NOTHING;
INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com') ON CONFLICT DO NOTHING;