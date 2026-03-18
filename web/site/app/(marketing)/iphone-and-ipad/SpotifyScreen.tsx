'use client';

import React, { useEffect, useState } from 'react';
import { BlockedIcon } from './shared';

export const SpotifyIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z" />
  </svg>
);

const SpotifyScreen: React.FC = () => {
  const [showNowPlaying, setShowNowPlaying] = useState(true);

  useEffect(() => {
    const interval = setInterval(() => {
      setShowNowPlaying((prev) => !prev);
    }, 5500);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="size-full flex flex-col bg-gradient-to-b from-slate-800 to-black relative overflow-hidden">
      <div
        className={`absolute inset-0 flex flex-col transition-all duration-500 ${
          showNowPlaying ? `opacity-100 translate-x-0` : `opacity-0 -translate-x-full`
        }`}
      >
        <div className="flex-1 flex flex-col items-center justify-center px-6 pt-8">
          <div className="w-[70%] aspect-square bg-slate-700 rounded-lg flex items-center justify-center mb-6 shadow-2xl">
            <BlockedIcon className="size-16 text-red-400/60" />
          </div>
          <p className="text-white font-bold text-lg text-center">Summer Vibes</p>
          <p className="text-white/60 text-sm text-center">Various Artists</p>
          <p className="text-red-400/80 text-xs text-center mt-1">Artwork hidden</p>
        </div>
        <div className="px-6 pb-10">
          <div className="w-full bg-white/20 rounded-full h-1 mb-3">
            <div className="bg-white h-1 rounded-full w-1/3" />
          </div>
          <div className="flex justify-between text-white/40 text-xs mb-4">
            <span>1:23</span>
            <span>3:45</span>
          </div>
          <div className="flex items-center justify-center gap-8">
            <svg className="size-6 text-white/60" viewBox="0 0 24 24" fill="currentColor">
              <path d="M6 6h2v12H6zm3.5 6l8.5 6V6z" />
            </svg>
            <div className="size-14 rounded-full bg-white flex items-center justify-center">
              <svg
                className="size-6 text-black ml-1"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M8 5v14l11-7z" />
              </svg>
            </div>
            <svg className="size-6 text-white/60" viewBox="0 0 24 24" fill="currentColor">
              <path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z" />
            </svg>
          </div>
        </div>
      </div>
      <div
        className={`absolute inset-0 flex flex-col transition-all duration-500 ${
          !showNowPlaying ? `opacity-100 translate-x-0` : `opacity-0 translate-x-full`
        }`}
      >
        <div className="p-4 pt-16">
          <div className="flex items-center gap-2 mb-1">
            <SpotifyIcon className="size-5 text-green-500" />
            <p className="text-white font-bold text-xl">Your Library</p>
          </div>
          <p className="text-white/50 text-xs mb-4">Recently played</p>
          <div className="grid grid-cols-3 gap-2">
            {[...Array(12)].map((_, i) => (
              <div key={i} className="flex flex-col">
                <div className="aspect-square bg-slate-700 rounded flex items-center justify-center mb-1">
                  <BlockedIcon className="size-6 text-red-400/60" />
                </div>
                <p className="text-white/70 text-[9px] truncate">
                  {
                    [
                      `Chill Mix`,
                      `Rock Hits`,
                      `Pop Today`,
                      `Jazz Café`,
                      `EDM Party`,
                      `Country`,
                      `Hip Hop`,
                      `Indie`,
                      `Classical`,
                      `R&B Vibes`,
                      `Workout`,
                      `Focus`,
                    ][i]
                  }
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SpotifyScreen;
