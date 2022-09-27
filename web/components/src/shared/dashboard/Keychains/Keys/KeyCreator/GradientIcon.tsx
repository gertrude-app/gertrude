import React from 'react';
import cx from 'classnames';

interface Props {
  className?: string;
  icon:
    | 'comment'
    | 'google-chrome'
    | 'location'
    | 'unlock'
    | 'calendar'
    | 'app-store'
    | 'globe'
    | 'lightning-bolt'
    | 'window'
    | 'pen-to-square';
}

const CLASS_MAP: Record<Props['icon'], string> = {
  calendar: `fa-solid fa-calendar-days`,
  comment: `fa-solid fa-comment`,
  location: `fa-solid fa-location scale-110`,
  'app-store': `fa-brands fa-app-store-ios scale-125`,
  'pen-to-square': `fa-solid fa-pen-to-square`,
  'google-chrome': `fa-brands fa-chrome`,
  'lightning-bolt': `fa-solid fa-bolt`,
  unlock: `fa-solid fa-unlock`,
  globe: `fa-solid fa-earth-americas`,
  window: `fa-solid fa-window-maximize`,
};

const GradientIcon: React.FC<Props> = ({ icon, className }) => {
  return (
    <i
      className={cx(
        `bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent`,
        CLASS_MAP[icon],
        className,
      )}
    />
  );
};

export default GradientIcon;
