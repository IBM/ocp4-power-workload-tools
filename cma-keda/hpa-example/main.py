from http.server import HTTPServer, BaseHTTPRequestHandler
import math
import gc
import psutil
import threading
import time

# Memory monitoring configuration
MEMORY_THRESHOLD_MB = 12
THRESHOLD_DURATION_SECONDS = 90
memory_over_threshold_start = None

def monitor_memory():
    """Monitor memory usage and trigger GC if over threshold for specified duration"""
    global memory_over_threshold_start
    
    while True:
        try:
            process = psutil.Process()
            memory_mb = process.memory_info().rss / (1024 * 1024)  # Convert to MB
            
            if memory_mb > MEMORY_THRESHOLD_MB:
                if memory_over_threshold_start is None:
                    memory_over_threshold_start = time.time()
                    print(f'Memory usage {memory_mb:.2f}MB exceeds threshold {MEMORY_THRESHOLD_MB}MB')
                else:
                    duration = time.time() - memory_over_threshold_start
                    if duration >= THRESHOLD_DURATION_SECONDS:
                        print(f'Memory over threshold for {duration:.0f}s, running full GC')
                        gc.collect()
                        memory_after = process.memory_info().rss / (1024 * 1024)
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