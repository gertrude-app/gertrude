import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';
import type { CdnAsset } from './cdn-assets';
import useWindowWidth from '../lib/hooks';

interface Props {
  asset: CdnAsset | Array<{ duration: number; asset: CdnAsset<'image'> }>;
  width: number;
  height: number;
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
}) => {
  const [expanded, setExpanded] = useState(false);
  const [frameCoords, setFrameCoords] = useState({ x: 0, y: 0 });
  const [hasBeenExpanded, setHasBeenExpanded] = useState(false);
  const [currentStep, setCurrentStep] = useState(-1);
  const [autoPlay, setAutoPlay] = useState(true);
  const contentRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const windowWidth = useWindowWidth();

  const aspectRatio = width / height;
  const isMultiPart = Array.isArray(asset);
  const isImage = isMultiPart ? true : asset.type === `image`;
  const maxWidth = 800;

  useEffect(() => {
    setCurrentStep(0);
  }, []);

  useEffect(() => {
    if (contentRef.current) {
      const x = contentRef.current.offsetLeft;
      const y = contentRef.current.offsetTop;
      setFrameCoords({ x, y });
    }
  }, [contentRef, windowWidth]);

  useEffect(() => {
    if (!isMultiPart || !autoPlay) return;
    const currentAsset = asset[currentStep];
    if (!currentAsset) return;

    const timeoutId = setTimeout(() => {
      setCurrentStep((currentStep + 1) % asset.length);
    }, currentAsset.duration * 1000);

    return () => clearTimeout(timeoutId);
  }, [autoPlay, currentStep, asset, isMultiPart]);

  const style = {
    width: expanded
      ? isImage
        ? `min(90%, ${maxWidth}px)`
        : window.innerWidth
      : contentRef.current?.clientWidth,
    height: expanded
      ? isImage
        ? `min(${90 / aspectRatio}vw, ${maxWidth / aspectRatio}px)`
        : window.innerWidth / aspectRatio
      : contentRef.current?.clientHeight,
    left: expanded
      ? isImage
        ? Math.max(
            window.innerWidth / 2 - 0.45 * window.innerWidth,
            window.innerWidth / 2 - maxWidth / 2,
          )
        : 0
      : frameCoords.x,
    top: expanded
      ? window.innerHeight / 2 -
        (isImage ? Math.min(0.9 * window.innerWidth, maxWidth) : window.innerWidth) /
          (aspectRatio * 2)
      : frameCoords.y,
    transitionProperty: `width, height, left, top, box-shadow`,
    transitionDuration: hasBeenExpanded ? `250ms` : `0`,
  };

  const classes = cx(
    `mb-6 cursor-pointer absolute`,
    isImage && `object-cover object-center`,
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
        {!isImage && (
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
        <div style={style} className="absolute">
          {isImage && (
            <img
              className={classes}
              src={
                isMultiPart
                  ? asset[currentStep === -1 ? 0 : currentStep]?.asset.url
                  : asset.url
              }
              alt=""
              onClick={() => {
                setExpanded(!expanded);
                setHasBeenExpanded(true);
              }}
            />
          )}
          {!isImage && !isMultiPart && (
            <div
              style={style}
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
          {isMultiPart && (
            <div className="rounded-full absolute w-full h-4 -bottom-8 flex justify-center items-center gap-2">
              {asset.map((a, i) => (
                <div
                  key={a.asset.url}
                  onClick={() => {
                    setAutoPlay(false);
                    setCurrentStep(i);
                  }}
                  className={cx(
                    `h-3 rounded-full bg-slate-300 transition-[background-color,width,transform] duration-300 hover:scale-110 cursor-pointer relative overflow-hidden`,
                    currentStep === i ? `w-12` : `w-3`,
                    expanded && `!bg-slate-400/60`,
                  )}
                >
                  <div
                    style={{
                      // animate-progress-right <- need this since it's never being used as a tailwind utility
                      animation:
                        currentStep === i
                          ? `progress-right ${a.duration}s 0s linear infinite`
                          : `none`,
                    }}
                    className={cx(
                      `absolute left-0 top-0 w-2 h-full bg-violet-400`,
                      currentStep !== i && `opacity-0`,
                      expanded && `!bg-violet-500`,
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
