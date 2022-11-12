import React, { useState } from 'react';
import Testimonial from './Testimonial';

const TestimonialsBlock: React.FC = () => {
  const [testimonialIndex, setTestimonialIndex] = useState(0);
  return (
    <section className="bg-gray-50 relative h-128 flex justify-center items-center overflow-hidden">
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-52 -bottom-96 z-10" />
      <div className="absolute bottom-12 flex space-x-2">
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 0 ? 'bg-gray-400' : 'bg-gray-300 shadow-inner'
          }`}
          onClick={() => setTestimonialIndex(0)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 1 ? 'bg-gray-400' : 'bg-gray-300 shadow-inner'
          }`}
          onClick={() => setTestimonialIndex(1)}
        />
        <div
          className={`relative z-20 w-3 h-3 transition duration-100 cursor-pointer hover:scale-110 rounded-full ${
            testimonialIndex === 2 ? 'bg-gray-400' : 'bg-gray-300 shadow-inner'
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
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Suscipit hic, quae maxime
        officia commodi dolorum id fuga molestiae eaque similique sint ipsa soluta eius
        eveniet alias nesciunt, eos sed in?
      </Testimonial>
      <Testimonial name="Jared H." index={2} testimonialIndex={testimonialIndex}>
        I'm a bit biased because I made it, but I use Gertrude with all four of my kids
        and would be devastated if it didn't exist. It's so much easier to use, and I feel
        much more comfortable with my kids' online activity than I did before.
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
