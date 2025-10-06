# 🌾 Krishi Sahayak Web Application

A modern Next.js web application for AI-powered agricultural management, built to complement the Flutter mobile app.

## 🚀 Features

### 🤖 AI-Powered Crop Analysis

- Upload crop images for instant health analysis
- Real-time disease detection and recommendations
- Confidence scoring and detailed predictions
- Integration with Kubernetes ML server

### 🌤️ Weather Dashboard

- Real-time weather data from OpenWeatherMap API
- Location-based weather forecasts
- Farming recommendations based on weather conditions
- Multiple city support

### 📊 Farming Dashboard

- System status monitoring
- Recent analysis history
- Performance metrics and statistics
- Real-time ML server health checks

### 🎨 Modern UI/UX

- Responsive design for all devices
- Smooth animations with Framer Motion
- Beautiful gradient backgrounds
- Intuitive navigation

## 🛠️ Tech Stack

- **Frontend**: Next.js 14 with TypeScript
- **Styling**: Tailwind CSS
- **Animations**: Framer Motion
- **Icons**: Lucide React
- **HTTP Client**: Axios
- **Database**: Supabase
- **ML Server**: Kubernetes-hosted Python service

## 🔧 Environment Variables

Create a `.env.local` file with the following variables:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# ML Server Configuration
NEXT_PUBLIC_ML_SERVER_URL=http://35.222.33.77

# Weather API Configuration
NEXT_PUBLIC_OPENWEATHERMAP_API_KEY=your_openweathermap_api_key

# App Configuration
NEXT_PUBLIC_APP_NAME=Krishi Sahayak
NEXT_PUBLIC_APP_VERSION=1.0.0
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Access to the Kubernetes ML server

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd krishi_web
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Set up environment variables**

   ```bash
   cp .env.example .env.local
   # Edit .env.local with your actual values
   ```

4. **Start the development server**

   ```bash
   npm run dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 📱 Pages

### 🏠 Home Page (`/`)

- Hero section with feature overview
- Real-time system status
- Weather information
- Feature highlights

### 🔍 Crop Analysis (`/analyze`)

- Image upload interface
- AI-powered crop health analysis
- Detailed results and recommendations
- Confidence scoring

### 🌤️ Weather Dashboard (`/weather`)

- Location-based weather data
- Farming recommendations
- Multiple city support
- Real-time updates

### 📊 Dashboard (`/dashboard`)

- System monitoring
- Recent analyses
- Performance metrics
- Status indicators

## 🔌 API Integration

### ML Server Integration

- **Health Check**: `GET /health`
- **Crop Analysis**: `POST /analyze_crop`
- **Base URL**: `http://35.222.33.77`

### Weather API Integration

- **OpenWeatherMap API** for real-time weather data
- **Location-based** weather forecasts
- **Farming recommendations** based on conditions

### Supabase Integration

- **Database** for storing crop data
- **Real-time** updates
- **User management** (future feature)

## 🎨 Design System

### Colors

- **Primary**: Green (`#16a34a`)
- **Secondary**: Blue (`#2563eb`)
- **Background**: Gradient from green to blue
- **Text**: Gray scale

### Typography

- **Headings**: Bold, large sizes
- **Body**: Regular weight, readable sizes
- **Font**: System fonts (Inter, sans-serif)

### Components

- **Cards**: Rounded corners, shadows
- **Buttons**: Rounded, hover effects
- **Forms**: Clean inputs, validation
- **Navigation**: Responsive, mobile-friendly

## 🚀 Deployment

### Vercel (Recommended)

1. Connect your GitHub repository
2. Set environment variables
3. Deploy automatically

### Other Platforms

- **Netlify**: Static site generation
- **AWS**: Amplify or S3 + CloudFront
- **Google Cloud**: App Engine or Cloud Run

## 🔧 Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

### Project Structure

```
src/
├── app/                 # Next.js app directory
│   ├── analyze/         # Crop analysis page
│   ├── weather/         # Weather dashboard
│   ├── dashboard/       # Main dashboard
│   └── page.tsx         # Home page
├── components/          # Reusable components
├── lib/                 # Utility functions
│   ├── supabase.ts      # Database client
│   ├── mlService.ts     # ML server integration
│   └── weatherService.ts # Weather API integration
└── styles/              # Global styles
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:

- Create an issue on GitHub
- Contact the development team
- Check the documentation

## 🔗 Related Projects

- **Flutter App**: Mobile application
- **ML Server**: Kubernetes-hosted AI service
- **Database**: Supabase backend

---

**Built with ❤️ for farmers and agricultural innovation**
