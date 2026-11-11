import React from 'react';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { type CustomerTestimonial, homeTestimonials } from '@/lib/customer-testimonials';

const midpoint = Math.ceil(homeTestimonials.length / 2);
const testimonialRows = [
  homeTestimonials.slice(0, midpoint),
  homeTestimonials.slice(midpoint),
];

const HomeTestimonialsSection: React.FC = () => (
  <section
    id="testimonials"
    aria-labelledby="testimonials-heading"
    className="scroll-mt-24 border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="overflow-hidden bg-stone-50 py-16 sm:py-20">
      <h2
        id="testimonials-heading"
        className="mx-auto mb-14 max-w-2xl px-6 text-balance text-center text-2xl font-medium !leading-[1.2] tracking-[-0.035em] text-stone-950 sm:mb-16 sm:text-3xl lg:text-4xl"
      >
        Real relief, in their own words.
      </h2>
      <div
        role="region"
        aria-label="Customer reviews"
        tabIndex={0}
        className="home-testimonials-row home-testimonials-column sm:hidden focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-violet-500"
      >
        <div
          className="home-testimonials-marquee-track home-testimonials-marquee-track-vertical"
          style={
            {
              '--home-marquee-duration': `${homeTestimonials.length * 13}s`,
            } as React.CSSProperties
          }
        >
          {[0, 1].map((copy) => (
            <ul
              key={copy}
              aria-hidden={copy === 1 ? true : undefined}
              className={`home-testimonials-group flex flex-col gap-12 px-8 pt-12 ${copy === 1 ? `home-testimonials-copy` : ``}`}
            >
              {homeTestimonials.map((testimonial) => (
                <li key={testimonial.id} className="home-testimonials-item min-w-0">
                  <Testimonial testimonial={testimonial} />
                </li>
              ))}
            </ul>
          ))}
        </div>
      </div>
      <div className="hidden space-y-10 sm:block sm:space-y-12">
        {testimonialRows.map((testimonials, rowIndex) => (
          <div
            key={rowIndex}
            role="region"
            aria-label={`Customer reviews, row ${rowIndex + 1} of 2`}
            tabIndex={0}
            className="home-testimonials-row focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-violet-500"
          >
            <div
              className={`home-testimonials-marquee-track ${rowIndex === 1 ? `home-testimonials-marquee-track-reverse` : ``}`}
              style={
                {
                  '--home-marquee-duration': `${testimonials.length * (rowIndex === 0 ? 20 : 22)}s`,
                } as React.CSSProperties
              }
            >
              {[0, 1].map((copy) => (
                <ul
                  key={copy}
                  aria-hidden={copy === 1 ? true : undefined}
                  className={`home-testimonials-group flex shrink-0 gap-12 pr-12 sm:gap-16 sm:pr-16 ${copy === 1 ? `home-testimonials-copy` : ``}`}
                >
                  {testimonials.map((testimonial) => (
                    <li
                      key={testimonial.id}
                      className="home-testimonials-item w-[min(84vw,28rem)] shrink-0"
                    >
                      <Testimonial testimonial={testimonial} />
                    </li>
                  ))}
                </ul>
              ))}
            </div>
          </div>
        ))}
      </div>
    </HomeSectionRails>
  </section>
);

export default HomeTestimonialsSection;

const Testimonial: React.FC<{ testimonial: CustomerTestimonial }> = ({ testimonial }) => {
  const [beforeEmphasis, afterEmphasis] = testimonial.emphasis
    ? testimonial.quote.split(testimonial.emphasis)
    : [testimonial.quote];

  return (
    <figure className="flex h-full flex-col justify-center text-center">
      <blockquote>
        <p className="text-base font-normal !leading-[1.55] tracking-[-0.02em] text-stone-700 sm:text-lg">
          “{beforeEmphasis}
          {testimonial.emphasis && (
            <span className="font-medium text-violet-700">{testimonial.emphasis}</span>
          )}
          {afterEmphasis}”
        </p>
      </blockquote>
      {testimonial.name && (
        <figcaption className="mt-4 text-xs leading-5 text-stone-500">
          {testimonial.name}
        </figcaption>
      )}
    </figure>
  );
};
