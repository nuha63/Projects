#!/bin/bash
# KitchenCraft Backend Startup Script

echo "========================================"
echo "  KitchenCraft AI Backend Startup"
echo "========================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "[ERROR] .env file not found!"
    echo ""
    echo "Please create a .env file:"
    echo "  1. Copy .env.example to .env"
    echo "  2. Add your GROQ_API_KEY"
    echo ""
    echo "Run: cp .env.example .env"
    echo ""
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python is not installed"
    echo ""
    echo "Please install Python 3.11 or higher"
    echo ""
    exit 1
fi

echo "[1/3] Checking Python version..."
python3 --version

# Check if requirements are installed
echo ""
echo "[2/3] Checking dependencies..."
if ! python3 -c "import fastapi" &> /dev/null; then
    echo ""
    echo "[INFO] Installing dependencies..."
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo ""
        echo "[ERROR] Failed to install dependencies"
        exit 1
    fi
else
    echo "Dependencies OK"
fi

echo ""
echo "[3/3] Starting server..."
echo ""
echo "========================================"
echo "  Backend will be available at:"
echo "  http://localhost:8000"
echo ""
echo "  API Docs: http://localhost:8000/docs"
echo "  Health: http://localhost:8000/health"
echo "========================================"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
python3 main.py
