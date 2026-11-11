import React from 'react';

interface HomeFeatureCaptionProps {
  title: string;
  description: string;
  backgroundImage: string;
  backgroundOpacity?: number;
  inverted?: boolean;
}

const HomeFeatureCaption: React.FC<HomeFeatureCaptionProps> = ({
  title,
  description,
  backgroundImage,
  backgroundOpacity = 0.25,
  inverted = false,
}) => (
  <p
    className={`mt-5 text-base leading-7 sm:text-lg ${inverted ? `text-stone-400` : `text-stone-500`}`}
  >
    <strong
      className={`relative inline-block font-semibold mr-1.5 ${
        inverted ? `text-stone-50` : `text-stone-950`
      }`}
    >
      <img
        src={backgroundImage}
        alt=""
        width={600}
        height={100}
        loading="lazy"
        decoding="async"
        className="pointer-events-none absolute inset-y-0 -inset-x-1 h-full w-[calc(100%+0.5rem)] max-w-none rounded-lg object-cover"
        style={{ opacity: backgroundOpacity }}
      />
      <span className="relative">{title}</span>
    </strong>
    {` `}
    {description}
  </p>
);

export default HomeFeatureCaption;
