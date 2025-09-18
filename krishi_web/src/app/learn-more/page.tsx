'use client'

import React from 'react';
import Image from 'next/image';
import { motion } from 'framer-motion';
import { Users, Target, Zap, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

const LearnMorePage: React.FC = () => {
  const founders = [
    { name: 'Piyush', imgSrc: '/Piyush.jpg' },
    { name: 'Ayush', imgSrc: '/Ayush.jpg' },
    { name: 'Divyanshu', imgSrc: '/Divyanshu.jpg' },
    { name: 'Devansh', imgSrc: '/Devansh.jpg' },
  ];

  return (
    <div className="bg-gray-50 min-h-screen text-gray-800">
      {/* Back to Home Button */}
      <motion.div
        className="absolute top-4 left-4 z-20"
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.5, delay: 1 }}
      >
        <Link href="/" className="flex items-center space-x-2 text-gray-600 hover:text-green-600 transition-colors">
          <ArrowLeft className="w-5 h-5" />
          <span className="font-medium">Back to Home</span>
        </Link>
      </motion.div>

      {/* Hero Section */}
      <motion.section
        className="relative h-96 flex items-center justify-center text-white"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
      >
        <Image
          src="/logo.jpg"
          alt="Farm background"
          layout="fill"
          objectFit="cover"
          className="absolute inset-0 z-0 filter brightness-50"
        />
        <div className="relative z-10 text-center">
          <motion.h1
            className="text-5xl md:text-6xl font-extrabold"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.3 }}
          >
            About Krishi Sahayak
          </motion.h1>
          <motion.p
            className="text-lg mt-4 max-w-2xl"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.5 }}
          >
            Pioneering the future of agriculture with technology and innovation.
          </motion.p>
        </div>
      </motion.section>

      <main className="container mx-auto px-4 py-16">
        {/* Our Mission Section */}
        <motion.section
          className="mb-20 text-center"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
        >
          <div className="inline-block bg-green-100 text-green-700 p-3 rounded-full mb-4">
            <Target className="w-8 h-8" />
          </div>
          <h2 className="text-4xl font-bold mb-4">Our Mission</h2>
          <p className="text-lg max-w-3xl mx-auto leading-relaxed">
            Krishi Sahayak is dedicated to revolutionizing the agricultural sector by empowering farmers with cutting-edge technology. Our platform provides advanced tools for crop analysis, disease detection, and real-time weather forecasting to help farmers make informed decisions, increase productivity, and ensure sustainable farming practices.
          </p>
        </motion.section>

        {/* Our Incubator Section */}
        <motion.section
          className="mb-20 bg-white p-12 rounded-2xl shadow-lg"
          initial={{ opacity: 0, scale: 0.9 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
        >
          <div className="flex flex-col md:flex-row items-center gap-12">
            <div className="md:w-1/3 flex justify-center">
              <Image src="/NIELIT.png" alt="NIELIT Odisha" width={250} height={250} className="rounded-lg" />
            </div>
            <div className="md:w-2/3">
              <div className="inline-block bg-blue-100 text-blue-700 p-3 rounded-full mb-4">
                <Zap className="w-8 h-8" />
              </div>
              <h2 className="text-4xl font-bold mb-4">Our Incubator</h2>
              <h3 className="text-2xl font-semibold text-green-700 mb-2">NIELIT Bhubaneshwar</h3>
              <p className="text-lg leading-relaxed">
                We are proud to be incubated by the National Institute of Electronics & Information Technology (NIELIT), Odisha. NIELIT has been instrumental in our journey, providing invaluable mentorship, resources, and a supportive ecosystem to innovate and grow.
              </p>
            </div>
          </div>
        </motion.section>

        {/* Meet Our Founders Section */}
        <section className="text-center">
          <div className="inline-block bg-red-100 text-red-700 p-3 rounded-full mb-4">
            <Users className="w-8 h-8" />
          </div>
          <h2 className="text-4xl font-bold mb-12">Meet Our Founders</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-10">
            {founders.map((founder, index) => (
              <motion.div
                key={founder.name}
                className="text-center group"
                initial={{ opacity: 0, y: 25 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
              >
                <div className="relative w-48 h-48 mx-auto mb-4 shadow-xl rounded-full overflow-hidden transform group-hover:scale-105 transition-transform duration-300">
                  <Image
                    src={founder.imgSrc}
                    alt={founder.name}
                    layout="fill"
                    objectFit="cover"
                    className="rounded-full"
                  />
                </div>
                <h3 className="text-xl font-semibold">{founder.name}</h3>
              </motion.div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
};

export default LearnMorePage;