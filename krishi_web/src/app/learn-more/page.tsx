'use client'

import React from 'react';
import Image from 'next/image';
import { motion, useScroll, useTransform } from 'framer-motion';
import { Users, Target, Zap, ArrowLeft, Plane, Shield, Cloud } from 'lucide-react';
import Link from 'next/link';
import { useRef } from 'react';

const LearnMorePage: React.FC = () => {
  const founders = [
    { name: 'Piyush', imgSrc: '/Piyush 1.svg' },
    { name: 'Ayush', imgSrc: '/Ayush.svg' },
    { name: 'Divyanshu', imgSrc: '/Divyanshu.svg' },
    { name: 'Devansh', imgSrc: '/Devansh.svg' },
  ];

  const ref = useRef(null);
  const { scrollYProgress } = useScroll({ target: ref });

  return (
    <motion.div
      ref={ref}
      className="min-h-screen text-gray-800 bg-gradient-to-br from-green-100 via-blue-100 to-purple-100 relative overflow-hidden"
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
        <Link href="/" className="flex items-center space-x-2 text-white hover:text-green-700 transition-all duration-300 ease-in-out transform hover:-translate-x-1">
          <ArrowLeft className="w-6 h-6" />
        </Link>
      </motion.div>

      {/* Hero Section */}
      <motion.section
        className="relative py-28 md:py-40 flex items-center justify-center text-center bg-gradient-to-br from-green-600 to-blue-600 text-white shadow-xl overflow-hidden"
        initial={{ opacity: 0, y: -50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.7, ease: "easeOut" }}
      >
        {/* Parallax Background Layers */}
        <motion.div
          className="absolute inset-0 z-0"
          style={{
            backgroundColor: 'rgba(255, 255, 255, 0.05)', // Subtle background color
            y: useTransform(scrollYProgress, [0, 1], ["0%", "10%"]), // Adjust speed as needed
          }}
        />
        <motion.div
          className="absolute inset-0 z-0 opacity-30"
          style={{
            backgroundImage: 'radial-gradient(circle, #ffffff 1px, rgba(255,255,255,0) 1px)',
            backgroundSize: '30px 30px',
            y: useTransform(scrollYProgress, [0, 1], ["0%", "15%"]), // Adjust speed as needed
          }}
        />
        <div className="relative z-10 px-4">
          <motion.h1
            className="text-5xl md:text-7xl font-extrabold leading-tight mb-6 drop-shadow-md"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.3, ease: "easeOut" }}
          >
            Empowering Agriculture with AI
          </motion.h1>
          <motion.p
            className="text-xl md:text-2xl mt-5 max-w-4xl mx-auto font-light leading-relaxed"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.5, ease: "easeOut" }}
          >
            Krishi Sahayak is revolutionizing farming through advanced drone technologies and AI,
            providing intelligent solutions for sustainable growth and a prosperous future.
          </motion.p>
        </div>
      </motion.section>

      <main className="container mx-auto px-6 py-16">
        {/* Our Mission Section */}
        <motion.section
          className="mb-20 text-center group"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-xl transform group-hover:scale-110 group-hover:shadow-2xl transition-all duration-300 ease-in-out">
            <Target className="w-12 h-12" />
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-7 text-green-700 tracking-tight drop-shadow-md">Our Mission: Cultivating a Smarter Future</h2>
          <p className="text-xl md:text-2xl max-w-4xl mx-auto leading-relaxed text-gray-700 font-light">
            Krishi Sahayak is on a mission to transform agriculture by equipping farmers with the latest technology. Our platform offers advanced tools for crop analysis, early disease detection, and precise weather insights, enabling data-driven decisions, improved yields, and sustainable farming. We envision a future where smart farming ensures food security and protects our environment for generations.
          </p>
        </motion.section>

        {/* Key Features Section */}
        <motion.section
          className="mb-20 text-center group"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-xl transform group-hover:scale-110 group-hover:shadow-2xl transition-all duration-300 ease-in-out">
            <Zap className="w-12 h-12" />
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-7 text-green-700 tracking-tight drop-shadow-md">Key Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <FeatureItem
              title="AI Crop Disease Detection"
              description="Early warnings protect crops before diseases spread widely."
              icon={<Shield className="w-6 h-6" />}
            />
            <FeatureItem
              title="Drone Technologies Marketplace"
              description="Buy, sell, and rent agricultural drones and related services."
              icon={<Plane className="w-6 h-6" />}
            />
            <FeatureItem
              title="Regional Language Support"
              description="Insights into crop diseases in your local language."
              icon={<Cloud className="w-6 h-6" />}
            />
          </div>
        </motion.section>

       {/* Drone Technologies Section */}
       <motion.section
         className="mb-20 text-center group"
         initial={{ opacity: 0, y: 50 }}
         whileInView={{ opacity: 1, y: 0 }}
         viewport={{ once: true }}
         transition={{ duration: 0.6, ease: "easeOut" }}
       >
         <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-xl transform group-hover:scale-110 group-hover:shadow-2xl transition-all duration-300 ease-in-out">
           <Plane className="w-12 h-12" />
         </div>
         <h2 className="text-4xl md:text-5xl font-extrabold mb-7 text-blue-700 tracking-tight drop-shadow-md">Drone Technologies in Agriculture</h2>
         <p className="text-xl md:text-2xl max-w-4xl mx-auto leading-relaxed text-gray-700 font-light">
           Krishi Sahayak leverages cutting-edge drone technologies to revolutionize farming practices. Our platform facilitates a marketplace for buying, selling, and renting agricultural drones and related services. These drones are instrumental in aerial imaging for crop health monitoring, precise pesticide and fertilizer application, and efficient field mapping, leading to optimized resource management and increased yields.
         </p>
       </motion.section>

        {/* Our Incubator Section */}
        <motion.section
          className="mb-20 bg-white p-10 md:p-20 rounded-3xl shadow-xl border border-gray-100 transform hover:scale-[1.01] transition-transform duration-500 ease-in-out"
          initial={{ opacity: 0, scale: 0.9 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, ease: "easeOut" }}
        >
          <div className="flex flex-col md:flex-row items-center gap-12">
            <div className="md:w-1/3 flex justify-center">
              <Image src="/NIELIT 1.svg" alt="NIELIT Odisha" width={350} height={350} className="rounded-lg" />
            </div>
            <div className="md:w-2/3">
              <div className="hidden md:inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-xl">
                <Zap className="w-12 h-12" />
              </div>
              <h2 className="text-5xl md:text-6xl font-extrabold mb-8 text-gray-900 tracking-tight drop-shadow-md">Our Incubator: Nurturing Innovation</h2>
              <h3 className="text-3xl md:text-4xl font-semibold text-green-700 mb-6 drop-shadow-md">NIELIT Bhubaneshwar</h3>
              <p className="text-xl leading-relaxed text-gray-700 font-light">
                We are immensely proud to be incubated by the National Institute of Electronics & Information Technology (NIELIT), Odisha. NIELIT has been instrumental in our journey, providing invaluable mentorship, state-of-the-art resources, and a supportive ecosystem that has enabled us to innovate and grow. Their unwavering commitment to fostering technological advancements aligns perfectly with our vision, propelling us towards our ambitious goals.
              </p>
            </div>
          </div>
        </motion.section>

        {/* Meet Our Founders Section */}
        <section className="text-center">
          <div className="inline-block bg-gradient-to-br from-green-600 to-blue-600 text-white p-6 rounded-full mb-8 shadow-xl">
            <Users className="w-12 h-12" />
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-20 text-gray-900 tracking-tight drop-shadow-md">Meet Your Sahayaks</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-y-16 gap-x-10">
            {founders.map((founder, index) => (
              <motion.div
                key={founder.name}
                className="text-center group"
                initial={{ opacity: 0, y: 25 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.15, ease: "easeOut" }}
              >
                <div className="relative w-60 h-60 mx-auto mb-7 shadow-xl rounded-full overflow-hidden transform group-hover:scale-105 group-hover:shadow-2xl transition-transform duration-300 border-4 border-white group-hover:border-blue-600">
                  <Image
                    src={founder.imgSrc}
                    alt={founder.name}
                    fill
                    style={{ objectFit: 'cover' }}
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
        className="bg-gradient-to-br from-green-600 to-blue-600 text-white py-28 text-center shadow-xl"
        initial={{ opacity: 0, y: 50 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      >
        <div className="container mx-auto px-6">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-7 leading-tight drop-shadow-md">Ready to Transform Your Farm?</h2>
          <p className="text-xl md:text-2xl max-w-3xl mx-auto mb-12 font-light">
            Discover how Krishi Sahayak&apos;s innovative solutions can boost your productivity and ensure a sustainable future.
          </p>
          <Link href="/" className="bg-green-500 text-white px-12 py-5 rounded-full text-xl font-bold hover:bg-green-600 hover:scale-105 transition-all duration-300 ease-in-out shadow-xl">
            Explore Our Solutions
          </Link>
        </div>
      </motion.section>
    </motion.div>
  );
};

export default LearnMorePage;

const FeatureItem: React.FC<{ title: string; description: string; icon: React.ReactNode }> = ({ title, description, icon }) => (
  <div className="text-center p-6 rounded-xl bg-white/70 backdrop-blur-md shadow-subtle">
    <div className="inline-flex items-center justify-center w-14 h-14 bg-gradient-to-br from-green-100 to-blue-100 text-green-600 rounded-full mb-3 shadow-inner">
      {icon}
    </div>
    <h3 className="text-lg font-medium text-gray-900 mb-1.5">{title}</h3>
    <p className="text-gray-600 text-sm">{description}</p>
  </div>
);