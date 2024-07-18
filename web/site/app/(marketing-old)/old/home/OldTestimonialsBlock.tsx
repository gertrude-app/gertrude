'use client';

import React, { useState } from 'react';
import Testimonial from './Testimonial';

const TestimonialsBlock: React.FC = () => {
  const [testimonialIndex, setTestimonialIndex] = useState(0);
  return (
    <section className="bg-slate-50 relative h-[28rem] sm:h-[24rem] flex justify-center items-center overflow-hidden">
      <div className="absolute bottom-12 flex space-x-2">
        <div
          className={`relative z-20 w-3 h-3 transition-[background-color,transform] duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 0 ? `bg-slate-400` : `bg-slate-300 shadow-inner`
          }`}
          onClick={() => setTestimonialIndex(0)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition-[background-color,transform] duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 1 ? `bg-slate-400` : `bg-slate-300 shadow-inner`
          }`}
          onClick={() => setTestimonialIndex(1)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition-[background-color,transform] duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 2 ? `bg-slate-400` : `bg-slate-300 shadow-inner`
          }`}
          onClick={() => setTestimonialIndex(2)}
        />
      </div>
      <Testimonial name="Jason H." index={0} testimonialIndex={testimonialIndex}>
        I spent years trying out different parental control software for my four kids (on
        both Macs and PCs) and never found anything that made me feel peaceful and secure
        about my kids' online activities until I started using Gertrude.
      </Testimonial>
      <Testimonial name="Dr. Frank A." index={1} testimonialIndex={testimonialIndex}>
        We have used Gertrude for our two children for the past few years and have found
        it to be absolutely the most secure product available. The app makes securing
        children online something manageable for us as middle-aged parents with typical
        computer skills.
      </Testimonial>
      <Testimonial name="Jared H." index={2} testimonialIndex={testimonialIndex}>
        I take online safety very seriously. I needed a bulletproof mac internet filter
        for my kids. When I couldn't find anything up to my standards, I built Gertrude.
        I'm biased, but I think it's the best tool out there for mac website blocking and
        oversight with keylogging and screenshots.
      </Testimonial>
      <button
        className="absolute w-12 h-12 bg-white rounded-full flex justify-center items-center border border-slate-200 text-slate-500 right-16 bottom-8 lg:bottom-auto hover:bg-slate-50 active:bg-slate-100 active:scale-95 transition-[transform,background-color] duration-50 z-20"
        onClick={() => {
          if (testimonialIndex < 2) {
            setTestimonialIndex(testimonialIndex + 1);
          } else {
            setTestimonialIndex(0);
          }
        }}
      >
        <i aria-hidden className="fa-solid fa-chevron-right" />
      </button>
      <button
        className="absolute w-12 h-12 bg-white rounded-full flex justify-center items-center border border-slate-200 text-slate-500 left-16 bottom-8 lg:bottom-auto hover:bg-slate-50 active:bg-slate-100 active:scale-95 transition-[transform,background-color] duration-50 z-20"
        onClick={() => {
          if (testimonialIndex > 0) {
            setTestimonialIndex(testimonialIndex - 1);
          } else {
            setTestimonialIndex(2);
          }
        }}
      >
        <i aria-hidden className="fa-solid fa-chevron-left" />
      </button>
    </section>
  );
};

export default TestimonialsBlock;
