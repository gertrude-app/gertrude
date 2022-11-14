import React, { useState } from 'react';
import Testimonial from './Testimonial';

const TestimonialsBlock: React.FC = () => {
  const [testimonialIndex, setTestimonialIndex] = useState(0);
  return (
    <section className="bg-gray-50 relative h-[28rem] sm:h-[24rem] flex justify-center items-center overflow-hidden">
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-52 -bottom-96 z-10" />
      <div className="absolute bottom-12 flex space-x-2">
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 0 ? `bg-gray-400` : `bg-gray-300 shadow-inner`
          }`}
          onClick={() => setTestimonialIndex(0)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 1 ? `bg-gray-400` : `bg-gray-300 shadow-inner`
          }`}
          onClick={() => setTestimonialIndex(1)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 2 ? `bg-gray-400` : `bg-gray-300 shadow-inner`
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
        I'm a bit biased because I made it, but I use Gertrude with all of my kids and
        would be devastated if I had to go back to what I was using before. It's safer and
        much easier to use, and I feel more comfortable with my kids' online activity than
        I ever have.
      </Testimonial>
      <button
        className="absolute w-12 h-12 bg-white rounded-full flex justify-center items-center shadow-lg text-gray-500 right-16 bottom-8 lg:bottom-auto hover:bg-violet-50 transition duration-50 z-20"
        onClick={() => {
          if (testimonialIndex < 2) {
            setTestimonialIndex(testimonialIndex + 1);
          } else {
            setTestimonialIndex(0);
          }
        }}
      >
        <i className="fa-solid fa-chevron-right" />
      </button>
      <button
        className="absolute w-12 h-12 bg-white rounded-full flex justify-center items-center shadow-lg text-gray-500 left-16 bottom-8 lg:bottom-auto hover:bg-violet-50 transition duration-50 z-20"
        onClick={() => {
          if (testimonialIndex > 0) {
            setTestimonialIndex(testimonialIndex - 1);
          } else {
            setTestimonialIndex(2);
          }
        }}
      >
        <i className="fa-solid fa-chevron-left" />
      </button>
    </section>
  );
};

export default TestimonialsBlock;
