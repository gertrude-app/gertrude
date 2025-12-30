import React from 'react';
import SpotifyScreen, { SpotifyIcon } from './SpotifyScreen';
import { FeatureItem } from './shared';
import DeviceMockupBlock from '@/components/DeviceMockupBlock';

const SpotifyBlock: React.FC = () => (
  <DeviceMockupBlock
    background="green"
    devicePosition="right"
    deviceContent={<SpotifyScreen />}
    deviceBleeds
  >
    <div className="inline-flex items-center gap-2 bg-black/20 px-3 py-1.5 rounded-full text-white text-sm font-medium mb-6">
      <SpotifyIcon className="size-4" />
      Spotify
    </div>
    <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
      Block Explicit Album Covers in Spotify
    </h2>
    <p className="text-lg xs:text-xl text-white/80 leading-relaxed mb-8">
      Album covers and playlist artwork often contain explicit or suggestive imagery.
      Gertrude can hide album artwork images in Spotify while letting your kids enjoy
      their music without visual distractions.
    </p>
    <ul className="space-y-2 mb-8 ml-4">
      <FeatureItem inverted text="Hides explicit album cover artwork" />
      <FeatureItem inverted text="Music playback completely unaffected" />
      <FeatureItem inverted text="Works with all Spotify content" />
    </ul>
  </DeviceMockupBlock>
);

export default SpotifyBlock;
