import React from 'react';

interface Props {
  children: React.ReactNode;
}

const FrameBackground: React.FC<Props> = ({ children }) => (
  <div className="h-full relative overflow-hidden bg-slate-50">
    <div className="absolute w-[50rem] h-[50rem] -right-64 -top-64 [background:radial-gradient(#8b5cf625_0%,transparent_70%,transparent)]" />
    <div className="absolute w-[50rem] h-[50rem] right-16 -top-80 [background:radial-gradient(#d946ef20_0%,transparent_70%,transparent)]" />
    <div className="absolute w-[50rem] h-[50rem] -left-80 -top-64 [background:radial-gradient(#8b5cf618_0%,transparent_70%,transparent)]" />
    <div className="relative h-full flex flex-col items-center justify-center p-12">
      {children}
    </div>
  </div>
);

export default FrameBackground;
