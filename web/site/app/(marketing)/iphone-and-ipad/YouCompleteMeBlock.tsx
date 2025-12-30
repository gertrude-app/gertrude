import React from 'react';

const HeartIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
  </svg>
);

interface AppIconCardProps {
  gradient: string;
  src: string;
  alt: string;
  label: string;
}

const AppIconCard: React.FC<AppIconCardProps> = ({ gradient, src, alt, label }) => (
  <div className="relative group">
    <div
      className={`absolute inset-0 ${gradient} rounded-3xl blur-xl opacity-50 group-hover:opacity-70 transition-opacity`}
    />
    <div className={`relative ${gradient} rounded-3xl p-1`}>
      <div className="bg-slate-900 rounded-[20px] p-3 xs:p-4">
        <img
          src={src}
          alt={alt}
          className="size-[4.5rem] xs:size-20 sm:size-24 rounded-2xl object-cover mx-auto"
        />
        <p className="text-white font-semibold text-center mt-2 xs:mt-3 text-xs xs:text-sm sm:text-base">
          {label}
        </p>
      </div>
    </div>
  </div>
);

const YouCompleteMeBlock: React.FC = () => (
  <section className="bg-gradient-to-b from-slate-900 via-violet-950 to-slate-900 py-20 sm:py-28 lg:py-32 overflow-hidden">
    <div className="max-w-5xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="text-center mb-16">
        <h2 className="text-[2.75rem] xs:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-3 leading-[1.1]">
          <span className="text-slate-400">&ldquo;</span>You{` `}
          <span className="bg-gradient-to-r from-pink-400 via-rose-400 to-red-400 bg-clip-text text-transparent">
            complete
          </span>
          {` `}me.<span className="text-slate-400">&rdquo;</span>
        </h2>
        <p className="text-lg xs:text-xl md:text-2xl text-slate-400 italic mb-2">
          &mdash; Screen Time, to Gertrude
        </p>
      </div>
      <div className="relative flex flex-row items-center justify-center gap-4 xs:gap-6 sm:gap-8 mb-16">
        <AppIconCard
          gradient="bg-gradient-to-br from-purple-500 to-indigo-600"
          src="/screen-time-icon.png"
          alt="Screen Time"
          label="Screen Time"
        />
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-10">
          <div className="bg-slate-900 rounded-full p-1.5 xs:p-2 shadow-xl">
            <HeartIcon className="size-6 xs:size-8 sm:size-10 text-pink-400" />
          </div>
        </div>
        <AppIconCard
          gradient="bg-gradient-to-br from-violet-500 to-fuchsia-500"
          src="/gertrude-icon.png"
          alt="Gertrude"
          label="Gertrude"
        />
      </div>
      <div className="max-w-3xl mx-auto text-center">
        <p className="text-xl xs:text-2xl md:text-3xl text-white font-medium mb-6">
          Gertrude works <span className="text-violet-400 font-bold italic">with</span>
          {` `}Screen Time for 100% protection.
        </p>
        <p className="text-lg xs:text-xl text-slate-400 leading-relaxed">
          Screen Time is great, but in recent years Apple has dropped the ball for
          parents, allowing{` `}
          <a
            href="https://discussions.apple.com/thread/254820669"
            target="_blank"
            rel="nofollow noopener noreferrer"
            className="text-slate-300 hover:text-violet-400 transition-colors"
          >
            several
          </a>
          {` `}
          <a
            href="https://discussions.apple.com/thread/255165706"
            target="_blank"
            rel="nofollow noopener noreferrer"
            className="text-slate-300 hover:text-violet-400 transition-colors"
          >
            well-known
          </a>
          {` `}and{` `}
          <a
            href="https://discussions.apple.com/thread/250347853"
            target="_blank"
            rel="nofollow noopener noreferrer"
            className="text-slate-300 hover:text-violet-400 transition-colors"
          >
            dangerous
          </a>
          {` `}
          <a
            href="https://discussions.apple.com/thread/255387094"
            target="_blank"
            rel="nofollow noopener noreferrer"
            className="text-slate-300 hover:text-violet-400 transition-colors"
          >
            loopholes
          </a>
          {` `}to go unaddressed. Gertrude fills in the gaps, giving you back complete
          control over your kids&apos; iPhones and iPads.
        </p>
      </div>
    </div>
  </section>
);

export default YouCompleteMeBlock;
