import React from 'react';

const Loading: React.FC<{ text?: string }> = ({ text }) => (
  <div className="bg-white p-3 rounded-full">
    <div className="flex flex-col items-center justify-center">
      <div className="animate-spin border-t-fuchsia-500 rounded-full border-[6px] border-t-[6px] border-gray-200 h-10 w-10" />
      {/* to prevent missing focus trap errors when rendering alone in a modal */}
      <input type="text" className="w-0 h-0 opacity-0 sr-only absolute -left-11" />
      {text && (
        <h2 className="animate-pulse text-center text-gray-400 text-xs uppercase font-light antialiased">
          {text}
        </h2>
      )}
    </div>
  </div>
);

export default Loading;
