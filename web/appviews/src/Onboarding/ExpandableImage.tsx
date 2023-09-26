import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';

interface Props {
  src: string;
  alt: string;
  width: number;
  height: number;
  className?: string;
  showInstructions?: boolean;
}

const ExpandableImage: React.FC<Props> = ({
  src,
  alt,
  width,
  height,
  className,
  showInstructions,
}) => {
  const [imageExpanded, setImageExpanded] = useState(false);
  const [imageFrameCoords, setImageFrameCoords] = useState({ x: 0, y: 0 });
  const [hasBeenExpanded, setHasBeenExpanded] = useState(false);
  const imageFrameRef = useRef<HTMLDivElement>(null);

  const aspectRatio = width / height;
  const maxWidth = 800;

  const imageFrameBoundingRect = imageFrameRef.current?.getBoundingClientRect();

  useEffect(() => {
    if (imageFrameBoundingRect) {
      setImageFrameCoords({ x: imageFrameBoundingRect.x, y: imageFrameBoundingRect.y });
    }
  }, [imageFrameBoundingRect]);

  return (
    <>
      <div
        className={cx(
          `w-full h-full absolute left-0 top-0 bg-white/30 transition-[opacity,backdrop-filter] duration-500 z-10`,
          imageExpanded
            ? `opacity-100 backdrop-blur-lg`
            : `opacity-0 pointer-events-none`,
        )}
        onClick={() => setImageExpanded(false)}
      />
      <div
        ref={imageFrameRef}
        className={cx(
          `shrink-0 z-20 flex justify-center bg-slate-200/50 rounded-3xl shadow-inner shadow-slate-300/30`,
          className,
        )}
        style={{
          width,
          height,
        }}
      >
        {showInstructions && (
          <div
            className={cx(
              `relative -top-12 flex flex-col items-center gap-1.5 text-slate-400 text-sm transition-opacity duration-300`,
              hasBeenExpanded && `opacity-0`,
            )}
          >
            <span>Click to enlarge</span>
            <i className="fa-solid fa-chevron-down animate-bounce" />
          </div>
        )}
        {imageFrameRef.current && (
          <img
            className={cx(
              `rounded-3xl mb-6 cursor-pointer absolute object-cover object-center`,
              imageExpanded
                ? `cursor-zoom-out shadow-2xl shadow-slate-500/50`
                : `cursor-zoom-in`,
            )}
            style={{
              width: imageExpanded
                ? `min(90%, ${800}px)`
                : imageFrameRef.current.clientWidth,
              height: imageExpanded
                ? `min(${90 / aspectRatio}vw, ${maxWidth / aspectRatio}px)`
                : imageFrameRef.current.clientHeight,
              left: imageExpanded
                ? Math.max(
                    window.innerWidth / 2 - 0.45 * window.innerWidth,
                    window.innerWidth / 2 - 400,
                  )
                : imageFrameCoords.x,
              top: imageExpanded
                ? window.innerHeight / 2 -
                  Math.min(0.9 * window.innerWidth, 800) / (aspectRatio * 2)
                : imageFrameCoords.y,
              transitionProperty: `width, height, left, top, box-shadow`,
              transitionDuration: `500ms`,
            }}
            src={src}
            alt={alt}
            onClick={() => {
              setImageExpanded(!imageExpanded);
              setHasBeenExpanded(true);
            }}
          />
        )}
      </div>
    </>
  );
};

export default ExpandableImage;
