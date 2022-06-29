import React from 'react';

const DreamToRealityBlock: React.FC = () => {
  return (
    <section
      style={{
        background: `linear-gradient(to bottom right, #f3f4f6 50%, white 50%)`,
      }}
      className="relative"
    >
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-96 -bottom-112" />
      <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -right-96" />
      <div className="lg:ml-10 flex justify-start py-8 items-center relative">
        <div className="lg:w-1/2 p-12 lg:pl-12 sm:pl-16 pl-8 pr-8">
          <div className="bg-gradient-to-br from-violet-500 to-fuchsia-500 w-12 h-12 rounded-lg flex justify-center items-center">
            <i className="fas fa-desktop text-white text-xl" />
          </div>
          <h1 className="text-5xl font-extrabold font-inter mt-4">
            <span className="text-black">
              From dream to{` `}
              <span className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent">
                reality
              </span>
            </span>
          </h1>
          <p className="text-xl text-gray-500 my-5 leading-8">
            Protect your loved ones with aggressive network filtering, plus screen and
            keystroke monitoring. Remotely supervise and control access from your own
            computer or phone. Available for macOS starting November 1.
          </p>
          <button
            className="text-white font-extrabold text-2xl bg-gradient-to-br from-violet-500 to-fuchsia-500 px-8 py-3 rounded-xl shadow-xl mt-8 hover:from-violet-600 hover:to-fuchsia-600 flex items-center"
            onClick={() => alert(`April fools`)}
          >
            <i className="fas fa-rocket mr-5" />
            <h2>Join the waitlist</h2>
          </button>
        </div>
        <div className="w-1/2 h-112 bg-fuchsia-radial-gradient z-10 p-8 justify-center items-center lg:flex hidden">
          <div className="w-96 h-96 bg-white rounded-full shadow-xl overflow-hidden flex justify-center items-center">
            <i className="fa fa-lock text-9xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent scale-125" />
          </div>
        </div>
      </div>
    </section>
  );
};

export default DreamToRealityBlock;
