import React from 'react';
import cx from 'classnames';

interface PhoneProps {
  children: React.ReactNode;
  className: string;
  labelStatus: 'hidden' | 'prominent' | 'subtle';
}

const Phone: React.FC<PhoneProps> = ({ children, className, labelStatus }) => (
  <div
    className={cx(`border-8 border-black rounded-[36px] w-80 h-152 relative`, className)}
  >
    <div
      className={cx(
        `absolute flex justify-center items-center transition-all duration-700`,
        {
          '-top-20 opacity-0 w-0 h-12 xscale-0 rounded-full left-[156px]':
            labelStatus === `hidden`,
          '-top-20 w-40 h-12 rounded-full left-[76px] delay-500':
            labelStatus === `prominent`,
          '-top-12 w-32 h-7 rounded-full left-[92px]': labelStatus === `subtle`,
        },
      )}
    >
      <div
        className={cx(
          `w-4 h-4 absolute rotate-45 rounded transition-[bottom,background-color] duration-500`,
          labelStatus === `prominent`
            ? `-bottom-1.5 delay-700 bg-violet-500 `
            : `bottom-1 bg-violet-100`,
        )}
      />
      <span
        className={cx(
          `font-medium text-lg transition-all duration-300 text-center relative w-full h-full flex justify-center items-center rounded-full`,
          {
            'text-transparent bg-violet-500': labelStatus === `hidden`,
            'text-white delay-700 bg-violet-500': labelStatus === `prominent`,
            'scale-90 bg-violet-200 text-violet-700': labelStatus === `subtle`,
          },
        )}
      >
        Your device
      </span>
    </div>
    <div className="w-1 h-12 bg-black rounded-r absolute -right-3 top-36" />
    <div className="w-1 h-12 bg-black rounded-l absolute -left-3 top-36" />
    <div className="w-1 h-12 bg-black rounded-l absolute -left-3 top-52" />
    <div className="w-24 h-7 rounded-full bg-black absolute left-[calc(50%-44px)] top-2 z-50" />
    <div className="w-24 h-1.5 rounded-full bg-black/60 absolute left-[calc(50%-44px)] bottom-2 z-30" />
    <div className="w-full h-full overflow-hidden rounded-[28px] bg-black relative">
      {children}
    </div>
  </div>
);

export default Phone;
