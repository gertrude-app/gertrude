'use client';

import cx from 'classnames';
import React, { useEffect, useRef } from 'react';

interface Props {
  className?: string;
  direction: `up` | `down` | `flat`;
}

const GraphSection: React.FC<Props> = ({ className, direction }) => {
  const ref = useRef<HTMLDivElement>(null);
  const [width, setWidth] = React.useState(0);
  const [height, setHeight] = React.useState(0);

  useEffect(() => {
    if (ref.current) {
      setWidth(ref.current.offsetWidth);
      setHeight(ref.current.offsetHeight);
    }
  }, []);

  return (
    <div
      className={cx(
        `transition-opacity duration-300`,
        !ref.current && `opacity-0`,
        className,
      )}
      ref={ref}
    >
      <svg viewBox={`0 0 ${width} ${height}`} width={width} height={height}>
        <path
          d={`M 0 ${direction === `up` ? height - 2 : direction === `down` ? 2 : 2} C ${
            width / 2
          } ${direction === `up` ? height - 2 : direction === `down` ? 2 : 2}, ${
            width / 2
          } ${direction === `up` ? 2 : direction === `down` ? height - 2 : 2}, ${width} ${
            direction === `up` ? 2 : direction === `down` ? height - 2 : 2
          }`}
          fill="none"
          stroke="#d946ef"
          strokeWidth="4"
        />
      </svg>
    </div>
  );
};

export default GraphSection;
