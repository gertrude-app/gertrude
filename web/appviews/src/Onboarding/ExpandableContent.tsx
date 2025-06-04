import cx from 'classnames';
import React, { useContext, useEffect, useRef, useState } from 'react';
import type { CdnAsset } from './cdn-assets';
import useWindowWidth from '../lib/hooks';
import { WithinActiveStepContext } from './OnboardingContext';

interface Props {
  asset: CdnAsset;
  width: number;
  height: number;
  maxWidth?: number;
  lessRounded?: boolean;
  showInstructions?: boolean;
  className?: string;
}

const ExpandableContent: React.FC<Props> = ({
  asset,
  width,
  height,
  showInstructions = true,
  lessRounded = false,
  className,
  maxWidth = 800,
}) => {
  const [expanded, setExpanded] = useState(false);
  const [frameCoords, setFrameCoords] = useState({ x: 0, y: 0 });
  const [hasBeenExpanded, setHasBeenExpanded] = useState(false);
  const [multiGifIndex, setMultiGifIndex] = useState(0);
  const [autoPlay, setAutoPlay] = useState(true);
  const contentRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const windowWidth = useWindowWidth();
  const withinActiveStep = useContext(WithinActiveStepContext);

  const aspectRatio = width / height;

  useEffect(() => {
    if (contentRef.current) {
      const x = contentRef.current.offsetLeft;
      const y = contentRef.current.offsetTop;
      setFrameCoords({ x, y });
    }
  }, [contentRef, windowWidth]);

  useEffect(() => {
    if (asset.type !== `images` || !autoPlay || !withinActiveStep) return;
    const currentAsset = asset.steps[multiGifIndex];
    if (!currentAsset) return;

    const timeoutId = setTimeout(() => {
      setMultiGifIndex((multiGifIndex + 1) % asset.steps.length);
    }, currentAsset.duration * 1000);

    return () => clearTimeout(timeoutId);
  }, [autoPlay, multiGifIndex, asset, withinActiveStep]);

  // preload multi-gif steps
  const stableUrls = stableMultiGifPreloadString(asset);
  useEffect(() => {
    for (const url of stableUrls.split(`,`).filter(Boolean)) {
      const image = new Image();
      image.src = url;
    }
  }, [stableUrls]);

  const style = {
    width: expanded
      ? asset.type !== `video`
        ? `min(90%, ${maxWidth}px)`
        : window.innerWidth
      : contentRef.current?.clientWidth,
    height: expanded
      ? asset.type !== `video`
        ? `min(${90 / aspectRatio}vw, ${maxWidth / aspectRatio}px)`
        : window.innerWidth / aspectRatio
      : contentRef.current?.clientHeight,
    left: expanded
      ? asset.type !== `video`
        ? Math.max(
            window.innerWidth / 2 - 0.45 * window.innerWidth,
            window.innerWidth / 2 - maxWidth / 2,
          )
        : 0
      : frameCoords.x,
    top: expanded
      ? window.innerHeight / 2 -
        (asset.type !== `video`
          ? Math.min(0.9 * window.innerWidth, maxWidth)
          : window.innerWidth) /
          (aspectRatio * 2)
      : frameCoords.y,
    transitionProperty: `width, height, left, top, box-shadow`,
    transitionDuration: hasBeenExpanded ? `250ms` : `0`,
  };

  const classes = cx(
    `mb-6 cursor-pointer absolute`,
    asset.type === `image` && `object-cover object-center`,
    expanded ? `cursor-zoom-out shadow-2xl shadow-slate-500/50` : `cursor-zoom-in`,
    lessRounded ? `rounded-lg` : `rounded-3xl`,
  );

  return (
    <>
      <div
        className={cx(
          `!ml-0 w-full h-full absolute left-0 top-0 bg-white/30 transition-[opacity,backdrop-filter] duration-500 z-10`,
          expanded
            ? `opacity-100 cursor-zoom-out backdrop-blur-lg`
            : `opacity-0 pointer-events-none`,
        )}
        onClick={() => {
          setExpanded(false);
          videoRef.current?.pause();
        }}
      >
        {asset.type === `video` && (
          <div className="absolute top-4 right-4 text-slate-400/80 text-sm antialiased">
            <i className="fa-solid fa-times mr-1" />
            <span className="uppercase">Close</span>
          </div>
        )}
      </div>
      <div
        ref={contentRef}
        className={cx(`shrink-0 z-20 flex justify-center`, className)}
        style={{
          width,
          height,
        }}
      >
        <div
          className={cx(
            `relative -top-12 flex flex-col items-center space-y-1.5 text-slate-400 text-sm transition-opacity duration-300`,
            hasBeenExpanded && `opacity-0`,
            !showInstructions && `hidden`,
          )}
        >
          <span>Click to enlarge</span>
          <i className="fa-solid fa-chevron-down animate-bounce" />
        </div>
        <div
          style={style}
          className="absolute bg-gradient-to-b from-violet-500 to-fuchsia-600 rounded-3xl"
        >
          {asset.type !== `video` && (
            <img
              className={classes}
              src={
                asset.type === `images`
                  ? withinActiveStep
                    ? asset.steps[multiGifIndex]?.url
                    : // wait for step to become active BEFORE setting gif step img, so that we
                      // start right at the beginning of step 0 when user first sees the screen
                      // or else they might find image[0] mid-stream through it's loop
                      undefined
                  : asset.url
              }
              alt=""
              onClick={() => {
                setExpanded(!expanded);
                setHasBeenExpanded(true);
              }}
            />
          )}
          {asset.type === `video` && (
            <div
              style={style}
              className={cx(
                `bg-black transition-[width,height] duration-[250ms]`,
                expanded ? `rounded-md` : `rounded-3xl`,
              )}
              onClick={() => {
                if (!expanded) {
                  setExpanded(true);
                  setHasBeenExpanded(true);
                  const video = videoRef.current;
                  if (video) {
                    video.play();
                    video.onended = () => setExpanded(false);
                  }
                }
              }}
            >
              {asset.render && (
                <video
                  tabIndex={-1} // prevent autofocus, which can cause layout issues
                  ref={videoRef}
                  preload="auto"
                  className={cx(
                    classes,
                    `transition-[width,height] duration-[250ms] !cursor-pointer`,
                    expanded ? `rounded-md` : `rounded-2xl pointer-events-none`,
                  )}
                  width={expanded ? style.width : width}
                  height={expanded ? style.height : height}
                  controls
                >
                  <source src={asset.url} type="video/mp4" />
                </video>
              )}
            </div>
          )}
          {/* don't render GIF nav till we're the active step, so progress starts at 0, in sync w/ img */}
          {(asset.type === `images` || asset.type === `gif`) && withinActiveStep && (
            <div className="rounded-full absolute w-full h-4 -bottom-8 flex justify-center items-center space-x-2">
              {(asset.type === `images`
                ? asset.steps
                : [{ url: asset.url, duration: asset.duration }]
              ).map((step, i, steps) => (
                <div
                  key={step.url}
                  onClick={() => {
                    if (steps.length > 1) {
                      setAutoPlay(false);
                      setMultiGifIndex(i);
                    }
                  }}
                  className={cx(
                    `rounded-full bg-slate-300 transition-[background-color,width,transform] duration-300 relative overflow-hidden`,
                    multiGifIndex === i ? `w-12` : `w-3`,
                    steps.length > 1 &&
                      (autoPlay || multiGifIndex !== i) &&
                      `hover:scale-110 cursor-pointer`,
                    steps.length > 1 && multiGifIndex !== i && `hover:!scale-125`,
                    steps.length > 1 ? `h-3` : `h-2 -mt-3`,
                    expanded && `!bg-slate-400/60`,
                  )}
                >
                  <div
                    style={{
                      // purgeCSS: animate-progress-right
                      animation:
                        multiGifIndex === i
                          ? `progress-right ${step.duration}s 0s linear infinite`
                          : `none`,
                    }}
                    className={cx(
                      `absolute left-0 top-0 w-2 h-full`,
                      multiGifIndex !== i && `opacity-0`,
                      {
                        'bg-violet-400': autoPlay && !expanded,
                        'bg-violet-500': autoPlay && expanded,
                        'bg-fuchsia-500/80': !autoPlay,
                      },
                    )}
                  />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default ExpandableContent;

function stableMultiGifPreloadString(asset: CdnAsset): string {
  if (asset.type !== `images`) return ``;
  return asset.steps.map((step) => step.url).join(`,`);
}
