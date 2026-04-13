from http.server import HTTPServer, BaseHTTPRequestHandler
import math
import gc
import os
import threading
import time

# Memory monitoring configuration
MEMORY_THRESHOLD_MB = 12
THRESHOLD_DURATION_SECONDS = 90
memory_over_threshold_start = None

def get_memory_usage_mb():
    """Get current process memory usage in MB using /proc filesystem"""
    try:
        with open('/proc/self/status', 'r') as f:
            for line in f:
                if line.startswith('VmRSS:'):
                    # VmRSS is in kB, convert to MB
                    memory_kb = int(line.split()[1])
                    return memory_kb / 1024
    except Exception as e:
        print(f'Error reading memory: {e}')
        return 0
    return 0

def monitor_memory():
    """Monitor memory usage and trigger GC if over threshold for specified duration"""
    global memory_over_threshold_start
    
    while True:
        try:
            memory_mb = get_memory_usage_mb()
            
            if memory_mb > MEMORY_THRESHOLD_MB:
                if memory_over_threshold_start is None:
                    memory_over_threshold_start = time.time()
                    print(f'Memory usage {memory_mb:.2f}MB exceeds threshold {MEMORY_THRESHOLD_MB}MB')
                else:
                    duration = time.time() - memory_over_threshold_start
                    if duration >= THRESHOLD_DURATION_SECONDS:
                        print(f'Memory over threshold for {duration:.0f}s, running full GC')
                        gc.collect()
                        memory_after = get_memory_usage_mb()
                        print(f'GC complete: {memory_mb:.2f}MB -> {memory_after:.2f}MB')
                        memory_over_threshold_start = None
            else:
                if memory_over_threshold_start is not None:
                    print(f'Memory usage {memory_mb:.2f}MB back below threshold')
                memory_over_threshold_start = None
                
        except Exception as e:
            print(f'Memory monitoring error: {e}')
        
        time.sleep(5)  # Check every 5 seconds

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # CPU-intensive work
        x = 0.0
        for i in range(10000000):
            x += math.sqrt(i + 1)
        
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'OK!')
    
    def log_message(self, format, *args):
        pass  # Suppress logs to reduce memory

if __name__ == '__main__':
    # Start memory monitoring thread
    monitor_thread = threading.Thread(target=monitor_memory, daemon=True)
    monitor_thread.start()
    print(f'Memory monitor started (threshold: {MEMORY_THRESHOLD_MB}MB for {THRESHOLD_DURATION_SECONDS}s)')
    
    server = HTTPServer(('0.0.0.0', 80), RequestHandler)
    print('Server starting on port 80')
    server.serve_forever()