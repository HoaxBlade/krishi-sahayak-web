import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Krishi Sahayak",
  description: "Revolutionizing agriculture with AI-powered crop analysis and weather insights.",
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/webicon.png', sizes: '32x32', type: 'image/png' },
      { url: '/webicon.png', sizes: '16x16', type: 'image/png' },
    ],
    apple: [
      { url: '/webicon.png', sizes: '180x180', type: 'image/png' },
    ],
    shortcut: '/favicon.ico',
  },
};