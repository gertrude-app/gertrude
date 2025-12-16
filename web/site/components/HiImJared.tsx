'use client';

import { PodcastIcon, YoutubeIcon } from 'lucide-react';
import React, { useRef } from 'react';
import { useIntersectionVisibility } from '@/lib/hooks';

const HiImJared: React.FC = () => {
  const sectionRef = useRef<HTMLDivElement>(null);
  const isVisible = useIntersectionVisibility(sectionRef, 0.3);

  return (
    <section
      ref={sectionRef}
      className="bg-gradient-to-b from-slate-900 to-slate-950 px-6 sm:px-8 md:px-20 py-24 sm:py-32 md:py-40"
    >
      <div className="max-w-5xl mx-auto">
        <div className="flex flex-col md+:flex-row items-center gap-12 md+:gap-16 lg:gap-24">
          <div className="relative shrink-0">
            <div
              className={`relative transition-all duration-700 ${
                isVisible
                  ? `opacity-100 rotate-[-5deg] scale-100`
                  : `opacity-0 rotate-0 scale-95`
              }`}
              style={{ transitionDelay: isVisible ? `200ms` : `0ms` }}
            >
              <div className="bg-white p-2 xs:p-3 sm:p-4 shadow-2xl shadow-black/40">
                <img
                  src="/family.jpg"
                  alt="Jared and his family"
                  width={320}
                  height={240}
                  className="w-56 xs:w-64 sm:w-72 md:w-80 aspect-[4/3] object-cover"
                />
              </div>
            </div>
            <img
              src="/arrow.png"
              alt=""
              width={96}
              height={96}
              className={`absolute top-[10%] left-[15%] md:top-[11%] md:left-[18%] w-16 xs:w-20 sm:w-24 transition-opacity duration-500 ${
                isVisible ? `opacity-100` : `opacity-0`
              }`}
              style={{
                transitionDelay: isVisible ? `2000ms` : `0ms`,
                transform: `rotate(150deg)`,
                animation: isVisible ? `waggle-arrow 0.6s ease-in-out 2.1s` : `none`,
              }}
            />
          </div>

          <div className="text-center md+:text-left">
            <h2
              className={`text-4xl sm:text-5xl font-semibold text-white mb-6 transition-all duration-500 ${
                isVisible ? `opacity-100 translate-y-0` : `opacity-0 translate-y-8`
              }`}
              style={{ transitionDelay: isVisible ? `400ms` : `0ms` }}
            >
              <span
                className="text-[1.75rem] xs:text-[2.25rem] sm:text-[2.75rem]"
                role="img"
                aria-label="waving hand"
              >
                👋
              </span>
              {` `}
              Hi, I&rsquo;m{` `}
              <span className="bg-gradient-to-r from-violet-400 to-fuchsia-400 bg-clip-text text-transparent">
                Jared!
              </span>
            </h2>
            <p
              className={`text-white/80 text-base xs:text-lg sm:text-xl leading-relaxed max-w-xl transition-all duration-500 ${
                isVisible ? `opacity-100 translate-y-0` : `opacity-0 translate-y-8`
              }`}
              style={{ transitionDelay: isVisible ? `600ms` : `0ms` }}
            >
              I&rsquo;m a Christian, a homeschool dad, and a computer programmer. I built
              all the Gertrude apps first to protect my own kids. I care a ton about
              helping provide simple, strict, and reliable tools to protect the hearts of
              the next generation.
            </p>
            <div
              className={`mt-10 flex flex-col gap-3 text-left transition-all duration-500 ${
                isVisible ? `opacity-100 translate-y-0` : `opacity-0 translate-y-8`
              }`}
              style={{ transitionDelay: isVisible ? `800ms` : `0ms` }}
            >
              <a
                href="https://www.youtube.com/watch?v=syC94X5LBIc"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3.5 px-4 py-2.5 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-colors group"
              >
                <YoutubeIcon className="opacity-75 size-7 text-violet-500 group-hover:text-violet-300" />
                <span className="text-sm leading-tight text-white/60 group-hover:text-white/90">
                  Watch me give a talk on &ldquo;Internet Safety 101&rdquo;
                </span>
              </a>
              <a
                href="https://changelog.com/friends/19"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3.5 px-4 py-2.5 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-colors group"
              >
                <PodcastIcon className="opacity-75 size-7 text-violet-500 group-hover:text-violet-300" />
                <span className="text-sm leading-tight text-white/60 group-hover:text-white/90">
                  Hear me being interviewed on The Changelog podcast
                </span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HiImJared;
