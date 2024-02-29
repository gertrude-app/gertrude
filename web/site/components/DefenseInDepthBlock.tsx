import React from 'react';
import Stars from './Stars';

const DefenseInDepthBlock: React.FC = () => (
  <section className="bg-white xl:p-8 xl:pb-0">
    <div className="px-8 xs:px-12 lg:px-28 pt-16 md:pt-28 pb-12 lg:pb-20 bg-slate-900 rounded-t-[40px] flex flex-col items-center relative overflow-hidden">
      <Stars className="absolute left-0 top-0 w-full h-128" />
      <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -right-80 -top-80" />
      <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -left-80 -top-80" />
      <div className="[background:radial-gradient(#a78bfa44,transparent_70%)] w-176 h-176 absolute left-20 -top-96" />
      <h2 className="font-axiforma font-bold text-4xl xs:text-5xl sm:text-6xl lg:text-7xl bg-gradient-to-r from-white to-violet-300 bg-clip-text text-transparent pt-0.5 z-10 text-center">
        Defense in depth.
      </h2>
      <p className="text-lg xs:text-xl text-violet-200 max-w-4xl text-center mt-8 z-10">
        In addition to internet filtering, Gertrude allows you to collect{` `}
        <strong className="text-white">screenshots</strong> of your child’s screens, as
        well as a record of{` `}
        <strong className="text-white">everything they type</strong>, for an unprecedented
        level of safety, redundancy, and oversight. You get to review screenshots and
        keystrokes on your own time, on your own device.
      </p>
      <p className="text-lg xs:text-xl text-violet-200 max-w-4xl text-center mt-8 z-10">
        We clearly display that they are being watched—there‘s nothing creepy or secretive
        about it. This greatly increases their safety online, plus allows you to
        occasionally turn off the filter, safe in the knowledge that their activity is
        being observed.
      </p>
    </div>
  </section>
);

export default DefenseInDepthBlock;
