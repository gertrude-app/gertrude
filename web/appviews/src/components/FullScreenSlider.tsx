import React from 'react';
import cx from 'classnames';

interface Props {
  pages: React.ReactNode[];
  index: number;
}

const FullScreenSlider: React.FC<Props> = ({ pages, index }) => (
  <div className="h-screen w-screen relative bg-white dark:bg-slate-900 overflow-hidden">
    {pages.map((page, i) => (
      <div
        className={cx(
          `w-full h-full absolute top-0 duration-300 transition-[left,opacity]`,
          i < index && `-left-full opacity-0`,
          i === index && `left-0 opacity-100`,
          i > index && `left-full opacity-0`,
        )}
      >
        {page}
      </div>
    ))}
  </div>
);

export default FullScreenSlider;
