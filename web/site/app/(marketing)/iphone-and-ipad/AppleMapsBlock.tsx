import React from 'react';
import { BlockedIcon, FeatureItem } from './shared';
import DeviceMockupBlock from '@/components/DeviceMockupBlock';

const AppleMapsScreen: React.FC = () => (
  <div className="size-full flex flex-col bg-gradient-to-br from-green-200 via-blue-100 to-blue-200 relative">
    <div className="absolute inset-0">
      <div className="absolute top-[15%] left-[10%] w-[35%] h-[20%] bg-green-300/70 rounded-sm" />
      <div className="absolute top-[10%] right-[15%] w-[25%] h-[15%] bg-green-400/60 rounded-sm" />
      <div className="absolute top-[40%] left-[5%] w-[40%] h-[12%] bg-green-300/50 rounded-sm" />
      <div className="absolute top-[35%] right-[10%] w-[30%] h-[18%] bg-green-200/70 rounded-sm" />
      <div className="absolute bottom-[30%] left-[20%] w-[25%] h-[10%] bg-blue-300/40 rounded-sm" />
      <div className="absolute bottom-[15%] right-[5%] w-[45%] h-[8%] bg-blue-200/50 rounded-sm" />
      <div className="absolute top-[25%] left-[30%] right-[30%] h-[2px] bg-amber-400/80" />
      <div className="absolute top-[50%] left-[20%] right-[25%] h-[2px] bg-amber-300/70" />
      <div className="absolute top-[65%] left-[10%] right-[40%] h-[2px] bg-amber-400/60" />
      <div className="absolute top-[20%] left-[45%] w-[2px] h-[35%] bg-slate-400/50" />
      <div className="absolute top-[45%] left-[70%] w-[2px] h-[40%] bg-slate-400/40" />
    </div>
    <div className="absolute top-[20%] lg:top-[38%] left-1/2 -translate-x-1/2 -translate-y-1/2">
      <div className="size-10 bg-red-500 rounded-full flex items-center justify-center shadow-lg border-[3px] border-white">
        <div className="w-2.5 h-2.5 bg-white rounded-full" />
      </div>
    </div>
    <div className="absolute top-[30%] lg:top-auto lg:bottom-0 left-0 right-0 lg:rounded-none rounded-t-2xl bg-white/95 backdrop-blur-sm p-4">
      <div className="flex items-center gap-3 mb-3">
        <div className="size-10 bg-slate-200 rounded-lg flex items-center justify-center">
          <BlockedIcon className="size-5 text-red-400" />
        </div>
        <div className="flex-1">
          <p className="text-slate-800 font-semibold text-sm">After Hours Lounge</p>
          <p className="text-slate-500 text-xs">123 Freemont St.</p>
        </div>
      </div>
      <div className="grid grid-cols-4 gap-2">
        {[...Array(8)].map((_, i) => (
          <div
            key={i}
            className="aspect-square bg-slate-100 rounded-lg flex items-center justify-center"
          >
            <BlockedIcon className="size-5 text-red-400/70" />
          </div>
        ))}
      </div>
      <p className="text-center text-slate-400 text-[10px] mt-2">
        Photos blocked by Gertrude
      </p>
    </div>
  </div>
);

const AppleMapsBlock: React.FC = () => (
  <DeviceMockupBlock
    background="violet"
    devicePosition="left"
    deviceContent={<AppleMapsScreen />}
    deviceBleeds
  >
    <div className="inline-flex items-center gap-2 bg-white/20 px-3 py-1.5 rounded-full text-white text-sm font-medium mb-6">
      <svg
        className="size-4"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={2}
      >
        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
        <circle cx="12" cy="10" r="3" />
      </svg>
      Apple Maps
    </div>
    <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
      Block Inappropriate Photos in Apple Maps
    </h2>
    <p className="text-lg xs:text-xl text-white/80 leading-relaxed mb-8">
      Apple Maps displays user-uploaded photos of locations that can include inappropriate
      imagery. Gertrude removes these images from Apple Maps while keeping navigation and
      all other features fully functional.
    </p>
    <ul className="space-y-2 mb-8 ml-4">
      <FeatureItem inverted text="Removes user-uploaded location photos" />
      <FeatureItem inverted text="Photos of business exteriors and interiors blocked" />
      <FeatureItem inverted text="Navigation and directions unaffected" />
    </ul>
  </DeviceMockupBlock>
);

export default AppleMapsBlock;
