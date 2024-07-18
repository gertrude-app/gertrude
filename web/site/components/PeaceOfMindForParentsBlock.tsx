'use client';

import React, { useState } from 'react';
import { RocketIcon, VideoIcon } from 'lucide-react';
import { useIntersectionObserver, useScrollY, useWindowDimensions } from '../lib/hooks';
import WebsiteGraphic from './WebsiteGraphic';
import FancyLink from './FancyLink';
import VideoModal from './VideoModal';

const PeaceOfMindForParentsBlock: React.FC = () => {
  const { intersected, ref: illustration } = useIntersectionObserver({ threshold: 1 });
  const { width: windowWidth, height: windowHeight } = useWindowDimensions();
  const [showingVideo, setShowingVideo] = useState(false);
  const scrollY = useScrollY();

  return (
    <div className="bg-fuchsia-500 px-6 sm:px-8 xs:px-12 md:px-20 py-28 pb-64 min-[1450px]:pb-48 flex flex-col min-[1450px]:flex-row gap-80 min-[1450px]:gap-16 items-center justify-center">
      <div
        className="flex-grow max-w-3xl sticky top-[calc(50vh-250px)] min-[1450px]:top-0 min-[1450px]:relative flex flex-col items-center min-[1450px]:items-start"
        style={{
          transform:
            windowWidth < 1450
              ? `scale(${Math.max(2 - Math.max((scrollY - 200) / windowHeight, 1), 0.5)})`
              : ``,
          filter:
            windowWidth < 1450
              ? `blur(${Math.max(0, scrollY - 200 - windowHeight) / 10}px)`
              : ``,
        }}
      >
        <h2 className="text-4xl xs:text-5xl md:text-6xl font-semibold text-white text-center min-[1450px]:text-left">
          Peace of mind for parents
        </h2>
        <p className="mt-8 text-white/80 text-lg xs:text-xl md:text-2xl leading-[1.5em] text-center min-[1450px]:text-left">
          Gertrude lets you block the entire internet, only unlocking the portions you
          choose. Keep your kids only and exactly where you want them to be online. Plus,
          review screenshots and keystrokes of their activity from your own computer or
          phone. Mac parental controls have never been this good.
        </p>
        <div className="flex flex-col md:flex-row gap-6 mt-12 self-stretch sm:self-center min-[1450px]:self-start">
          <FancyLink
            type="link"
            href="https://parents.gertrude.app/signup?v=new_site"
            Icon={RocketIcon}
            inverted
            color="primary"
            size="lg"
          >
            Get started
          </FancyLink>
          <FancyLink
            type="button"
            onClick={() => setShowingVideo(true)}
            Icon={VideoIcon}
            inverted
            size="lg"
          >
            Watch demo video
          </FancyLink>
        </div>
      </div>
      <div
        ref={illustration}
        className="flex-grow relative h-112 flex justify-center items-center max-w-[640px] min-w-[600px] scale-[55%] xs:scale-75 sm:scale-90 md:scale-100"
      >
        <div className="w-176 h-176 [background:radial-gradient(rgb(255_255_255/0.5),transparent_70%)] hidden min-[1450px]:block" />
        <WebsiteGraphic
          variant={1}
          initiallyAllowed={true}
          className="absolute left-8 delay-1"
          bottom={0}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={2}
          initiallyAllowed={true}
          className="absolute left-[calc(50%-75px)] delay-100"
          bottom={6}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={3}
          initiallyAllowed={true}
          className="absolute right-8 delay-200"
          bottom={-6}
          intersected={intersected}
        />

        <WebsiteGraphic
          variant={1}
          initiallyAllowed={false}
          className="absolute left-0 -rotate-6"
          bottom={8}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={2}
          initiallyAllowed={false}
          className="absolute left-6 rotate-3"
          bottom={0}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={3}
          initiallyAllowed={false}
          className="absolute left-20 rotate-12"
          bottom={12}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={1}
          initiallyAllowed={false}
          className="absolute left-36 -rotate-12"
          bottom={-4}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={2}
          initiallyAllowed={false}
          className="absolute left-52"
          bottom={4}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={3}
          initiallyAllowed={false}
          className="absolute left-64 rotate-6"
          bottom={16}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={1}
          initiallyAllowed={false}
          className="absolute right-0 rotate-12"
          bottom={12}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={2}
          initiallyAllowed={false}
          className="absolute right-16 rotate-6"
          bottom={0}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={3}
          initiallyAllowed={false}
          className="absolute right-32 -rotate-12"
          bottom={8}
          intersected={intersected}
        />
        <WebsiteGraphic
          variant={2}
          initiallyAllowed={false}
          className="absolute right-36 rotate-12"
          bottom={-8}
          intersected={intersected}
        />
      </div>
      {showingVideo && (
        <VideoModal videoId="Mr8_ufrkDZs" onDismiss={() => setShowingVideo(false)} />
      )}
    </div>
  );
};

export default PeaceOfMindForParentsBlock;
