import React from 'react';

interface VioletButtonProps {
  onClick(): void;
  children: React.ReactNode;
}

const VioletButton: React.FC<VioletButtonProps> = ({ onClick, children }) => (
  <button
    onClick={onClick}
    className="bg-gradient-to-b from-violet-400 dark:from-violet-500 to-violet-500 dark:to-violet-700 px-2 py-1 rounded-lg text-white font-medium shadow border-t border-white/40 hover:scale-105 hover:shadow-md transition-[transform,box-shadow] duration-100 cursor-default active:scale-95"
  >
    {children}
  </button>
);

export default VioletButton;
