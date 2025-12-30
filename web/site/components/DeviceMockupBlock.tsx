'use client';

import cx from 'classnames';
import React from 'react';

type BackgroundColor = `violet` | `fuchsia` | `slate` | `white` | `gradient` | `green`;

const BackgroundDecoration: React.FC = () => (
  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none">
    <svg
      viewBox="0 0 558 558"
      width="558"
      height="558"
      fill="none"
      aria-hidden="true"
      className="animate-spin-slow opacity-30"
    >
      <defs>
        <linearGradient
          id="device-gradient-1"
          x1="79"
          y1="16"
          x2="105"
          y2="237"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#d946ef" />
          <stop offset="1" stopColor="#d946ef" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path
        opacity=".2"
        d="M1 279C1 125.465 125.465 1 279 1s278 124.465 278 278-124.465 278-278 278S1 432.535 1 279Z"
        stroke="#d946ef"
      />
      <path
        d="M1 279C1 125.465 125.465 1 279 1"
        stroke="url(#device-gradient-1)"
        strokeLinecap="round"
      />
    </svg>
  </div>
);

const PhoneFrameSVG: React.FC = () => (
  <svg
    viewBox="0 0 366 729"
    aria-hidden="true"
    className="pointer-events-none absolute inset-0 h-full w-full"
  >
    <path
      fill="#1e1e1e"
      fillRule="evenodd"
      clipRule="evenodd"
      d="M300.092 1c41.22 0 63.223 21.99 63.223 63.213V184.94c-.173.184-.329.476-.458.851.188-.282.404-.547.647-.791.844-.073 2.496.257 2.496 2.157V268.719c-.406 2.023-2.605 2.023-2.605 2.023a7.119 7.119 0 0 1-.08-.102v394.462c0 41.213-22.001 63.212-63.223 63.212h-95.074c-.881-.468-2.474-.795-4.323-.838l-33.704-.005-.049.001h-.231l-.141-.001c-2.028 0-3.798.339-4.745.843H66.751c-41.223 0-63.223-21.995-63.223-63.208V287.739c-.402-.024-2.165-.23-2.524-2.02v-.973A2.039 2.039 0 0 1 1 284.62v-47.611c0-.042.001-.084.004-.126v-.726c0-1.9 1.652-2.23 2.496-2.157l.028.028v-16.289c-.402-.024-2.165-.23-2.524-2.02v-.973A2.039 2.039 0 0 1 1 214.62v-47.611c0-.042.001-.084.004-.126v-.726c0-1.9 1.652-2.23 2.496-2.157l.028.028v-26.041a2.26 2.26 0 0 0 .093-.236l-.064-.01a3.337 3.337 0 0 1-.72-.12l-.166-.028A2 2 0 0 1 1 135.62v-24.611a2 2 0 0 1 1.671-1.973l.857-.143v-44.68C3.528 22.99 25.53 1 66.75 1h233.341ZM3.952 234.516a5.481 5.481 0 0 0-.229-.278c.082.071.159.163.228.278Zm89.99-206.304A4.213 4.213 0 0 0 89.727 24H56.864C38.714 24 24 38.708 24 56.852v618.296C24 693.292 38.714 708 56.864 708h250.272c18.15 0 32.864-14.708 32.864-32.852V56.852C340 38.708 325.286 24 307.136 24h-32.864a4.212 4.212 0 0 0-4.213 4.212v2.527c0 10.235-8.3 18.532-18.539 18.532H112.48c-10.239 0-18.539-8.297-18.539-18.532v-2.527Z"
    />
    <rect x="154" y="29" width="56" height="5" rx="2.5" fill="#3b3b3b" />
  </svg>
);

interface DeviceFrameProps {
  children: React.ReactNode;
  className?: string;
}

const DeviceFrame: React.FC<DeviceFrameProps> = ({ children, className }) => (
  <div className={cx(`relative mx-auto w-full max-w-[366px]`, className)}>
    <BackgroundDecoration />
    <div className="relative aspect-[366/729]">
      <div className="absolute inset-y-[calc(1/729*100%)] right-[calc(5/729*100%)] left-[calc(7/729*100%)] rounded-[calc(58/366*100%)/calc(58/729*100%)] shadow-2xl" />
      <div className="absolute top-[calc(23/729*100%)] left-[calc(23/366*100%)] grid h-[calc(686/729*100%)] w-[calc(318/366*100%)] transform grid-cols-1 overflow-hidden rounded-[calc(36/366*100%)/calc(36/729*100%)] bg-slate-900">
        {children}
      </div>
      <PhoneFrameSVG />
    </div>
  </div>
);

