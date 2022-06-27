import React from 'react';

interface Props {
  children: string;
  icon: string;
}

const Feature: React.FC<Props> = ({ children, icon }) => {
  return (
    <div className="shadow-lg w-128 m-5 rounded-2xl sm:p-12 p-8 flex flex-col items-start relative overflow-hidden bg-white z-20">
      <div className="w-32 h-32 bg-violet-200 rounded-full absolute -left-16 -top-16">
        <i
          className={`fa fa-${icon} text-2xl text-violet-800 absolute bottom-12 mb-1 right-12 h-0 w-0`}
        />
      </div>
      <p className="text-xl text-gray-500 leading-8 mt-12 relative">{children}</p>
    </div>
  );
};

export default Feature;
