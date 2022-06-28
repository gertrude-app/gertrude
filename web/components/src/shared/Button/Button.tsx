import React from 'react';

interface Props {
  className?: string;
  onClick(): void;
  type: 'primary-violet' | 'primary-white' | 'secondary-violet' | 'secondary-white';
  children: string;
}

const Button: React.FC<Props> = ({ className, onClick, type, children }) => {
  let colors = ``;
  switch (type) {
    case `primary-violet`:
      colors = `bg-violet-500 text-white hover:bg-violet-600 border-2 border-violet-500 hover:border-violet-600 ring ring-white ring-offset-0 focus:ring-offset-4 focus:ring-violet-500`;
      break;
    case `primary-white`:
      colors = `bg-white text-violet-500 hover:bg-violet-50 border-2 border-white hover:border-violet-50 ring ring-violet-500 ring-offset-0 ring-offset-violet-500 focus:ring-offset-4 focus:ring-white`;
      break;
    case `secondary-violet`:
      colors = `bg-violet-500 text-white border-2 border-white hover:bg-violet-400 ring ring-violet-500 ring-offset-0 focus:ring-offset-4 focus:ring-white ring-offset-violet-500`;
      break;
    case `secondary-white`:
      colors = `bg-gray-50 text-gray-500 border hover:bg-gray-100 ring ring-white ring-offset-0 focus:ring-offset-4 focus:ring-indigo-400 focus:border-indigo-500`;
      break;
  }

  return (
    <button
      className={`${colors} py-2.5 px-10 shadow-sm rounded-lg text-lg font-bold [transition:100ms] outline-none ${className}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};

export default Button;
