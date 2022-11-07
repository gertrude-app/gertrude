import React, { useId } from 'react';
import cx from 'classnames';

interface Props {
  size?: number;
  iconOnly?: boolean;
  className?: string;
  type?: 'default' | 'inverted' | 'on-dark';
  textSize?:
    | 'text-base'
    | 'text-lg'
    | 'text-xl'
    | 'text-2xl'
    | 'text-3xl'
    | 'text-4xl'
    | 'text-5xl';
}

const Logo: React.FC<Props> = ({
  size = 40,
  className,
  iconOnly,
  type = `default`,
  textSize = `text-4xl`,
}) => {
  const gradientId = useId();
  let outerColor = ``;
  let innerColor = ``;

  switch (type) {
    case `inverted`:
      outerColor = `white`;
      innerColor = `#8b5cf6`;
      break;
    case `on-dark`:
      outerColor = `white`;
      innerColor = `#13182b`;
      break;
    default:
      outerColor = `url(#${gradientId})`;
      innerColor = `white`;
  }

  return (
    <div className={cx(`flex items-center justify-start`, className)}>
      <svg
        height={size}
        viewBox="0 0 35 35"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M2.95086 22.3525C0.216576 19.6194 0.216574 15.1883 2.95086 12.4552L12.4617 2.94862C15.196 0.215571 19.6292 0.215571 22.3635 2.94862L32.0667 12.6475C34.801 15.3806 34.801 19.8117 32.0667 22.5448L22.5558 32.0514C19.8215 34.7844 15.3884 34.7844 12.6541 32.0514L2.95086 22.3525Z"
          fill={outerColor}
        />
        <path
          d="M8.17925 18.3251C6.97568 16.4726 7.50214 13.9958 9.35513 12.793L16.465 8.17786C18.318 6.97506 20.7958 7.50174 21.9994 9.35423L26.6158 16.4597C27.8194 18.3122 27.2929 20.789 25.4399 21.9918L18.33 26.6069C16.477 27.8097 13.9992 27.283 12.7957 25.4305L8.17925 18.3251Z"
          fill={innerColor}
        />
        {type === `default` && (
          <defs>
            <linearGradient
              id={gradientId}
              x1="17.5088"
              y1="0.898834"
              x2="17.5088"
              y2="34.1011"
              gradientUnits="userSpaceOnUse"
            >
              <stop stopColor="#8B5CF6" />
              <stop offset="1" stopColor="#D846EF" />
            </linearGradient>
          </defs>
        )}
      </svg>
      {!iconOnly && (
        <div
          className={cx(
            `font-lato ml-2 whitespace-nowrap`,
            type === `inverted` || type === `on-dark` ? `text-white` : `text-gray-700`,
            textSize,
          )}
        >
          Gertrude
        </div>
      )}
    </div>
  );
};

export default Logo;
