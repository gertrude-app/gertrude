import React from 'react';
import { Logo } from '@shared/components';

const DmgBackground: React.FC = () => (
  <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-gradient-to-b from-violet-500 to-fuchsia-500">
    <div className="flex flex-col justify-center items-center mt-12 w-128">
      <div className="rounded-lg scale-150">
        <Logo type="inverted" />
      </div>
      <div className="mt-20 flex items-center justify-between">
        <div className="h-32 w-32 bg-white/20 rounded-3xl shrink-0" />
        <svg
          xmlns="http://www.w3.org/2000/svg"
          version="1.1"
          viewBox="0 0 800 800"
          height="200px"
          width="200px"
          className="shrink-0 opacity-80 rotate-6"
        >
          <g
            strokeWidth="22"
            stroke="hsl(0, 0%, 100%)"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
            transform="rotate(310, 400, 400)"
          >
            <path
              d="M250 250.55055594444275Q491 236.55055594444275 400 400.55055594444275Q333 533.5505559444427 550 550.5505559444427 "
              markerEnd="url(#SvgjsMarker1486)"
            ></path>
          </g>
          <defs>
            <marker
              markerWidth="5"
              markerHeight="5"
              refX="2.5"
              refY="2.5"
              viewBox="0 0 5 5"
              orient="auto"
              id="SvgjsMarker1486"
            >
              <polygon points="0,5 0,0 5,2.5" fill="hsl(0, 0%, 100%)"></polygon>
            </marker>
          </defs>
        </svg>
        <div className="h-32 w-32 bg-white/20 rounded-3xl shrink-0" />
      </div>
    </div>
  </div>
);

export default DmgBackground;
