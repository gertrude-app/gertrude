import React from 'react';
import cx from 'classnames';

export const ICONS = [
  `comment`,
  `google-chrome`,
  `location`,
  `unlock`,
  `calendar`,
  `app-store`,
  `globe`,
  `lightning-bolt`,
  `window`,
  `pen-to-square`,
  `info`,
  `list`,
  `bug`,
  `exclamation-triangle`,
  `hamburger`,
  `desktop`,
  `key`,
  `user-plus`,
  `user`,
  `users`,
  `pen`,
  `email`,
  `phone`,
  `slack`,
  `laptop`,
  `binoculars`,
  `clock`,
  `thumbs-up`,
] as const;

export type IconType = typeof ICONS[number];

interface Props {
  className?: string;
  icon: IconType;
  size: `small` | `medium` | `large`;
  subtle?: boolean;
}

const CLASS_MAP: Record<Props['icon'], string> = {
  calendar: `fa-solid fa-calendar-days`,
  comment: `fa-solid fa-comment`,
  clock: `fa-solid fa-clock`,
  location: `fa-solid fa-location scale-110`,
  'app-store': `fa-brands fa-app-store-ios scale-110`,
  'pen-to-square': `fa-solid fa-pen-to-square`,
  'google-chrome': `fa-brands fa-chrome`,
  'lightning-bolt': `fa-solid fa-bolt`,
  unlock: `fa-solid fa-unlock`,
  globe: `fa-solid fa-earth-americas`,
  window: `fa-solid fa-window-maximize`,
  'exclamation-triangle': `fa-solid fa-exclamation-triangle -translate-y-px`,
  info: `fa-solid fa-info`,
  bug: `fa-solid fa-bug`,
  list: `fa-solid fa-list`,
  hamburger: `fa-solid fa-hamburger`,
  desktop: `fa-solid fa-desktop translate-y-px`,
  key: `fa-solid fa-key`,
  user: `fa-solid fa-user`,
  'user-plus': `fa-solid fa-user-plus scale-90 translate-x-px`,
  users: `fa-solid fa-users`,
  pen: `fa-solid fa-pen`,
  email: `fa-solid fa-envelope`,
  phone: `fa-solid fa-mobile`,
  slack: `fa-brands fa-slack`,
  laptop: `fa-solid fa-laptop`,
  binoculars: `fa-solid fa-binoculars`,
  'thumbs-up': `fa-solid fa-thumbs-up translate-x-px`,
};

const GradientIcon: React.FC<Props> = ({ icon, className, size, subtle = false }) => {
  if (size === `small`) {
    return (
      <i
        className={cx(
          `bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent`,
          CLASS_MAP[icon],
          className,
        )}
      />
    );
  }
  return (
    <div
      className={cx(
        `flex flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-fuchsia-500`,
        size === `large` ? `h-12 w-12` : `h-10 w-10`,
        className,
      )}
    >
      <i
        className={cx(
          `text-white`,
          size === `large` && `text-2xl`,
          subtle ? `text-opacity-80 text-md` : `text-lg`,
          CLASS_MAP[icon],
        )}
      />
    </div>
  );
};

export default GradientIcon;
