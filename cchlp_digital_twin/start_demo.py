#!/usr/bin/env python3
import http.server
import socketserver
import webbrowser
import os
import sys

def find_free_port(start_port=8090):
    import socket
    port = start_port
    while port < 8200:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('localhost', port)) != 0:
                return port
        port += 1
    return 8090

DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

def run():
    port = find_free_port()
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", port), Handler) as httpd:
        url = f"http://localhost:{port}"
        print(f"\n=======================================================")
        print(f"⚡ CC-HLP CYBER-PHYSICAL DIGITAL TWIN RUNNING")
        print(f"👉 Local Demo URL: {url}")
        print(f"Press Ctrl+C to stop the server.")
        print(f"=======================================================\n")
        try:
            webbrowser.open(url)
        except Exception:
            pass
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")
            sys.exit(0)

if __name__ == '__main__':
    run()
