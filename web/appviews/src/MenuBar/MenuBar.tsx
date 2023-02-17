import React from 'react';
import ArrowRotateRight from '../Icons/ArrowRotateRight';

const MenuBar: React.FC = () => (
  <div className="p-4 text-center select-none">
    <h1 className="font-inter text-3xl antialiased font-extrabold mb-2">Rad WebView</h1>
    <div className="inline-flex gap-2 cursor-pointer items-center justify-center px-4 py-0.5 hover:bg-gray-100 rounded-md">
      <ArrowRotateRight className="w-4 h-4 text-sky-600" /> Let's go!
    </div>
  </div>
);

export default MenuBar;
