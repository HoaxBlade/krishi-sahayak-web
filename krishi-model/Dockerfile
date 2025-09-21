# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

WORKDIR /app

# Install system deps (add curl for HEALTHCHECK)
RUN apt-get update && apt-get install -y \
  gcc \
  g++ \
  curl \
  libgl1 \
  libglib2.0-0 \
  libsm6 \
  libxext6 \
  libxrender1 \
  libgomp1 \
  libglib2.0-dev \
  libgthread-2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Environment: quieter TF logs; ensure unbuffered py
ENV PYTHONUNBUFFERED=1 \
  TENSORFLOW_CPP_MIN_LOG_LEVEL=2

# Copy and install deps (pin)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5001

# Healthcheck (uses curl)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:5001/health || exit 1

# Use gunicorn for production
CMD ["gunicorn", "-w", "1", "-k", "gthread", "--threads", "8", "-t", "60", "-b", "0.0.0.0:5001", "main:app"]