import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';

interface Props {
  src: string;
  alt: string;
  width: number;
  height: number;
  className?: string;
}

const ExpandableImage: React.FC<Props> = ({ src, alt, width, height, className }) => {
  const [imageExpanded, setImageExpanded] = useState(false);
  const [imageFrameCoords, setImageFrameCoords] = useState({ x: 0, y: 0 });
  const imageFrameRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (imageFrameRef.current) {
      const { x, y } = imageFrameRef.current.getBoundingClientRect();
      setImageFrameCoords({ x, y });
    }
  }, []);

  return (
    <div
      ref={imageFrameRef}
      className={cx(`shrink-0`, className)}
      style={{
        width,
        height,
      }}
    >
      {imageFrameRef.current && (
        <img
          className={cx(
            `rounded-3xl mb-6 cursor-pointer absolute`,
            imageExpanded
              ? `cursor-zoom-out shadow-xl shadow-slate-500/50`
              : `cursor-zoom-in`,
          )}
          style={{
            width: imageExpanded ? `calc(90%)` : imageFrameRef.current?.clientWidth,
            left: imageExpanded
              ? window.innerWidth / 2 - 0.45 * window.innerWidth
              : imageFrameCoords.x,
            top: imageExpanded ? 80 : imageFrameCoords.y,
            transitionProperty: `width, left, top, box-shadow`,
            transitionDuration: `500ms`,
          }}
          src={src}
          alt={alt}
          onClick={() => setImageExpanded(!imageExpanded)}
        />
      )}
    </div>
  );
};

export default ExpandableImage;
