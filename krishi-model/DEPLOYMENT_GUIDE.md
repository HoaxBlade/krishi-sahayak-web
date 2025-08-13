# Krishi ML Server Deployment Guide

This guide provides multiple options to host your Python Flask server so you don't have to run it manually every time.

## 🚀 Quick Start Options

### Option 1: Render (Recommended for Beginners)

**Free tier available, easy deployment**

1. **Fork/Clone your repository to GitHub**
2. **Sign up at [render.com](https://render.com)**
3. **Create New Web Service**
4. **Connect your GitHub repository**
5. **Configure:**
   - **Name:** `krishi-ml-server`
   - **Environment:** `Python`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `python main_production.py`
6. **Deploy!**

Your server will be available at: `https://your-app-name.onrender.com`

### Option 2: Railway (Alternative Cloud)

**Free tier available, good for ML workloads**

1. **Sign up at [railway.app](https://railway.app)**
2. **Deploy from GitHub repository**
3. **Set environment variables:**
   - `PORT=5001`
4. **Deploy!**

### Option 3: Heroku (Paid, but Reliable)

**Professional hosting with good monitoring**

1. **Install Heroku CLI**
2. **Login:** `heroku login`
3. **Create app:** `heroku create krishi-ml-server`
4. **Deploy:** `git push heroku main`
5. **Open:** `heroku open`

## 🐳 Docker Deployment (Local/Cloud)

### Local Docker

```bash
# Build and run
docker-compose up --build

# Run in background
docker-compose up -d

# Stop
docker-compose down
```

### Cloud Docker (Google Cloud Run, AWS ECS, etc.)

```bash
# Build image
docker build -t krishi-ml-server .

# Push to registry
docker tag krishi-ml-server gcr.io/your-project/krishi-ml-server
docker push gcr.io/your-project/krishi-ml-server
```

## 🖥️ VPS/Cloud VM Deployment

### DigitalOcean Droplet

1. **Create Ubuntu droplet**
2. **SSH into server**
3. **Install dependencies:**

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv nginx
```

4. **Clone repository:**

```bash
git clone https://github.com/your-username/krishi-sahayak.git
cd krishi-sahayak/krishi-model
```

5. **Setup virtual environment:**

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

6. **Setup systemd service:**

```bash
# Copy service file
sudo cp krishi-ml-server.service /etc/systemd/system/

# Edit paths in service file
sudo nano /etc/systemd/system/krishi-ml-server.service

# Enable and start service
sudo systemctl enable krishi-ml-server
sudo systemctl start krishi-ml-server
```

7. **Setup Nginx reverse proxy:**

```bash
sudo nano /etc/nginx/sites-available/krishi-ml-server
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

8. **Enable site:**

```bash
sudo ln -s /etc/nginx/sites-available/krishi-ml-server /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🔧 Environment Variables

Set these in your hosting platform:

- `PORT`: Server port (usually set automatically by hosting platform)
- `FLASK_ENV`: `production` for production deployments

## 📱 Update Flutter App

After deploying, update your Flutter app's API base URL:

```dart
// In your Flutter app
const String baseUrl = 'https://your-deployed-server.com';
// Instead of
// const String baseUrl = 'http://localhost:5001';
```

## 🚨 Important Notes

1. **Model Files**: Ensure your trained model files (`*.h5`) are included in the repository
2. **Labels**: Make sure `labels.txt` is accessible
3. **Dependencies**: All required packages are in `requirements.txt`
4. **Memory**: ML models can be memory-intensive; choose appropriate hosting plan
5. **Cold Starts**: Free tiers may have cold start delays

## 🔍 Testing Deployment

Test your deployed server:

```bash
# Health check
curl https://your-server.com/health

# Get labels
curl https://your-server.com/labels

# Root endpoint
curl https://your-server.com/
```

## 💰 Cost Comparison

- **Render**: Free tier available, $7/month for paid
- **Railway**: Free tier available, pay-as-you-use
- **Heroku**: $7/month basic dyno
- **VPS**: $5-20/month depending on provider
- **Cloud Run**: Pay-per-request, very cheap for low usage

## 🆘 Troubleshooting

### Common Issues:

1. **Port binding errors**: Check if port is already in use
2. **Model loading failures**: Ensure model files are in correct paths
3. **Memory issues**: Increase hosting plan memory allocation
4. **CORS errors**: Check if CORS is properly configured

### Logs:

- **Render**: View logs in dashboard
- **Railway**: Check logs in deployment tab
- **Heroku**: `heroku logs --tail`
- **Docker**: `docker-compose logs`
- **Systemd**: `sudo journalctl -u krishi-ml-server -f`

## 📚 Next Steps

1. **Choose your preferred hosting option**
2. **Deploy following the guide above**
3. **Update your Flutter app with the new server URL**
4. **Test the integration**
5. **Monitor server performance and logs**

Your server will now run 24/7 without manual intervention! 🎉
