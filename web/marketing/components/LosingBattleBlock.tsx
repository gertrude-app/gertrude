import React from 'react';
import ExampleWebsiteGraphic from './ExampleWebsiteGraphic';

const LosingBattleBlock: React.FC = () => {
  return (
    <>
      <section
        className="lg:h-32 h-24 flex border-l-2 border-none relative"
        style={{
          background: `linear-gradient(to bottom right, transparent 50%, #111827 50%)`,
        }}
      >
        <div className="h-full w-20 ml-0.5 z-20 hidden lg:block"></div>
      </section>
      <section className="bg-gray-900 relative lg:flex-row flex flex-col py-16">
        <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-128 -bottom-52 z-20" />
        <div className="lg:w-1/2 h-128 lg:ml-10 -my-36 lg:-my-16 flex justify-center items-center lg:block scale-75 lg:scale-100">
          <div className="relative bottom-72 left-96 lg:bottom-0 lg:left-0">
            <ExampleWebsiteGraphic className="right-80 top-48 scale-125 z-50 -rotate-6" />
            <ExampleWebsiteGraphic className="right-52 top-20 scale-90 z-40 -rotate-12" />
            <ExampleWebsiteGraphic className="right-32 top-72 scale-75 z-40 rotate-12" />
          </div>
        </div>
        <div className="lg:w-1/2">
          <div className="p-20 lg:px-20 px-10 lg:pl-0 -mb-20 lg:-mb-0">
            <h1 className="text-6xl font-extrabold font-inter text-white">
              <span className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent">
                A losing battle
              </span>
            </h1>
            <p className="text-xl text-gray-500 mt-8 leading-8">
              Most internet safety tools try to block categories of the internet. With 1.7
              billion websites, and hundreds of thousands more being added every day,
              taking this approach only gives you the illusion of safety...
            </p>
          </div>
        </div>
      </section>
      <section
        className="h-32 flex border-l-2 border-none relative z-10"
        style={{
          background: `linear-gradient(to bottom right, #111827 50%,  #f3f4f6 50%)`,
        }}
      >
        <div className="hidden lg:block h-full w-20 ml-0.5  z-20"></div>
      </section>
    </>
  );
};

export default LosingBattleBlock;
