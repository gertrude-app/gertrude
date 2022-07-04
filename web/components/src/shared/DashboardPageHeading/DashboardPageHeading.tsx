import React from 'react';

type Props = {
  children: React.ReactNode;
  icon: string;
};

const DashboardPageHeading: React.FC<Props> = ({ children, icon }) => {
  return (
    <header>
      <div className="flex justify-start items-center mb-3">
        <div className="flex justify-center items-center w-12 h-12 bg-violet-500 rounded-full mr-3">
          <i className={`fas fa-${icon} text-2xl text-white text-opacity-60`} />
        </div>
        <h1 className="text-4xl font-bold flex justify-start items-center text-gray-800">
          {children}
        </h1>
      </div>
      <hr className="h-1 bg-gradient-to-r from-indigo-500 to-fuchsia-500" />
    </header>
  );
};

export default DashboardPageHeading;
