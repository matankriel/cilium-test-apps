-- Initialize database for testing
CREATE TABLE IF NOT EXISTS test_data (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS request_logs (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(100),
    service_name VARCHAR(100),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data
INSERT INTO test_data (service_name, message) VALUES
    ('backend', 'Initial test data'),
    ('frontend', 'Initial test data'),
    ('database', 'Database initialized');

