import { NextResponse } from 'next/server';
import axios from 'axios';

const ML_SERVER_URL = process.env.NEXT_PUBLIC_ML_SERVER_URL || 'http://35.222.33.77';

async function convertFileToBase64(file: File): Promise<string> {
  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const base64 = buffer.toString('base64');
  const mimeType = file.type;
  return `data:${mimeType};base64,${base64}`;
}

export async function POST(request: Request) {
  if (!ML_SERVER_URL) {
    return NextResponse.json({ error: 'ML Server URL not configured' }, { status: 500 });
  }

  try {
    const formData = await request.formData();
    const imageFile = formData.get('image') as File;

    if (!imageFile) {
      return NextResponse.json({ error: 'No image file provided' }, { status: 400 });
    }

    const base64ImageWithPrefix = await convertFileToBase64(imageFile);
    const base64Image = base64ImageWithPrefix.split(',')[1];

    const mlResponse = await axios.post(`${ML_SERVER_URL}/analyze_crop`, {
      image: base64Image,
    }, {
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    });

    return NextResponse.json(mlResponse.data);
  } catch (error) {
    console.error('Error during ML analysis:', error);
    if (axios.isAxiosError(error) && error.response) {
      return NextResponse.json({ error: error.response.data }, { status: error.response.status });
    }
    return NextResponse.json({ error: 'Failed to perform ML analysis' }, { status: 500 });
  }
}
