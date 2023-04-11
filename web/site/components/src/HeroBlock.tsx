import React from 'react';
import cx from 'classnames';

const HeroBlock: React.FC = () => (
  <section className="flex justify-center items-center sm:p-20 p-10 pt-20 bg-gradient-to-b from-violet-500 to-fuchsia-500 relative z-10">
    <h1
      className={cx(
        `lg:text-6xl text-5xl font-extrabold text-center leading-[120%] text-white text-opacity-60`,
      )}
    >
      Finally, real{` `}
      <span className="text-white text-opacity-90">internet safety</span>
      {` `}
      is possible
    </h1>
  </section>
);

export default HeroBlock;
