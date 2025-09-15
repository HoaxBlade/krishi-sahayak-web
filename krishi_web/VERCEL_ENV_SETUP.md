# Vercel Environment Variables Setup

## Required Environment Variables

Configure these environment variables in your Vercel dashboard:

### 1. ML Server Configuration

```
NEXT_PUBLIC_ML_SERVER_URL=http://35.222.33.77
```

### 2. Supabase Configuration

```
NEXT_PUBLIC_SUPABASE_URL=https://wksrgiofitfylzzwwkfw.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indrc3JnaW9maXRmeWx6end3a2Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0NTIzNTMsImV4cCI6MjA3MzAyODM1M30.HqGk5PZhtWy2-OeeQExqUlRSMJKD6gU6JcuUIFGipck
```

### 3. Weather API Configuration

```
NEXT_PUBLIC_OPENWEATHERMAP_API_KEY=bf5945787401f51daf7ce7f1fe7a2779
```

### 4. App Configuration

```
NEXT_PUBLIC_APP_NAME=Krishi Sahayak
NEXT_PUBLIC_APP_VERSION=1.0.0
```

## How to Configure in Vercel

1. Go to your Vercel dashboard
2. Select your project
3. Go to Settings → Environment Variables
4. Add each variable above
5. Make sure to set them for Production, Preview, and Development environments
6. Redeploy your application

## Troubleshooting

### ML Server Issues

- Ensure `NEXT_PUBLIC_ML_SERVER_URL` is correctly set
- Check if the ML server at `http://35.222.33.77` is accessible
- Verify CORS settings on the ML server

### Weather API Issues

- Ensure `NEXT_PUBLIC_OPENWEATHERMAP_API_KEY` is correctly set
- Check if the API key is valid and has sufficient quota
- Verify the API endpoint is accessible from Vercel

### Database Issues

- Ensure `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are correctly set
- Check Supabase project status
- Verify database permissions
