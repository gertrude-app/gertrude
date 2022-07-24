import React from 'react';

type Props = {
  className?: string;
  type: 'green' | 'ok' | 'warning' | 'yellow' | 'red' | 'error' | 'blue' | 'info';
  children: React.ReactNode;
};

const PillBadge: React.FC<Props> = ({ type, className, children }) => {
  let colors = ``;

  switch (type) {
    case `green`:
    case `ok`:
      colors = `bg-green-200 text-green-800`;
      break;
    case `red`:
    case `error`:
      colors = `bg-red-200 text-red-800`;
      break;
    case `yellow`:
    case `warning`:
      colors = `bg-yellow-200 text-yellow-800`;
      break;
    case `blue`:
    case `info`:
      colors = `bg-indigo-200 text-indigo-800`;
      break;
  }

  return (
    <h3 className={`px-6 py-0.5 rounded-full max-w-fit ${colors} ${className}`}>
      {children}
    </h3>
  );
};

export default PillBadge;
