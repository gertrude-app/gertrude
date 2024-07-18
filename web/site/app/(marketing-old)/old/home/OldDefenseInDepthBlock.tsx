import React from 'react';
import GlowEffect from './GlowEffect';

const DefenseInDepthBlock: React.FC = () => (
  <section className="bg-gradient-to-b from-slate-900 to-slate-800 px-10 md:px-16 pt-16 md:pt-28 pb-12 flex items-center flex-col relative overflow-hidden">
    <GlowEffect className="-right-128 -top-72 z-20" />
    <GlowEffect className="-left-20 -bottom-128 z-20" />
    <GlowEffect className="-left-72 -bottom-96 z-20" />
    <div className="flex flex-row flex-wrap justify-center md:justify-center items-center mb-8 sm:mb-16 relative">
      <IconCircle icon="lock" />
      <IconCircle icon="binoculars" />
      <IconCircle icon="keyboard" />
    </div>
    <h2 className="font-inter text-6xl md:text-7xl text-left md:text-center text-white">
      Defense in depth.
    </h2>
    <p className="text-xl text-slate-400/90 mt-8 leading-8 md:text-center text-left max-w-5xl *sm:mb-20 mb-10">
      In addition to internet filtering, Gertrude allows you to collect{` `}
      <b className="text-slate-300">screenshots</b>
      {` `}
      of your child&rsquo;s screens, as well as a record of{` `}
      <b className="text-slate-300">everything they type</b>, for an unprecedented level
      of safety, redundancy, and oversight. You get to review screenshots and keystrokes
      on your own time, on your own device.
    </p>
    <p className="text-xl text-slate-400/90 mt-0 leading-8 md:text-center text-left max-w-5xl sm:mb-24 mb-8">
      We clearly display that they are being watched&mdash;there&lsquo;s nothing creepy or
      secretive about it. This greatly increases their safety online, plus allows you to
      occasionally turn off the filter, safe in the knowledge that their activity is being
      observed.
    </p>
  </section>
);

interface IconCircleProps {
  icon: string;
}

const IconCircle: React.FC<IconCircleProps> = ({ icon }) => (
  <div className="md:w-32 w-24 md:h-32 h-24 rounded-full bg-slate-800 flex items-center justify-center my-2 sm:my-0 mx-3 sm:mx-10 shadow-2xl relative">
    <i
      aria-hidden
      className={`fa fa-${icon} text-4xl md:text-5xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent`}
    />
  </div>
);

export default DefenseInDepthBlock;
