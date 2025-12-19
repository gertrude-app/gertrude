import { BellIcon } from '@heroicons/react/24/outline';
import {
  Bars3Icon,
  BoltIcon,
  BugAntIcon,
  CalendarDaysIcon,
  ChatBubbleOvalLeftIcon,
  ClockIcon,
  Cog6ToothIcon,
  ComputerDesktopIcon,
  DevicePhoneMobileIcon,
  EnvelopeIcon,
  ExclamationTriangleIcon,
  GlobeAmericasIcon,
  HandThumbDownIcon,
  HandThumbUpIcon,
  HomeIcon,
  InformationCircleIcon,
  KeyIcon,
  ListBulletIcon,
  LockOpenIcon,
  MapPinIcon,
  PencilIcon,
  QuestionMarkCircleIcon,
  ShieldCheckIcon,
  UserIcon,
  UserPlusIcon,
  UsersIcon,
  WindowIcon,
} from '@heroicons/react/24/solid';
import cx from 'classnames';
import React from 'react';
import type { HeroIcon } from '@dash/types';

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
  `edit`,
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
  `thumbs-down`,
  `stopwatch`,
  `question`,
  `home`,
  `cog`,
  `shield`,
  `bell`,
] as const;

export type IconType = (typeof ICONS)[number];

interface Props {
  className?: string;
  icon: IconType;
  size: `small` | `medium` | `large`;
}

const CLASS_MAP: Record<IconType, HeroIcon | string> = {
  calendar: CalendarDaysIcon,
  comment: ChatBubbleOvalLeftIcon,
  clock: ClockIcon,
  location: MapPinIcon,
  'app-store': `fa-brands fa-app-store-ios scale-110`,
  edit: `fa-solid fa-pen-to-square`,
  'google-chrome': `fa-brands fa-chrome`,
  'lightning-bolt': BoltIcon,
  unlock: LockOpenIcon,
  globe: GlobeAmericasIcon,
  home: HomeIcon,
  window: WindowIcon,
  'exclamation-triangle': ExclamationTriangleIcon,
  info: InformationCircleIcon,
  bug: BugAntIcon,
  list: ListBulletIcon,
  hamburger: Bars3Icon,
  desktop: ComputerDesktopIcon,
  key: KeyIcon,
  user: UserIcon,
  'user-plus': UserPlusIcon,
  users: UsersIcon,
  pen: PencilIcon,
  email: EnvelopeIcon,
  phone: DevicePhoneMobileIcon,
  slack: `fa-brands fa-slack`,
  question: QuestionMarkCircleIcon,
  laptop: `fa-solid fa-laptop`,
  binoculars: `fa-solid fa-binoculars`,
  'thumbs-up': HandThumbUpIcon,
  'thumbs-down': HandThumbDownIcon,
  stopwatch: `fa-solid fa-stopwatch`,
  cog: Cog6ToothIcon,
  shield: ShieldCheckIcon,
  bell: BellIcon,
};

const GradientIcon: React.FC<Props> = ({ icon, className, size }) => {
  const Icon = CLASS_MAP[icon];
  if (size === `small`) {
    if (typeof Icon === `string`) {
      return <i className={cx(`text-violet-500`, Icon, className)} />;
    }
    return <Icon className={cx(`w-5 h-5 text-violet-500`, className)} />;
  }
  return (
    <div
      className={cx(
        `inline-flex flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-fuchsia-500`,
        size === `large` ? `h-12 w-12` : `h-10 w-10`,
        className,
      )}
    >
      {typeof Icon === `string` ? (
        <i className={cx(`text-white`, size === `large` && `text-2xl`, Icon)} />
      ) : (
        <Icon className={cx(`text-white w-5`, size === `large` && `w-6`)} />
      )}
    </div>
  );
};

export default GradientIcon;
