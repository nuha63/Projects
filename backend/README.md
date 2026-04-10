# KitchenCraft AI API Backend

AI-powered cooking assistant backend for the KitchenCraft Flutter app.

## Features

- 🤖 AI-powered recipe generation using Groq/Llama
- 💾 Smart response caching for faster responses
- 🎯 Context-aware suggestions based on ingredients
- 🚀 Fast async API built with FastAPI
- 📊 Built-in monitoring and health checks
- 🔒 Secure API key management

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and add your API keys:

```bash
cp .env.example .env
```

Edit `.env`:
```
GROQ_API_KEY=your_actual_groq_api_key_here
ENVIRONMENT=development
```

### 3. Run the Server

**Development mode (with auto-reload):**
```bash
python main.py
```

Or:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Production mode:**
```bash
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### 4. Test the API

Open your browser:
- API Docs: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- Interactive API: http://localhost:8000/docs

Or use curl:
```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What can I make with eggs and rice?", "ingredients": ["eggs", "rice", "onions"]}'
```

## API Endpoints

### Chat
- `POST /api/chat` - Generate AI cooking responses
- `GET /api/chat/cache-stats` - View cache statistics
- `POST /api/chat/clear-cache` - Clear response cache

### Health
- `GET /health` - Comprehensive health check
- `GET /ping` - Simple ping/pong

## Project Structure

```
backend/
├── main.py                 # Application entry point
├── requirements.txt        # Python dependencies
├── .env.example           # Environment template
├── app/
│   ├── core/              # Core configuration
│   │   ├── config.py      # Settings management
│   │   └── cache.py       # Cache manager
│   ├── models/            # Pydantic models
│   │   └── schemas.py     # Request/response schemas
│   ├── routes/            # API routes
│   │   ├── chat.py        # Chat endpoints
│   │   └── health.py      # Health endpoints
│   └── services/          # Business logic
│       └── ai_service.py  # AI/Groq integration
```

## Configuration

All configuration is in `.env`:

- `GROQ_API_KEY` - Your Groq API key (required)
- `ENVIRONMENT` - development/production
- `CACHE_ENABLED` - Enable/disable caching
- `CACHE_TTL` - Cache time-to-live (seconds)
- `API_TIMEOUT` - API request timeout (seconds)

## Deployment

See `Dockerfile` and deployment guides for:
- Docker deployment
- Render.com
- Railway.app
- Google Cloud Run
- Fly.io

## Development

Run with auto-reload:
```bash
uvicorn main:app --reload
```

View logs:
```bash
tail -f logs/app.log
```

## License

See parent project LICENSE
