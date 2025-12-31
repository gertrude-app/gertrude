import React from 'react';
import { GertrudeLogo } from './Icons';

interface SplitLayoutProps {
  children: React.ReactNode;
}

const SplitLayout: React.FC<SplitLayoutProps> = ({ children }) => (
  <div className="min-h-screen flex">
    <div className="flex-1 flex items-center justify-center p-8 bg-slate-50">
      <div className="w-full max-w-md animate-fade-in">
        <div className="lg:hidden flex items-center gap-3 mb-12">
          <GertrudeLogo className="w-10 h-10" />
          <span className="font-display font-semibold text-xl text-slate-800">
            Gertrude
          </span>
        </div>
        {children}
      </div>
    </div>

    <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 relative overflow-hidden">
      <div className="absolute inset-0 opacity-30">
        <div className="absolute top-1/4 -left-20 w-96 h-96 bg-brand-violet/20 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-brand-fuchsia/20 rounded-full blur-3xl" />
      </div>
      <div
        className="absolute inset-0 opacity-[0.015]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        }}
      />
      <div className="relative z-10 flex flex-col justify-center items-center w-full p-12">
        <GertrudeLogo className="w-32 h-32 animate-float" variant="light" />
        <h2 className="mt-2 text-3xl font-display font-semibold text-white/90 tracking-tight">
          Gertrude
        </h2>
        <p className="mt-2 text-white/40 font-medium tracking-widest uppercase text-xs">
          Admin Portal
        </p>
      </div>
    </div>
  </div>
);

export default SplitLayout;
