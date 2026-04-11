from http.server import HTTPServer, BaseHTTPRequestHandler
import math

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
    server = HTTPServer(('0.0.0.0', 80), RequestHandler)
    print('Server starting on port 80')
    server.serve_forever()