#!/bin/bash

# Script to serve the Marketincer website locally
# Usage: ./serve-local.sh [port]

PORT=${1:-8000}

echo "Starting local server on port $PORT..."
echo "Website will be available at: http://localhost:$PORT"
echo "Press Ctrl+C to stop the server"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT
else
    echo "Python not found. Please install Python to run the local server."
    echo "Alternatively, you can open index.html directly in your browser."
fi
