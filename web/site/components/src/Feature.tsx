import React from 'react';
import cx from 'classnames';
import { useIntersectionObserver } from '../../app/lib/hooks';

interface Props {
  children: string;
  heading: string;
  icon: string;
  side: 'right' | 'left';
}

const Feature: React.FC<Props> = ({ children, icon, side, heading }) => {
  const { ref, intersected } = useIntersectionObserver({
    rootMargin: `0px`,
    threshold: 0.75,
  });

  return (
    <div
      className={cx(
        `m-6 transition duration-200 flex items-center relative z-20`,
        intersected
          ? cx(`opacity-100`, side === `left` ? `md:-rotate-3` : `md:rotate-3`)
          : `opacity-0 scale-90 translate-y-6`,
        side === `left` ? `lg:mr-96 flex-row-reverse` : `lg:ml-96 flex-row`,
      )}
      ref={ref}
    >
      <div
        className={cx(
          `w-16 h-16 md:w-24 md:h-24 bg-white shadow-md flex justify-center items-center rounded-2xl absolute sm:relative z-30 -right-6 -top-6 sm:right-0 sm:top-0`,
          side === `left` ? `sm:ml-4 md:ml-8` : `sm:mr-4 md:mr-8`,
        )}
      >
        <i
          aria-hidden
          className={`fa fa-${icon} text-3xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent`}
        />
      </div>
      <div className="shadow-lg rounded-2xl sm:w-128 p-8 sm:p-12 sm:pb-10 flex flex-col items-start relative bg-white z-20 overflow-hidden">
        <div className="w-128 h-128 absolute rotate-12 bg-slate-50 left-80 -top-52" />
        <h3 className="text-xl font-bold mb-2 text-slate-700 relative">{heading}</h3>
        <p className="sm:text-lg text-base text-slate-400 leading-7 relative">
          {children}
        </p>
      </div>
    </div>
  );
};

export default Feature;
