import React from 'react';
import cx from 'classnames';

interface Props {
  pages: React.ReactNode[];
  index: number;
}

const FullScreenSlider: React.FC<Props> = ({ pages, index }) => (
  <div className="h-screen w-screen relative bg-white dark:bg-slate-900">
    {pages.map((page, i) => (
      <div
        className={cx(
          `w-full h-full absolute top-0 [transition:300ms]`,
          i < index && `-left-full`,
          i === index && `left-0`,
          i > index && `left-full`,
        )}
      >
        {page}
      </div>
    ))}
  </div>
);

export default FullScreenSlider;
