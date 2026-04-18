# 🎯 KitchenCraft FastAPI - Quick Reference Card

## 🚀 Start Backend (3 Ways)

### Option 1: Easy (Recommended)
```bash
cd backend
start.bat          # Windows
./start.sh         # Linux/Mac
```

### Option 2: Manual
```bash
cd backend
python main.py
```

### Option 3: With Auto-Reload
```bash
cd backend
uvicorn main:app --reload
```

---

## 🧪 Test Backend

```bash
# Health check
curl http://localhost:8000/health

# Test chat
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt":"What can I make with eggs?","ingredients":["eggs","rice"]}'

# Cache stats
curl http://localhost:8000/api/chat/cache-stats
```

**Or open in browser:**
- http://localhost:8000/docs (API documentation)
- http://localhost:8000/health (Health check)

---

## 🏃 Run Flutter App

```bash
# In project root
flutter run -d chrome
```

Your app will automatically connect to `http://localhost:8000`

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `backend/.env` | API keys & config |
| `backend/main.py` | Main FastAPI app |
| `lib/services/ai_backend_service.dart` | Backend API client |
| `lib/features/home/presentation/ai_chat_page.dart` | Chat UI |

---

## 🔧 Configuration

### Backend Config (`backend/.env`)
```env
GROQ_API_KEY=your_key_here
ENVIRONMENT=development
CACHE_ENABLED=true
CACHE_TTL=3600
```

### Flutter Config (`.env`)
```env
BACKEND_URL=http://localhost:8000
```

---

## 📊 Monitoring

### Watch Logs
Terminal where you ran `python main.py` shows:
- 📨 Incoming requests
- 🤖 AI API calls
- ✨ Cache hits
- ✅ Successful responses
- ❌ Errors

### Commands
```bash
# Cache performance
curl http://localhost:8000/api/chat/cache-stats

# Clear cache
curl -X POST http://localhost:8000/api/chat/clear-cache

# Health status
curl http://localhost:8000/health
```

---

## 🐛 Troubleshooting

### Backend won't start
```bash
# Install dependencies
cd backend
pip install -r requirements.txt
```

### Port 8000 in use
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Flutter can't connect
1. Check backend is running: `curl http://localhost:8000/health`
2. Check `.env` has `BACKEND_URL=http://localhost:8000`
3. Restart Flutter app

### API errors
1. Check `backend/.env` has valid `GROQ_API_KEY`
2. Check backend terminal for error logs
3. Test with curl to isolate issue

---

## 🌐 Deployment Checklist

- [ ] Backend running locally
- [ ] Flutter app tested locally
- [ ] Choose hosting platform (Render/Railway/Fly.io)
- [ ] Deploy backend
- [ ] Get backend URL (e.g., https://your-app.onrender.com)
- [ ] Update `.env`: `BACKEND_URL=https://your-app.onrender.com`
- [ ] Build Flutter: `flutter build web`
- [ ] Deploy Flutter app
- [ ] Test production

**See**: `backend/DEPLOYMENT.md` for detailed steps

---

## 💡 Common Tasks

### Add new AI model
Edit `backend/app/core/config.py`:
```python
GROQ_MODEL: str = "mixtral-8x7b-32768"  # Change this
```

### Adjust cache size
Edit `backend/.env`:
```env
CACHE_MAX_SIZE=200      # Increase from 100
CACHE_TTL=7200          # 2 hours instead of 1
```

### Change backend port
```bash
uvicorn main:app --port 8001
```
Then update Flutter `.env`:
```env
BACKEND_URL=http://localhost:8001
```

---

## 📚 Documentation

- **Setup Guide**: [BACKEND_SETUP.md](BACKEND_SETUP.md)
- **Implementation Details**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **Before/After Comparison**: [BEFORE_VS_AFTER.md](BEFORE_VS_AFTER.md)
- **Deployment Guide**: [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md)
- **Backend README**: [backend/README.md](backend/README.md)

---

## ⚡ Quick Commands Reference

```bash
# Backend
cd backend && python main.py          # Start backend
cd backend && pip install -r requirements.txt  # Install deps

# Flutter
flutter run -d chrome                 # Run on Chrome
flutter run                           # Run on all devices
flutter clean && flutter pub get      # Clean install

# Testing
curl http://localhost:8000/health     # Health check
curl http://localhost:8000/api/chat/cache-stats  # Cache stats

# Docker
cd backend && docker-compose up       # Run with Docker
docker-compose down                   # Stop Docker
```

---

## 🎯 Success Indicators

Your setup is working correctly if:

- ✅ Backend health check returns `"status": "ok"`
- ✅ Flutter app connects without errors
- ✅ Chatbot responds to questions
- ✅ Backend logs show requests
- ✅ Cache stats show hits increasing
- ✅ No CORS errors in browser console

---

## 🆘 Quick Help

**Backend Issues**: Check terminal logs where you ran `python main.py`

**Flutter Issues**: Check VS Code Debug Console

**API Issues**: Check Groq console at https://console.groq.com

**Still Stuck?**: 
1. Review `BACKEND_SETUP.md`
2. Check logs in both terminals
3. Verify `.env` files are correct

---

## 🎉 You're All Set!

**Backend**: http://localhost:8000/docs
**Flutter**: Running on your device
**Chatbot**: Ready to help users cook!

**Next**: Try asking your chatbot questions and watch the magic happen! ✨
