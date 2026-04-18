@echo off
REM KitchenCraft Backend Startup Script

echo ========================================
echo   KitchenCraft AI Backend Startup
echo ========================================
echo.

REM Check if .env file exists
if not exist .env (
    echo [ERROR] .env file not found!
    echo.
    echo Please create a .env file:
    echo   1. Copy .env.example to .env
    echo   2. Add your GROQ_API_KEY
    echo.
    echo Run: copy .env.example .env
    echo.
    pause
    exit /b 1
)

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo.
    echo Please install Python 3.11 or higher from:
    echo https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [1/3] Checking Python version...
python --version

REM Check if requirements are installed
echo.
echo [2/3] Checking dependencies...
pip show fastapi >nul 2>&1
if errorlevel 1 (
    echo.
    echo [INFO] Installing dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
) else (
    echo Dependencies OK
)

echo.
echo [3/3] Starting server...
echo.
echo ========================================
echo   Backend will be available at:
echo   http://localhost:8000
echo.
echo   API Docs: http://localhost:8000/docs
echo   Health: http://localhost:8000/health
echo ========================================
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
python main.py
