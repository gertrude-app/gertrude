import cx from 'classnames';
import React from 'react';

export const BlockedIcon: React.FC<{
  className?: string;
  style?: React.CSSProperties;
}> = ({ className, style }) => (
  <svg
    className={className}
    style={style}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
  >
    <circle cx="12" cy="12" r="10" />
    <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
  </svg>
);

export const SpotifyIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z" />
  </svg>
);

interface PhoneFrameProps {
  children: React.ReactNode;
  className?: string;
}

export const PhoneFrame: React.FC<PhoneFrameProps> = ({ children, className }) => (
  <div
    className={cx(
      `relative bg-black rounded-[44px] p-[6px] shadow-[0_30px_60px_-15px_rgba(0,0,0,0.6)] ring-1 ring-white/5`,
      className,
    )}
  >
    <div className="absolute top-[10px] left-1/2 -translate-x-1/2 w-[34%] h-[18px] bg-black rounded-full z-30" />
    <div className="absolute -right-[2px] top-[22%] w-[3px] h-[58px] bg-zinc-800 rounded-r" />
    <div className="absolute -left-[2px] top-[18%] w-[3px] h-[32px] bg-zinc-800 rounded-l" />
    <div className="absolute -left-[2px] top-[30%] w-[3px] h-[58px] bg-zinc-800 rounded-l" />
    <div className="w-full h-full overflow-hidden rounded-[38px] bg-slate-900 relative">
      {children}
    </div>
  </div>
);

