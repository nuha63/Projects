# KitchenCraft AI API - Deployment Guide

## Deployment Options

### 1. Render.com (Recommended - Free Tier Available)

**Steps:**
1. Push your code to GitHub
2. Go to [render.com](https://render.com) and sign up
3. Create a new "Web Service"
4. Connect your GitHub repository
5. Set the following:
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT`
   - **Environment**: Python 3
6. Add environment variables:
   - `GROQ_API_KEY`: Your Groq API key
   - `ENVIRONMENT`: production
   - `ALLOWED_ORIGINS`: Your Flutter app domain
7. Click "Create Web Service"

**Your API will be available at**: `https://your-app-name.onrender.com`

---

### 2. Railway.app (Free Tier Available)

**Steps:**
1. Install Railway CLI: `npm i -g @railway/cli`
2. Login: `railway login`
3. In the `backend` directory, run:
   ```bash
   railway init
   railway up
   ```
4. Set environment variables:
   ```bash
   railway variables set GROQ_API_KEY=your_key_here
   railway variables set ENVIRONMENT=production
   ```
5. Deploy:
   ```bash
   railway up
   ```

**Your API will be available at**: Railway provides a URL

---

### 3. Fly.io (Free Tier Available)

**Steps:**
1. Install Fly CLI: `curl -L https://fly.io/install.sh | sh`
2. Login: `fly auth login`
3. In the `backend` directory:
   ```bash
   fly launch
   ```
4. Set secrets:
   ```bash
   fly secrets set GROQ_API_KEY=your_key_here
   ```
5. Deploy:
   ```bash
   fly deploy
   ```

---

### 4. Docker (Self-hosted)

**Build and run:**
```bash
cd backend

# Build image
docker build -t kitchencraft-ai-api .

# Run container
docker run -d \
  -p 8000:8000 \
  -e GROQ_API_KEY=your_key_here \
  -e ENVIRONMENT=production \
  --name kitchencraft-api \
  kitchencraft-ai-api
```

**Or use docker-compose:**
```bash
docker-compose up -d
```

---

### 5. Google Cloud Run (Free Tier Available)

**Steps:**
1. Install gcloud CLI
2. Authenticate: `gcloud auth login`
3. Build and deploy:
   ```bash
   gcloud run deploy kitchencraft-ai-api \
     --source . \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars GROQ_API_KEY=your_key_here,ENVIRONMENT=production
   ```

---

## After Deployment

1. **Test your API:**
   ```bash
   curl https://your-api-domain.com/health
   ```

2. **Update Flutter app:**
   Add to your `.env` file:
   ```
   BACKEND_URL=https://your-api-domain.com
   ```

3. **Update CORS:**
   In production, update `ALLOWED_ORIGINS` to your actual Flutter app domains:
   ```
   ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
   ```

---

## Monitoring

- **Health Check**: `GET /health`
- **Cache Stats**: `GET /api/chat/cache-stats`
- **API Docs**: `GET /docs` (only in development)

---

## Cost Estimates (Free Tiers)

| Platform | Free Tier | Limits |
|----------|-----------|--------|
| Render.com | ✅ Yes | 750 hours/month, sleeps after 15min inactive |
| Railway.app | ✅ Yes | $5 credit/month |
| Fly.io | ✅ Yes | 3 shared-cpu-1x VMs, 160GB bandwidth |
| Google Cloud Run | ✅ Yes | 2M requests/month, 360k GB-seconds |

---

## Troubleshooting

**API not responding:**
- Check logs in your platform dashboard
- Verify environment variables are set
- Ensure GROQ_API_KEY is valid

**CORS errors:**
- Update ALLOWED_ORIGINS environment variable
- Include your Flutter app domain

**Slow responses:**
- Free tiers may sleep after inactivity
- Consider upgrading or keeping alive with periodic pings

---

## Security Best Practices

1. **Never commit .env file** - It's in .gitignore
2. **Rotate API keys** regularly
3. **Restrict CORS origins** in production
4. **Enable rate limiting** for public APIs
5. **Monitor usage** to detect abuse
