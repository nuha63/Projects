# 🚀 KitchenCraft FastAPI Backend Setup Guide

This guide will help you set up and run the FastAPI backend for your KitchenCraft app's AI chatbot.

## 📋 Prerequisites

- Python 3.11 or higher
- pip (Python package manager)
- Your Groq API key (from https://console.groq.com/keys)

## ⚡ Quick Start

### Step 1: Create Backend Environment File

```bash
cd backend
copy .env.example .env
```

Or on Linux/Mac:
```bash
cd backend
cp .env.example .env
```

### Step 2: Edit `.env` File

Open `backend/.env` and add your Groq API key:

```env
ENVIRONMENT=development
GROQ_API_KEY=your_actual_groq_api_key_here
```

### Step 3: Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

If you prefer using a virtual environment (recommended):

```bash
# Windows
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# Linux/Mac
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Step 4: Run the Backend Server

```bash
python main.py
```

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 5: Test the Backend

Open your browser and go to:
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Ping Test**: http://localhost:8000/ping

Or use curl:
```bash
curl http://localhost:8000/health
```

You should see:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "environment": "development",
  "api_configured": true,
  "cache_stats": {...}
}
```

### Step 6: Test the Chat Endpoint

```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"What can I make with eggs and rice?\", \"ingredients\": [\"eggs\", \"rice\"]}"
```

### Step 7: Run Your Flutter App

Now run your Flutter app:
```bash
flutter run -d chrome
```

The app will automatically connect to your local backend at `http://localhost:8000`.

---

## 🎯 What This Backend Does

### Key Features:
1. **🔒 Secure API Key Management**: Your Groq API key stays on the server, never exposed in the Flutter app
2. **⚡ Smart Caching**: Identical questions get instant responses from cache
3. **🧠 Context-Aware**: Enhances prompts with user's ingredients and preferences
4. **📊 Monitoring**: Built-in health checks and cache statistics
5. **🚀 Production-Ready**: Easy deployment to Render, Railway, Fly.io, etc.

### Endpoints:
- `POST /api/chat` - Main chat endpoint
- `GET /health` - Health check with stats
- `GET /api/chat/cache-stats` - View cache performance
- `POST /api/chat/clear-cache` - Clear response cache

---

## 🔧 Development Tips

### Auto-Reload on Code Changes:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### View Logs:
The terminal where you ran `python main.py` will show all logs in real-time.

### Check Cache Performance:
```bash
curl http://localhost:8000/api/chat/cache-stats
```

### Clear Cache:
```bash
curl -X POST http://localhost:8000/api/chat/clear-cache
```

---

## 🐛 Troubleshooting

### ❌ "ModuleNotFoundError"
**Solution**: Install dependencies
```bash
pip install -r requirements.txt
```

### ❌ "Address already in use"
**Solution**: Port 8000 is already taken
```bash
# Find and kill the process
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac:
lsof -ti:8000 | xargs kill -9
```

Or use a different port:
```bash
uvicorn main:app --port 8001
```

Then update your Flutter `.env`:
```
BACKEND_URL=http://localhost:8001
```

### ❌ "API key not configured"
**Solution**: Check `backend/.env` file exists and has valid GROQ_API_KEY

### ❌ Flutter app can't connect
**Solution**: Ensure backend is running and check the URL:
- Web: `http://localhost:8000`
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`

---

## 🌐 Deploying to Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions to:
- Render.com (Recommended - Free tier available)
- Railway.app
- Fly.io
- Google Cloud Run
- Docker

### Quick Render.com Deployment:

1. Push code to GitHub
2. Go to https://render.com
3. Create new Web Service
4. Connect your repo
5. Set root directory to `backend`
6. Add environment variable: `GROQ_API_KEY`
7. Deploy!

Then update your Flutter app's `.env`:
```
BACKEND_URL=https://your-app.onrender.com
```

---

## 📊 Monitoring Your Backend

### View real-time activity:
Watch the terminal where you ran `python main.py`. You'll see:
- 📨 Incoming requests
- 🤖 AI API calls
- ✨ Cache hits
- ✅ Successful responses
- ❌ Errors

### Check cache performance:
```bash
curl http://localhost:8000/api/chat/cache-stats
```

Response:
```json
{
  "size": 5,
  "max_size": 100,
  "hits": 12,
  "misses": 5,
  "hit_rate": "70.59%",
  "ttl_seconds": 3600
}
```

---

## 🎨 Customization

### Change AI Model:
Edit `backend/app/core/config.py`:
```python
GROQ_MODEL: str = "llama-3.3-70b-versatile"
# Or try: "mixtral-8x7b-32768"
```

### Adjust Cache Settings:
Edit `backend/.env`:
```env
CACHE_ENABLED=true
CACHE_TTL=3600        # 1 hour
CACHE_MAX_SIZE=100    # Max 100 cached responses
```

### Customize Prompts:
Edit `backend/app/services/ai_service.py` in the `_build_enhanced_prompt` method.

---

## 🤝 Need Help?

1. Check the logs in your terminal
2. Review [backend/README.md](README.md)
3. See [DEPLOYMENT.md](DEPLOYMENT.md) for production setup
4. Test with the `/docs` endpoint: http://localhost:8000/docs

---

## ✅ Success Checklist

- [ ] Backend runs without errors
- [ ] Health check returns `"status": "ok"`
- [ ] Test chat endpoint works
- [ ] Flutter app connects successfully
- [ ] Chatbot responds to questions
- [ ] Responses are cached (check cache stats)

**You're all set! Enjoy your AI-powered cooking assistant! 🎉**