export const GifBlockingScreen: React.FC<{ searchText?: string }> = ({
  searchText = `Bikini`,
}) => (
  <div className="size-full flex flex-col overflow-hidden relative bg-slate-900">
    <div className="h-[28%] shrink-0" />
    <div className="flex-1 bg-white rounded-t-2xl shadow-2xl flex flex-col">
      <div className="bg-gray-50 px-2.5 py-2 border-b border-gray-200 flex flex-col gap-1.5">
        <div className="flex items-center gap-2">
          <div className="flex-1 bg-gray-200/70 rounded-full px-2.5 py-1 flex items-center gap-1.5">
            <svg
              className="size-3 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <span className="text-gray-700 text-[11px] font-medium">{searchText}</span>
          </div>
          <span className="text-blue-500 text-[10px] font-medium">Cancel</span>
        </div>
        <div className="flex gap-1 text-[9px] font-medium">
          <span className="px-2 py-0.5 rounded-full bg-red-600 text-white">#images</span>
          <span className="px-2 py-0.5 rounded-full bg-gray-200 text-gray-500">
            Trending
          </span>
          <span className="px-2 py-0.5 rounded-full bg-gray-200 text-gray-500">
            Reactions
          </span>
        </div>
      </div>
      <div className="flex-1 p-1.5 overflow-hidden bg-gray-100">
        <div className="grid grid-cols-3 gap-1">
          {[...Array(18)].map((_, i) => (
            <div
              key={i}
              className="aspect-square rounded-md bg-gray-300 shadow-inner flex items-center justify-center"
            >
              <BlockedIcon className="size-5 text-red-400/60" />
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

export const SpotlightBlockingScreen: React.FC = () => (
  <div className="size-full flex flex-col relative overflow-hidden">
    <div className="absolute inset-0 bg-gradient-to-br from-slate-600 via-purple-900/60 to-slate-900" />
    <div className="absolute inset-0 backdrop-blur-xl bg-black/40" />
    <div className="relative flex-1 flex flex-col pt-10 px-3">
      <div className="bg-white/20 backdrop-blur-md rounded-xl px-2.5 py-1.5 flex items-center gap-2 mb-3">
        <svg
          className="size-3.5 text-white/60"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <circle cx="11" cy="11" r="8" />
          <path d="M21 21l-4.35-4.35" />
        </svg>
        <span className="text-white text-[11px]">Sexy</span>
      </div>
      <div className="mb-3">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-white font-semibold text-[11px]">Web Images</span>
          <span className="text-white/50 text-[9px]">Show More</span>
        </div>
        <div className="grid grid-cols-4 gap-1">
          {[...Array(8)].map((_, i) => (
            <div
              key={i}
              className="aspect-square bg-slate-500/50 rounded-md flex items-center justify-center"
            >
              <BlockedIcon className="size-4 text-red-400/70" />
            </div>
          ))}
        </div>
      </div>
      <div className="bg-white/10 backdrop-blur-sm rounded-xl p-2.5 mb-2">
        <span className="text-white font-semibold text-[11px]">Siri Knowledge</span>
        <div className="flex items-center gap-2 mt-1.5">
          <div className="size-9 bg-slate-500/50 rounded-md flex items-center justify-center shrink-0">
            <BlockedIcon className="size-5 text-red-400/70" />
          </div>
          <div className="flex-1 space-y-1">
            <div className="h-1.5 bg-white/20 rounded w-full" />
            <div className="h-1.5 bg-white/20 rounded w-4/5" />
            <div className="h-1.5 bg-white/20 rounded w-3/5" />
          </div>
        </div>
      </div>
    </div>
  </div>
);

export const SpotifyBlockingScreen: React.FC = () => (
  <div className="size-full flex flex-col bg-gradient-to-b from-slate-800 to-black relative overflow-hidden">
    <div className="flex-1 flex flex-col items-center justify-center px-5 pt-6">
      <div className="w-[70%] aspect-square bg-slate-700 rounded-lg flex items-center justify-center mb-4 shadow-2xl">
        <BlockedIcon className="size-12 text-red-400/60" />
      </div>
      <p className="text-white font-bold text-sm text-center">Summer Vibes</p>
      <p className="text-white/60 text-[11px] text-center">Various Artists</p>
      <p className="text-red-400/80 text-[9px] text-center mt-1">Artwork hidden</p>
    </div>
    <div className="px-5 pb-6">
      <div className="w-full bg-white/20 rounded-full h-0.5 mb-2">
        <div className="bg-white h-0.5 rounded-full w-1/3" />
      </div>
      <div className="flex justify-between text-white/40 text-[9px] mb-3">
        <span>1:23</span>
        <span>3:45</span>
      </div>
      <div className="flex items-center justify-center gap-5">
        <svg className="size-4 text-white/60" viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 6h2v12H6zm3.5 6l8.5 6V6z" />
        </svg>
        <div className="size-9 rounded-full bg-white flex items-center justify-center">
          <svg
            className="size-4 text-black ml-0.5"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path d="M8 5v14l11-7z" />
          </svg>
        </div>
        <svg className="size-4 text-white/60" viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z" />
        </svg>
      </div>
    </div>
  </div>
);

export const SafariInNotesBlockingScreen: React.FC = () => (
  <div className="size-full flex flex-col bg-[#fdf6d8] relative overflow-hidden">
    <div className="shrink-0 px-3 pt-6 pb-2">
      <p className="text-[10px] font-semibold text-amber-900/70 mb-1">
        Tuesday · 3:42 PM
      </p>
      <p className="text-[13px] font-bold text-amber-950 leading-tight mb-1">
        School Project
      </p>
      <p className="text-[9px] text-amber-900/80 leading-snug">
        Research topic ideas
        <span className="underline text-blue-600"> https://images.ex</span>
      </p>
    </div>
    <div className="flex-1 bg-white rounded-t-2xl shadow-xl flex flex-col overflow-hidden border-t border-gray-200">
      <div className="bg-gray-100 px-2.5 py-1.5 border-b border-gray-200 flex items-center gap-2">
        <span className="text-blue-600 text-[9px] font-semibold">Done</span>
        <div className="flex-1 bg-white rounded-md px-2 py-0.5 flex items-center gap-1">
          <svg className="size-2.5 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 1a11 11 0 100 22 11 11 0 000-22zm0 2a9 9 0 110 18 9 9 0 010-18z" />
          </svg>
          <span className="text-gray-600 text-[9px] truncate">images.ex/search</span>
        </div>
        <svg className="size-2.5 text-blue-600" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 3l9 9h-4v9h-4v-6h-2v6H7v-9H3z" />
        </svg>
      </div>
      <div className="flex-1 p-1.5 bg-gray-50 overflow-hidden">
        <div className="grid grid-cols-3 gap-1">
          {[...Array(15)].map((_, i) => (
            <div
              key={i}
              className="aspect-square rounded-md bg-gray-200 flex items-center justify-center"
            >
              <BlockedIcon className="size-4 text-red-400/60" />
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

export const SiriBlockingScreen: React.FC = () => (
  <div className="size-full flex flex-col relative overflow-hidden bg-black">
    <div className="absolute inset-0 backdrop-blur-xl bg-black/70" />
    <div className="relative flex-1 flex flex-col px-3 pt-8">
      <div className="self-end bg-white/10 backdrop-blur-sm rounded-2xl rounded-br-sm px-2.5 py-1.5 mb-3 max-w-[80%]">
        <p className="text-white text-[10px] leading-tight">
          Show me pictures of bikini models
        </p>
      </div>
      <div className="bg-white/[0.07] backdrop-blur-sm rounded-xl p-2 mb-2 border border-white/10">
        <div className="flex items-center gap-1.5 mb-1.5">
          <div className="size-4 rounded bg-white/10 flex items-center justify-center">
            <BlockedIcon className="size-2.5 text-red-400/80" />
          </div>
          <span className="text-white/70 text-[9px] font-medium">Web Images</span>
        </div>
        <div className="grid grid-cols-4 gap-1">
          {[...Array(8)].map((_, i) => (
            <div
              key={i}
              className="aspect-square bg-white/5 rounded-md flex items-center justify-center"
            >
              <BlockedIcon className="size-3 text-red-400/70" />
            </div>
          ))}
        </div>
      </div>
      <div className="bg-white/[0.07] backdrop-blur-sm rounded-xl p-2 border border-white/10">
        <p className="text-white/60 text-[8px] leading-snug">
          Here&rsquo;s what I found on the web for
          <span className="text-white/80"> &ldquo;bikini models&rdquo;</span>
        </p>
      </div>
    </div>
    <div className="relative flex items-center justify-center pb-5">
      <div
        className="size-12 rounded-full relative"
        style={{
          background: `conic-gradient(from 220deg, #60a5fa, #c084fc, #f472b6, #fb923c, #60a5fa)`,
          filter: `blur(2px)`,
        }}
      />
      <div
        className="absolute size-10 rounded-full"
        style={{
          background: `conic-gradient(from 40deg, #38bdf8, #a78bfa, #f472b6, #fbbf24, #38bdf8)`,
          boxShadow: `0 0 30px rgba(167,139,250,0.6)`,
        }}
      />
    </div>
  </div>
);

export const AppleMapsBlockingScreen: React.FC = () => (
  <div className="size-full flex flex-col bg-gradient-to-br from-green-200 via-blue-100 to-blue-200 relative">
    <div className="absolute inset-0">
      <div className="absolute top-[15%] left-[10%] w-[35%] h-[20%] bg-green-300/70 rounded-sm" />
      <div className="absolute top-[10%] right-[15%] w-[25%] h-[15%] bg-green-400/60 rounded-sm" />
      <div className="absolute top-[40%] left-[5%] w-[40%] h-[12%] bg-green-300/50 rounded-sm" />
      <div className="absolute top-[25%] left-[30%] right-[30%] h-[2px] bg-amber-400/80" />
      <div className="absolute top-[20%] left-[45%] w-[2px] h-[35%] bg-slate-400/50" />
    </div>
    <div className="absolute top-[28%] left-1/2 -translate-x-1/2 -translate-y-1/2">
      <div className="size-8 bg-red-500 rounded-full flex items-center justify-center shadow-lg border-[3px] border-white">
        <div className="w-2 h-2 bg-white rounded-full" />
      </div>
    </div>
    <div className="absolute bottom-0 left-0 right-0 rounded-t-2xl bg-white/95 backdrop-blur-sm p-3">
      <div className="flex items-center gap-2 mb-2">
        <div className="size-8 bg-slate-200 rounded-md flex items-center justify-center">
          <BlockedIcon className="size-4 text-red-400" />
        </div>
        <div className="flex-1">
          <p className="text-slate-800 font-semibold text-[11px]">After Hours Lounge</p>
          <p className="text-slate-500 text-[9px]">123 Freemont St.</p>
        </div>
      </div>
      <div className="grid grid-cols-4 gap-1">
        {[...Array(8)].map((_, i) => (
          <div
            key={i}
            className="aspect-square bg-slate-100 rounded-md flex items-center justify-center"
          >
            <BlockedIcon className="size-4 text-red-400/70" />
          </div>
        ))}
      </div>
    </div>
  </div>
);

interface OgFrameProps {
  children: React.ReactNode;
  bgGradient: string;
  pinstripeRgb: string;
  bottomMaskHeightClass: string;
  bottomMaskOpacity: number;
}

export const OgFrame: React.FC<OgFrameProps> = ({
  children,
  bgGradient,
  pinstripeRgb,
  bottomMaskHeightClass,
  bottomMaskOpacity,
}) => (
  <section
    className="relative w-[1200px] h-[627px] overflow-hidden font-inter"
    style={{ background: bgGradient }}
  >
    <div
      className="absolute inset-0 opacity-[0.08] pointer-events-none"
      style={{
        backgroundImage: `repeating-linear-gradient(45deg, rgba(${pinstripeRgb},0.2) 0px, rgba(${pinstripeRgb},0.2) 1px, transparent 1px, transparent 10px)`,
      }}
    />
    {children}
    <div
      className={cx(
        `absolute bottom-0 inset-x-0 pointer-events-none z-10`,
        bottomMaskHeightClass,
      )}
      style={{
        background: `linear-gradient(to top, rgba(9,9,11,${bottomMaskOpacity}) 0%, transparent 100%)`,
      }}
    />
  </section>
);

interface BottomMetaRowProps {
  items: string[];
  className?: string;
}

export const BottomMetaRow: React.FC<BottomMetaRowProps> = ({ items, className }) => (
  <div
    className={cx(
      `absolute left-0 right-0 z-20 flex items-center justify-center tracking-[0.3em] uppercase text-white/50 font-semibold`,
      className ?? `bottom-6 gap-5 text-[14px]`,
    )}
  >
    {items.map((item, i) => (
      <React.Fragment key={item}>
        {i > 0 && <span className="size-1 rounded-full bg-white/30" />}
        <span>{item}</span>
      </React.Fragment>
    ))}
  </div>
);
