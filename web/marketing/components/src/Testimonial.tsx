import React from 'react';
import cx from 'classnames';

interface Props {
  children: React.ReactNode;
  name: string;
  index: number;
  testimonialIndex: number;
}

const Testimonial: React.FC<Props> = ({ children, name, index, testimonialIndex }) => {
  return (
    <div
      className={cx(
        `w-screen h-full flex justify-center items-center absolute [transition:300ms]`,
        index < testimonialIndex && `-left-[100vw]`,
        index === testimonialIndex && `left-0`,
        index > testimonialIndex && `left-[100vw]`,
      )}
    >
      <div className="mx-8 sm:mx-0 w-full sm:w-[calc(100vw-140px)] md:max-w-xl lg:max-w-2xl flex flex-col items-center relative">
        <i className="fa-solid fa-quote-left absolute text-6xl text-gray-100 sm:text-gray-200 -left-8 sm:-left-16 -top-8" />
        <i className="fa-solid fa-quote-right absolute text-6xl text-gray-100 sm:text-gray-200 -right-8 sm:-right-16 bottom-4" />
        <p className="text-center text-gray-500 text-xl font-light leading-8 relative">
          {children}
        </p>
        <h3 className="mt-3 text-xl font-bold text-gray-700 relative">{name}</h3>
      </div>
    </div>
  );
};

export default Testimonial;
