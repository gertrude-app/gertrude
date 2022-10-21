import React from 'react';
import Logo from '../shared/Logo';

const DmgBackground: React.FC = () => (
  <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-gray-800 bg-gradient-to-br from-transparent via-transparent to-violet-700/30">
    <div className="flex flex-col items-center">
      <div className="bg-white/0 mt-8 mb-4 px-5 py-3 rounded-lg scale-150">
        <Logo type="on-dark" />
      </div>
      <div className="mt-24 flex w-[384px] items-center justify-between opacity-50">
        <div className="h-32 w-32 bg-white rounded-xl" />
        <i className="text-white text-6xl fa fa-arrow-right" />
        <div className="h-32 w-32 bg-white rounded-xl" />
      </div>
    </div>
  </div>
);

export default DmgBackground;
