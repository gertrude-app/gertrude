import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';
import type { CdnAsset } from './cdn-assets';
import useWindowWidth from '../lib/hooks';

interface Props {
  asset: CdnAsset;
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
  const contentRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const windowWidth = useWindowWidth();

  const aspectRatio = width / height;
  const isImage = asset.type === `image`;
  const maxWidth = 800;

  useEffect(() => {
    if (contentRef.current) {
      const x = contentRef.current.offsetLeft;
      const y = contentRef.current.offsetTop;
      setFrameCoords({ x, y });
    }
  }, [contentRef, windowWidth]);

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
          `w-full h-full absolute -left-12 top-0 bg-white/30 transition-[opacity,backdrop-filter] duration-500 z-10`,
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
          <div className="absolute top-4 -right-8 text-slate-400/80 text-sm antialiased">
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
        {contentRef.current && asset.type === `video` && (
          <div
            className={cx(classes, `bg-black`)}
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
                  `transition-[width,height] duration-[250ms] cursor-pointer`,
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
        {contentRef.current && asset.type === `image` && (
          <img
            className={classes}
            style={style}
            src={asset.url}
            alt=""
            onClick={() => {
              setExpanded(!expanded);
              setHasBeenExpanded(true);
            }}
          />
        )}
      </div>
    </>
  );
};

export default ExpandableContent;
