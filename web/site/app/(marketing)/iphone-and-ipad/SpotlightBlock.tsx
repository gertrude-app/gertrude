import React from 'react';
import SpotlightScreen from './SpotlightScreen';
import { FeatureItem } from './shared';
import DeviceMockupBlock from '@/components/DeviceMockupBlock';

const SpotlightBlock: React.FC = () => (
  <DeviceMockupBlock
    background="slate"
    devicePosition="left"
    deviceContent={<SpotlightScreen />}
    deviceBleeds
  >
    <div className="inline-flex items-center gap-2 bg-violet-500/20 px-3 py-1.5 rounded-full text-violet-300 text-sm font-medium mb-6">
      <svg
        className="size-4"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={2}
      >
        <circle cx="11" cy="11" r="8" />
        <path d="M21 21l-4.35-4.35" />
      </svg>
      Spotlight Search
    </div>
    <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
      Block Spotlight Internet & Image Searches
    </h2>
    <p className="text-lg xs:text-xl text-slate-300 leading-relaxed mb-8">
      A common loophole parents miss is that the built-in search feature in iOS can pull
      content and images from the web. Screen Time can&apos;t restrict kids from using
      this feature, but Gertrude&apos;s got you covered.
    </p>
    <ul className="space-y-2 mb-8 ml-4">
      <FeatureItem text="Blocks web image results in Spotlight" />
      <FeatureItem text="App and file search still works" />
      <FeatureItem text="Siri suggestions unaffected" />
    </ul>
  </DeviceMockupBlock>
);

export default SpotlightBlock;
