import React, { useState, useEffect } from 'react';
import cx from 'classnames';

const HeroBlock: React.FC = () => {
  const [heading, setHeading] = useState('');
  const [finishedTyping, setFinishedTyping] = useState(false);
  const [loading, setLoading] = useState(false);
  const [blocked, setBlocked] = useState(false);
  const [index, setIndex] = useState(0);
  const letters = 'Finally, real internet safety is possible'.split('');

  useEffect(() => {
    setTimeout(() => {
      if (index < letters.length) {
        setHeading(heading + letters[index]);
        setIndex(index + 1);
      } else {
        setTimeout(() => setFinishedTyping(true), 1000);
        setTimeout(() => setLoading(true), 2000);
        setTimeout(() => {
          setBlocked(true);
          setLoading(false);
        }, 3000);
      }
    }, Math.random() * 50 + 40);
  }, [heading, setHeading]);

  return (
    <section className="flex justify-center items-center sm:p-20 p-10 py-20 bg-gradient-to-b from-violet-500 to-fuchsia-500">
      <h1
        className={cx(
          'lg:text-6xl text-5xl font-extrabold text-center leading-[120%] px-16 py-5 rounded-full [transition:500ms] flex items-center',
          finishedTyping
            ? 'text-black bg-white shadow-xl text-opacity-60'
            : 'text-white text-opacity-70',
        )}
      >
        <i
          className={cx(
            'fa-solid transition duration-300 mr-12 -ml-4',
            finishedTyping ? 'opacity-1' : 'opacity-0',
            loading ? 'fa-spinner animate-spin' : !blocked && 'fa-search',
            blocked
              ? 'fa-lock bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent'
              : 'text-gray-300',
          )}
        />
        <span
          dangerouslySetInnerHTML={{
            __html: heading.replace(
              'internet safety is possible',
              `<span style="color: ${
                finishedTyping ? 'rgba(0, 0, 0, 0.9)' : 'rgba(255, 255, 255, 1)'
              }; transition: 500ms;">internet safety</span> is possible`,
            ),
          }}
        ></span>{' '}
        <div
          className={`${
            finishedTyping ? 'bg-black' : 'bg-white'
          } w-1.5 h-14 left-1 relative inline-block fa-fade [--fa-animation-duration:1s] [--fa-fade-opacity:0.2]`}
        ></div>
      </h1>
    </section>
  );
};

export default HeroBlock;
