import React, { useEffect, useRef, useState, useContext } from 'react';
import cx from 'classnames';
import useWindowWidth from '../lib/hooks';
import OnboardingContext from './OnboardingContext';

interface Props {
  fileName: string;
  width: number;
  height: number;
  lessRounded?: boolean;
  showInstructions?: boolean;
  className?: string;
}

const ExpandableImage: React.FC<Props> = ({
  fileName,
  width,
  height,
  showInstructions = true,
  lessRounded = false,
  className,
}) => {
  const { os } = useContext(OnboardingContext);
  const [imageExpanded, setImageExpanded] = useState(false);
  const [imageFrameCoords, setImageFrameCoords] = useState({ x: 0, y: 0 });
  const [hasBeenExpanded, setHasBeenExpanded] = useState(false);
  const imageFrameRef = useRef<HTMLDivElement>(null);
  const windowWidth = useWindowWidth();

  const aspectRatio = width / height;
  const maxWidth = 800;

  useEffect(() => {
    if (imageFrameRef.current) {
      const x = imageFrameRef.current.offsetLeft;
      const y = imageFrameRef.current.offsetTop;
      setImageFrameCoords({ x, y });
    }
  }, [imageFrameRef, windowWidth]);

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
        {imageFrameRef.current && (
          <img
            className={cx(
              `mb-6 cursor-pointer absolute object-cover object-center`,
              imageExpanded
                ? `cursor-zoom-out shadow-2xl shadow-slate-500/50`
                : `cursor-zoom-in`,
              lessRounded ? `rounded-lg` : `rounded-3xl`,
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
              transitionDuration: hasBeenExpanded ? `250ms` : `0`,
            }}
            src={`https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/${os}/${fileName}`}
            alt=""
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
