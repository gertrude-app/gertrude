import React from 'react';

const LoadingSpinner: React.FC<{ text?: string }> = ({ text }) => (
  <div className="bg-white p-3 rounded-full relative">
    {/* to prevent missing focus trap errors when rendering alone in a modal */}
    <input type="text" className="w-0 h-0 opacity-0 sr-only absolute -left-11" />
    <div className="flex flex-col items-center justify-center">
      <div className="animate-spin border-t-fuchsia-500 rounded-full border-[6px] border-t-[6px] border-slate-200 h-10 w-10" />
      {text && (
        <h2 className="absolute tracking-wide w-screen animate-pulse text-center text-white -bottom-8 text-sm uppercase">
          {text}
        </h2>
      )}
    </div>
  </div>
);

export default LoadingSpinner;
