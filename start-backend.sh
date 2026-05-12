#!/bin/bash
# BharatMitra Backend Startup Script

set -e

PROJECT_DIR="/Users/mohith/Downloads/yojana_mitra_app"
BACKEND_DIR="$PROJECT_DIR/backend"
PORT=8000

echo "═════════════════════════════════════════════════════"
echo "  BharatMitra Backend Startup"
echo "═════════════════════════════════════════════════════"
echo ""

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found at $BACKEND_DIR"
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi

# Check/install dependencies
echo "📦 Checking dependencies..."
cd "$BACKEND_DIR"

if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please create it from .env.example"
    echo "   cp .env.example .env"
    exit 1
fi

echo "✓ .env configured"

# Install uvicorn if needed
python3 -c "import uvicorn" 2>/dev/null || {
    echo "📥 Installing uvicorn..."
    pip install uvicorn --quiet --break-system-packages
}

echo "✓ uvicorn available"
echo ""

# Get local IP
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

echo "Starting FastAPI backend..."
echo "  Host: 0.0.0.0"
echo "  Port: $PORT"
echo "  Local IP: $LOCAL_IP:$PORT"
echo ""
echo "🌍 Phone should use: http://$LOCAL_IP:$PORT"
echo ""
echo "Press Ctrl+C to stop"
echo "═════════════════════════════════════════════════════"
echo ""

# Start server
python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT --reload
