#!/usr/bin/env python3
import http.server
import socketserver
import json

class HealthHandler(http.server.SimpleHTTPRequestHandler):
    def _set_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Access-Control-Max-Age', '3600')
    
    def do_OPTIONS(self):
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            response = {'status': 'healthy', 'message': 'ML Server is running'}
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/test':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            response = {'test': 'success', 'message': 'Test endpoint working'}
            self.wfile.write(json.dumps(response).encode())
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path == '/analyze_crop':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            response = {
                'health_status': 'healthy',
                'confidence': '0.95',
                'prediction_class': 'healthy_crop',
                'all_predictions': {'healthy': 0.95, 'diseased': 0.05}
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self._set_cors_headers()
            self.end_headers()

if __name__ == '__main__':
    handler = HealthHandler
    httpd = socketserver.TCPServer(('', 5000), handler)
    print('ML Server running on port 5000 with CORS support')
    print('Endpoints: /health (GET), /analyze_crop (POST)')
    httpd.serve_forever()
