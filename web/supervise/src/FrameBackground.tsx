import React from 'react';

interface Props {
  children: React.ReactNode;
}

const FrameBackground: React.FC<Props> = ({ children }) => (
  <div className="h-full relative overflow-hidden bg-slate-50">
    <div className="absolute w-152 h-152 -left-96 -bottom-72 [background:radial-gradient(#8b5cf656_0%,transparent_70%,transparent)]" />
    <div className="absolute w-152 h-152 left-0 -bottom-96 [background:radial-gradient(#d946ef56_0%,transparent_70%,transparent)]" />
    <div className="absolute w-152 h-152 -right-80 -bottom-80 [background:radial-gradient(#8b5cf656_0%,transparent_70%,transparent)]" />
    <div className="relative h-full">{children}</div>
  </div>
);

export default FrameBackground;
