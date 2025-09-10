# Cloudflare Configuration for Krishi Sahayak

## 🌐 Domain Setup

### 1. Add Domain to Cloudflare

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click "Add a Site"
3. Enter your domain: `krishisahayak.com`
4. Choose Free plan (sufficient for initial setup)
5. Update nameservers as instructed

### 2. DNS Records

```
Type    Name                    Content                     TTL
A       @                      YOUR_K8S_INGRESS_IP         Auto
A       www                    YOUR_K8S_INGRESS_IP         Auto
A       api                    YOUR_K8S_INGRESS_IP         Auto
A       ml-api                 YOUR_K8S_INGRESS_IP         Auto
CNAME   app                    krishisahayak.com           Auto
```

## 🔒 SSL/TLS Configuration

### 1. SSL/TLS Settings

- **Encryption Mode**: Full (strict)
- **Edge Certificates**: Universal SSL enabled
- **Always Use HTTPS**: ON
- **HTTP Strict Transport Security (HSTS)**: ON
- **Minimum TLS Version**: 1.2

### 2. Page Rules

```
URL Pattern: krishisahayak.com/*
Settings:
- Always Use HTTPS: ON
- Cache Level: Standard
- Browser Cache TTL: 1 month

URL Pattern: api.krishisahayak.com/*
Settings:
- Always Use HTTPS: ON
- Cache Level: Bypass
- Security Level: High
```

## 🛡️ Security Configuration

### 1. WAF (Web Application Firewall)

- **Security Level**: High
- **Bot Fight Mode**: ON
- **Challenge Passage**: 30 minutes
- **Browser Integrity Check**: ON

### 2. Rate Limiting Rules

```
Rule 1: API Rate Limiting
- When: URI Path contains "/analyze_crop"
- Then: Rate limit to 10 requests per minute per IP
- Action: Block for 1 hour

Rule 2: General Rate Limiting
- When: URI Path contains "/api/"
- Then: Rate limit to 100 requests per minute per IP
- Action: Challenge for 1 hour
```

### 3. Firewall Rules

```
Rule 1: Block Suspicious Countries
- When: Country not in (US, IN, CA, GB, AU)
- Then: Block

Rule 2: Block Bad User Agents
- When: User Agent contains (bot, crawler, scanner)
- Then: Challenge

Rule 3: Allow API Access
- When: URI Path starts with "/api/" AND IP is whitelisted
- Then: Allow
```

## ⚡ Performance Optimization

### 1. Caching Rules

```
Rule 1: Static Assets
- When: URI Path matches "*.css, *.js, *.png, *.jpg, *.jpeg, *.gif, *.ico, *.svg"
- Then: Cache everything, Edge TTL: 1 month, Browser TTL: 1 year

Rule 2: API Responses
- When: URI Path starts with "/api/"
- Then: Cache nothing, Edge TTL: 0, Browser TTL: 0

Rule 3: HTML Pages
- When: URI Path matches "*.html"
- Then: Cache everything, Edge TTL: 1 hour, Browser TTL: 1 day
```

### 2. Speed Optimizations

- **Auto Minify**: CSS, HTML, JavaScript
- **Brotli Compression**: ON
- **Rocket Loader**: ON
- **Mirage**: ON (for mobile)
- **Polish**: Lossless

## 📊 Analytics & Monitoring

### 1. Cloudflare Analytics

- **Web Analytics**: ON
- **Bot Analytics**: ON
- **Security Analytics**: ON

### 2. Custom Headers

```
Response Headers:
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin
- Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'
```

## 🔧 Advanced Features

### 1. Workers (Optional)

```javascript
// Rate limiting worker
addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const ip = request.headers.get("CF-Connecting-IP");
  const url = new URL(request.url);

  // Check rate limit
  if (url.pathname.startsWith("/api/")) {
    const rateLimitKey = `rate_limit_${ip}`;
    const rateLimit = await RATE_LIMIT_KV.get(rateLimitKey);

    if (rateLimit && parseInt(rateLimit) > 100) {
      return new Response("Rate limit exceeded", { status: 429 });
    }

    await RATE_LIMIT_KV.put(rateLimitKey, (parseInt(rateLimit) || 0) + 1, {
      expirationTtl: 3600,
    });
  }

  return fetch(request);
}
```

### 2. Load Balancing

- **Health Check**: HTTP GET /health
- **Health Check Interval**: 30 seconds
- **Health Check Timeout**: 5 seconds
- **Health Check Retries**: 3
- **Pool Members**: Your Kubernetes ingress IPs

## 📱 Mobile Optimization

### 1. Mobile Redirects

- **Mobile Redirect**: OFF (handled by app)
- **Mirage**: ON (image optimization)
- **Polish**: Lossless (image compression)

### 2. Performance Settings

- **Rocket Loader**: ON
- **Auto Minify**: All enabled
- **Brotli**: ON
- **HTTP/2**: ON
- **HTTP/3**: ON

## 🚨 Monitoring & Alerts

### 1. Cloudflare Alerts

- **High Error Rate**: > 5% errors
- **High Bandwidth**: > 100GB/month
- **DDoS Attack**: Any DDoS detected
- **SSL Certificate**: Expiring in 30 days

### 2. Custom Monitoring

```bash
# Health check script
#!/bin/bash
curl -f https://api.krishisahayak.com/health || echo "API is down"
curl -f https://ml-api.krishisahayak.com/health || echo "ML API is down"
```

## 🔄 Deployment Checklist

- [ ] Domain added to Cloudflare
- [ ] DNS records configured
- [ ] SSL certificates issued
- [ ] WAF rules configured
- [ ] Rate limiting enabled
- [ ] Caching rules set
- [ ] Security headers added
- [ ] Monitoring alerts configured
- [ ] Load balancing configured
- [ ] Mobile optimization enabled

## 📞 Support

For Cloudflare-specific issues:

- **Documentation**: https://developers.cloudflare.com
- **Community**: https://community.cloudflare.com
- **Support**: Available in paid plans
