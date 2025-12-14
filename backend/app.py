from flask import Flask, jsonify, request
import psycopg2
import os
import requests
import time
import random
from datetime import datetime

app = Flask(__name__)

# Configuration
DB_HOST = os.getenv('DB_HOST', 'postgres-service.database-ns.svc.cluster.local')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'testdb')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')
LOGGING_SERVICE_URL = os.getenv('LOGGING_SERVICE_URL', 'http://logging-service.shared-ns.svc.cluster.local:5000')

request_count = 0
error_count = 0

def get_db_connection():
    """Create database connection"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=5
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def send_log(level, message):
    """Send log to logging service"""
    try:
        requests.post(
            f"{LOGGING_SERVICE_URL}/log",
            json={
                'service': 'backend',
                'level': level,
                'message': message,
                'timestamp': datetime.now().isoformat()
            },
            timeout=2
        )
    except Exception as e:
        print(f"Failed to send log: {e}")

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'service': 'backend',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/data', methods=['GET'])
def get_data():
    global request_count, error_count
    request_count += 1
    request_id = request.headers.get('X-Request-ID', f'backend-{request_count}')
    
    # Randomly generate errors (10% chance)
    if random.random() < 0.1:
        error_count += 1
        send_log('ERROR', f'Intentional error generated for request {request_id}')
        return jsonify({
            'error': 'Intentional error for testing',
            'service': 'backend',
            'requestId': request_id
        }), 500
    
    # Try to connect to database
    conn = get_db_connection()
    if conn is None:
        error_count += 1
        send_log('ERROR', f'Database connection failed for request {request_id}')
        return jsonify({
            'error': 'Database connection failed',
            'service': 'backend',
            'requestId': request_id
        }), 503
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM information_schema.tables")
        table_count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        send_log('INFO', f'Successfully processed request {request_id}')
        
        return jsonify({
            'service': 'backend',
            'requestId': request_id,
            'data': {
                'message': 'Data retrieved successfully',
                'tableCount': table_count,
                'timestamp': datetime.now().isoformat()
            }
        })
    except Exception as e:
        error_count += 1
        send_log('ERROR', f'Database query failed: {str(e)}')
        if conn:
            conn.close()
        return jsonify({
            'error': str(e),
            'service': 'backend',
            'requestId': request_id
        }), 500

@app.route('/api/slow', methods=['GET'])
def slow_endpoint():
    """Endpoint that takes a long time to respond"""
    delay = int(request.args.get('delay', 3))
    time.sleep(delay)
    return jsonify({
        'service': 'backend',
        'message': f'Slow response after {delay} seconds',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/error', methods=['GET'])
def error_endpoint():
    """Endpoint that always returns an error"""
    global error_count
    error_count += 1
    error_type = request.args.get('type', 'generic')
    
    send_log('ERROR', f'Error endpoint called with type: {error_type}')
    
    if error_type == 'timeout':
        time.sleep(10)  # Simulate timeout
    
    return jsonify({
        'error': f'Error type: {error_type}',
        'service': 'backend',
        'timestamp': datetime.now().isoformat()
    }), 500

@app.route('/metrics', methods=['GET'])
def metrics():
    return jsonify({
        'service': 'backend',
        'totalRequests': request_count,
        'errorCount': error_count,
        'successRate': ((request_count - error_count) / request_count * 100) if request_count > 0 else 0,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Initialize database connection on startup
    print(f"Connecting to database at {DB_HOST}:{DB_PORT}")
    app.run(host='0.0.0.0', port=8080, debug=False)

