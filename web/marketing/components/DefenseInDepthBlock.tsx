import React from 'react';

const DefenseInDepthBlock: React.FC = () => {
  return (
    <section className="bg-gradient-to-b from-gray-900 to-gray-800 px-10 md:px-16 pt-16 md:pt-24 flex items-center flex-col relative overflow-hidden">
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -right-128 -top-72 z-20" />
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-20 -bottom-128 z-20" />
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-72 -bottom-96 z-20" />
      <div className="flex sm:flex-row flex-col md:justify-center items-center mb-16 relative">
        <div className="md:w-32 w-24 md:h-32 h-24 rounded-full bg-gray-800 flex items-center justify-center my-5 sm:my-0 sm:mx-10 shadow-2xl relative">
          <i className="fa fa-filter text-4xl md:text-5xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent" />
        </div>
        <div className="md:w-32 w-24 md:h-32 h-24 rounded-full bg-gray-800 flex items-center justify-center my-5 sm:my-0 sm:mx-10 shadow-2xl relative">
          <i className="fa fa-binoculars text-4xl md:text-5xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent" />
        </div>
        <div className="md:w-32 w-24 md:h-32 h-24 rounded-full bg-gray-800 flex items-center justify-center my-5 sm:my-0 sm:mx-10 shadow-2xl relative">
          <i className="fa fa-keyboard text-4xl md:text-5xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent" />
        </div>
      </div>
      <h1 className="font-inter text-6xl md:text-7xl text-left md:text-center text-white">
        Defense in depth.
      </h1>
      <p className="text-xl text-gray-500 mt-8 leading-8 md:text-center text-left max-w-5xl sm:mb-20 mb-12">
        In addition to internet filtering, Gertrude allows you to collect screenshots of
        your protected users' screens, as well as their keystrokes, for an unprecedented
        level of safety, redundancy, and oversight. You get to review screenshots and
        keystrokes on your own time, on your own device.
      </p>
      <section className="flex justify-center w-screen">
        <div
          className="md:h-32 h-12 flex-grow relative z-30"
          style={{
            background: `linear-gradient(to bottom left, transparent 50%, #8b5cf6 50%)`,
          }}
        />
        <div
          className="md:h-32 h-12 flex-grow bg-pink-500 z-30"
          style={{
            background: `linear-gradient(to bottom right, transparent 50%, #8b5cf6 50%)`,
          }}
        />
      </section>
    </section>
  );
};

export default DefenseInDepthBlock;
