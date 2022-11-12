import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';

interface Props {
  children: string;
  heading: string;
  icon: string;
  side: 'right' | 'left';
}

const Feature: React.FC<Props> = ({ children, icon, side, heading }) => {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);

  const options: IntersectionObserverInit = {
    rootMargin: '0px',
    threshold: 1,
  };

  useEffect(() => {
    const observer = new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        setVisible(entry.isIntersecting);
        if (entry.isIntersecting) {
          observer.unobserve(entry.target);
        }
      });
    }, options);

    if (ref.current) observer.observe(ref.current);

    return () => {
      if (ref.current) observer.unobserve(ref.current);
    };
  }, [ref, options]);

  return (
    <div
      className={cx(
        'm-6 [transition:200ms] flex items-center relative z-20',
        visible
          ? cx('opacity-100', side === 'left' ? '-rotate-3' : 'rotate-3')
          : 'opacity-0 scale-90 translate-y-6',
        side === 'left' ? 'mr-96 flex-row-reverse' : 'ml-96 flex-row',
      )}
      ref={ref}
    >
      <div
        className={cx(
          'w-24 h-24 bg-white shadow-md flex justify-center items-center rounded-2xl',
          side === 'left' ? 'ml-8' : 'mr-8',
        )}
      >
        <i
          aria-hidden
          className={`fa fa-${icon} text-3xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent`}
        />
      </div>
      <div className="shadow-lg rounded-2xl w-128 p-8 sm:p-12 sm:pb-10 flex flex-col items-start relative bg-white z-20 overflow-hidden">
        <div className="w-128 h-128 absolute rotate-12 bg-gray-50 left-80 -top-52" />
        <h3 className="text-xl font-bold mb-2 text-gray-700 relative">{heading}</h3>
        <p className="text-lg text-gray-400 leading-7 relative">{children}</p>
      </div>
    </div>
  );
};

export default Feature;