interface DeviceFrameWithMaskProps {
  children: React.ReactNode;
  background: BackgroundColor;
  showMask?: boolean;
}

const DeviceFrameWithMask: React.FC<DeviceFrameWithMaskProps> = ({
  children,
  background,
  showMask = true,
}) => {
  const gradientColors: Record<BackgroundColor, string> = {
    violet: `from-violet-500`,
    fuchsia: `from-fuchsia-500`,
    slate: `from-slate-900`,
    white: `from-white`,
    gradient: `from-fuchsia-500`,
    green: `from-green-700`,
  };

  return (
    <div className="relative h-[420px] xs:h-[480px] sm:h-[520px] lg:h-auto overflow-hidden">
      {showMask && (
        <div
          className={cx(
            `lg:hidden absolute bottom-0 inset-x-0 h-44 pointer-events-none z-10`,
            `bg-gradient-to-t to-transparent`,
            gradientColors[background],
          )}
        />
      )}
      <DeviceFrame>{children}</DeviceFrame>
    </div>
  );
};

interface DeviceMockupBlockProps {
  children: React.ReactNode;
  deviceContent: React.ReactNode;
  devicePosition?: `left` | `right`;
  background?: BackgroundColor;
  className?: string;
  deviceBleeds?: boolean;
}

const DeviceMockupBlock: React.FC<DeviceMockupBlockProps> = ({
  children,
  deviceContent,
  devicePosition = `right`,
  background = `violet`,
  className,
  deviceBleeds = false,
}) => {
  const bgClasses: Record<BackgroundColor, string> = {
    violet: `bg-violet-500`,
    fuchsia: `bg-fuchsia-500`,
    slate: `bg-slate-900`,
    white: `bg-white`,
    gradient: `bg-gradient-to-b from-violet-500 to-fuchsia-500`,
    green: `bg-gradient-to-b from-green-600 to-green-700`,
  };

  const gradientColors: Record<BackgroundColor, string> = {
    violet: `from-violet-500`,
    fuchsia: `from-fuchsia-500`,
    slate: `from-slate-900`,
    white: `from-white`,
    gradient: `from-fuchsia-500`,
    green: `from-green-700`,
  };

  return (
    <section
      className={cx(
        `overflow-hidden relative`,
        deviceBleeds
          ? `pt-20 sm:pt-28 lg:pt-32 pb-0 lg:pb-32`
          : `py-20 sm:py-28 lg:py-32`,
        bgClasses[background],
        className,
      )}
    >
      {deviceBleeds && (
        <div
          className={cx(
            `lg:hidden absolute bottom-0 inset-x-0 h-44 pointer-events-none z-10`,
            `bg-gradient-to-t to-transparent`,
            gradientColors[background],
          )}
        />
      )}
      <div className="mx-auto max-w-7xl px-4 xs:px-8 sm:px-12 md:px-20">
        <div className="lg:grid lg:grid-cols-12 lg:gap-x-12 lg:gap-y-20 items-center">
          <div
            className={cx(
              `relative z-10 mx-auto max-w-2xl lg:max-w-none lg:pt-6`,
              devicePosition === `right`
                ? `lg:col-span-7 xl:col-span-6`
                : `lg:col-span-7 xl:col-span-6 lg:order-2`,
            )}
          >
            {children}
          </div>
          <div
            className={cx(
              `relative mt-10 sm:mt-16 lg:mt-0`,
              devicePosition === `right`
                ? `lg:col-span-5 xl:col-span-6`
                : `lg:col-span-5 xl:col-span-6 lg:order-1`,
            )}
          >
            <DeviceFrameWithMask background={background} showMask={!deviceBleeds}>
              {deviceContent}
            </DeviceFrameWithMask>
          </div>
        </div>
      </div>
    </section>
  );
};

export default DeviceMockupBlock;
export { DeviceFrame, DeviceFrameWithMask };
