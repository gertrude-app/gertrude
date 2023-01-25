import React from 'react';
import ExampleWebsiteGraphic from './ExampleWebsiteGraphic';
import GlowEffect from './GlowEffect';
import WebsiteCounter from './WebsiteCounter';

const LosingGameBlock: React.FC = () => (
  <>
    <section
      className="h-24 flex border-l-2 border-none relative"
      style={{
        background: `linear-gradient(to bottom right, transparent 50%, #111827 50%)`,
      }}
    >
      <div className="h-full w-20 ml-0.5 z-20 hidden lg:block"></div>
    </section>
    <section className="bg-slate-900 relative p-8 sm:p-12 pt-16 md:pt-20 md:p-20 lg:py-28 z-20">
      <GlowEffect className="lg:-right-20 -right-72 -top-32 lg:-top-12" />
      <GlowEffect className="-left-40 -bottom-24" />
      <GlowEffect className="left-56 -bottom-80" />
      <div className="flex flex-col-reverse lg:flex-row">
        <div className="md:mr-20">
          <h2 className="text-6xl font-extrabold font-inter text-white">
            <span className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent">
              A losing game
            </span>
          </h2>
          <p className="text-xl text-gray-500 mt-8 leading-8 max-w-3xl">
            Most internet safety tools try to block{` `}
            <span className="text-gray-400 font-bold antialiased">categories</span> of the
            internet. With 1.9 billion websites, and tens of thousands more being added
            every day, it's simply impossible to maintain up-to-date lists correctly
            categorizing even a fraction of dangerous websites.
          </p>
        </div>
        <div className="relative flex-grow lg:w-96 lg:ml-28 hidden md:block">
          <ExampleWebsiteGraphic className="absolute xl:-bottom-40 lg:bottom-12 lg:right-40 xl:right-56 lg:-rotate-6 scale-75 -right-52 -top-20 lg:top-auto rotate-3" />
          <ExampleWebsiteGraphic className="absolute lg:bottom-20 xl:bottom-8 lg:-right-2 lg:rotate-12 lg:scale-90 scale-75 -right-40 top-0 -rotate-12" />
          <ExampleWebsiteGraphic className="absolute lg:-bottom-8 xl:-bottom-20 lg:right-20 lg:rotate-3 lg:scale-100 scale-75 hidden lg:block" />
        </div>
      </div>
      <WebsiteCounter />
    </section>
    <section
      className="h-24 flex border-l-2 border-none relative z-10"
      style={{
        background: `linear-gradient(to bottom right, #111827 50%,  #f9fafb 50%)`,
      }}
    >
      <div className="hidden lg:block h-full w-20 ml-0.5  z-20"></div>
    </section>
  </>
);

export default LosingGameBlock;
