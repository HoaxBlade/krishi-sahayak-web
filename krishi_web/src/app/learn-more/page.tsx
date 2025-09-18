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
    <motion.div
      className="min-h-screen text-gray-800 bg-gradient-to-br from-green-200 via-blue-100 to-white"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.25 }}
    >
      {/* Back to Home Button */}
      <motion.div
        className="absolute top-6 left-6 z-20"
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.5, delay: 0.8 }}
      >
        <Link href="/" className="flex items-center space-x-2 text-gray-700 hover:text-green-700 transition-all duration-300 ease-in-out transform hover:-translate-x-1">
          <ArrowLeft className="w-6 h-6" />
          <span className="font-semibold text-lg">Back to Home</span>
        </Link>
      </motion.div>

      {/* Hero Section */}
      <motion.section
        className="relative py-28 md:py-40 flex items-center justify-center text-center bg-gradient-to-br from-green-600 to-blue-600 text-white shadow-2xl overflow-hidden"
        initial={{ opacity: 0, y: -50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
      >
        <div className="relative z-10 px-4">
          <motion.h1
            className="text-5xl md:text-7xl font-extrabold leading-tight mb-6 drop-shadow-xl"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.3 }}
          >
            Empowering Agriculture with AI
          </motion.h1>
          <motion.p
            className="text-xl md:text-2xl mt-5 max-w-4xl mx-auto font-light leading-relaxed"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.5 }}
          >
            Krishi Sahayak is revolutionizing farming through advanced AI,
            providing intelligent solutions for sustainable growth and a prosperous future.
          </motion.p>
        </div>
      </motion.section>

      <main className="container mx-auto px-6 py-16">
        {/* Our Mission Section */}
        <motion.section
          className="mb-20 text-center"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
        >
          <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-2xl">
            <Target className="w-12 h-12" />
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-7 text-green-700 tracking-tight drop-shadow-sm">Our Mission: Cultivating a Smarter Future</h2>
          <p className="text-xl md:text-2xl max-w-4xl mx-auto leading-relaxed text-gray-700 font-light">
            Krishi Sahayak is dedicated to revolutionizing the agricultural sector by empowering farmers with cutting-edge technology. Our platform provides advanced tools for crop analysis, disease detection, and real-time weather forecasting to help farmers make informed decisions, increase productivity, and ensure sustainable farming practices. We aim to foster a new era of smart farming, ensuring food security and environmental stewardship for generations to come.
          </p>
        </motion.section>

        {/* Our Incubator Section */}
        <motion.section
          className="mb-20 bg-white p-10 md:p-20 rounded-3xl shadow-3xl border border-gray-100 transform hover:scale-[1.01] transition-transform duration-500 ease-in-out"
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
              <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-2xl">
                <Zap className="w-12 h-12" />
              </div>
              <h2 className="text-4xl md:text-5xl font-extrabold mb-7 text-gray-900 tracking-tight drop-shadow-sm">Our Incubator: Nurturing Innovation</h2>
              <h3 className="text-2xl md:text-3xl font-semibold text-green-700 mb-5">NIELIT Bhubaneshwar</h3>
              <p className="text-xl leading-relaxed text-gray-700 font-light">
                We are immensely proud to be incubated by the National Institute of Electronics & Information Technology (NIELIT), Odisha. NIELIT has been instrumental in our journey, providing invaluable mentorship, state-of-the-art resources, and a supportive ecosystem that has enabled us to innovate and grow. Their unwavering commitment to fostering technological advancements aligns perfectly with our vision, propelling us towards our ambitious goals.
              </p>
            </div>
          </div>
        </motion.section>

        {/* Meet Our Founders Section */}
        <section className="text-center">
          <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-2xl">
            <Users className="w-12 h-12" />
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-20 text-gray-900 tracking-tight drop-shadow-sm">Meet Our Visionary Sahayaks</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-y-16 gap-x-10">
            {founders.map((founder, index) => (
              <motion.div
                key={founder.name}
                className="text-center group"
                initial={{ opacity: 0, y: 25 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
              >
                <div className="relative w-60 h-60 mx-auto mb-7 shadow-3xl rounded-full overflow-hidden transform group-hover:scale-105 transition-transform duration-300 border-4 border-white group-hover:border-blue-600">
                  <Image
                    src={founder.imgSrc}
                    alt={founder.name}
                    layout="fill"
                    objectFit="cover"
                    className="rounded-full"
                  />
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mt-4">{founder.name}</h3>
              </motion.div>
            ))}
          </div>
        </section>
      </main>

      {/* Call to Action Section */}
      <motion.section
        className="bg-gradient-to-br from-green-600 to-blue-600 text-white py-28 text-center shadow-3xl"
        initial={{ opacity: 0, y: 50 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.25}}
      >
        <div className="container mx-auto px-6">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-7 leading-tight drop-shadow-md">Ready to Transform Your Farm?</h2>
          <p className="text-xl md:text-2xl max-w-3xl mx-auto mb-12 font-light">
            Discover how Krishi Sahayak&apos;s innovative solutions can boost your productivity and ensure a sustainable future.
          </p>
          <Link href="/" className="bg-white text-green-700 px-12 py-5 rounded-full text-xl font-bold hover:bg-gray-100 hover:scale-105 transition-all duration-300 ease-in-out shadow-xl">
            Explore Our Solutions
          </Link>
        </div>
      </motion.section>
    </motion.div>
  );
};

export default LearnMorePage;