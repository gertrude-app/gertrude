import React from 'react';

interface Props {
  className?: string;
  children: React.ReactNode;
  // add more as needed
  type: 'primary';
  onClick(): void;
}

const ButtonPrimary: React.FC<Props> = ({ className, children, onClick, type }) => {
  return (
    <button
      className={`${className} ${
        type === `primary`
          ? `bg-white border-white text-violet-500 hover:bg-violet-50 hover:border-violet-50`
          : ``
      } border-2 px-5 py-2 font-bold rounded-lg transition duration-100`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};

export default ButtonPrimary;
