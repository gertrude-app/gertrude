import cx from 'classnames';
import React from 'react';

interface ComputerProps {
  children: React.ReactNode;
  className: string;
  labelStatus: `hidden` | `prominent` | `subtle`;
}

const Computer: React.FC<ComputerProps> = ({ children, className, labelStatus }) => (
  <div className={cx(`[perspective:1200px]`, className)}>
    <div
      className={cx(
        `absolute flex justify-center items-center transition-all duration-700`,
        {
          '-top-20 opacity-0 w-0 h-12 xscale-0 rounded-full left-[252px]':
            labelStatus === `hidden`,
          '-top-20 w-56 h-12 rounded-full left-[140px] delay-500':
            labelStatus === `prominent`,
          '-top-10 w-52 h-7 rounded-full left-[148px]': labelStatus === `subtle`,
        },
      )}
    >
      <div
        className={cx(
          `w-4 h-4 absolute rotate-45 rounded transition-[bottom,background-color] duration-500`,
          labelStatus === `prominent`
            ? `-bottom-1.5 delay-700 bg-fuchsia-500 `
            : `bottom-1 bg-fuchsia-100`,
        )}
      />
      <span
        className={cx(
          `font-medium text-lg transition-all duration-300 text-center relative w-full h-full flex justify-center items-center rounded-full`,
          {
            'text-transparent bg-fuchsia-500': labelStatus === `hidden`,
            'text-white delay-[800ms] bg-fuchsia-500': labelStatus === `prominent`,
            'scale-90 bg-fuchsia-200 text-fuchsia-700': labelStatus === `subtle`,
          },
        )}
      >
        Your child's computer
      </span>
    </div>
    <div className="w-128 h-96 border-8 border-black rounded-t-3xl bg-black overflow-hidden">
      {children}
    </div>
    <div className="w-[592px] h-96 bg-gradient-to-b from-slate-700 to-slate-600 [transform:rotateX(80deg)] absolute -left-[40px] top-[255px] flex flex-col p-8 pb-4 gap-1">
      <div className="flex justify-center gap-1">{keys(14)}</div>
      <div className="flex justify-center gap-1">
        <Key grow />
        {keys(12)}
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        {keys(13)}
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        {keys(11)}
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        {keys(10)}
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        {keys(5)}
        <Key grow />
        {keys(5)}
      </div>
      <div className="w-40 h-28 rounded-lg bg-slate-500 self-center mt-4" />
    </div>
    <div className="w-[702px] h-6 absolute bg-slate-700 rounded-b-xl z-50 top-[534px] -left-[95px]" />
  </div>
);

const Key: React.FC<{ className?: string; grow?: boolean }> = ({ className, grow }) => (
  <div
    className={cx(`w-8 h-8 bg-black rounded-md`, className)}
    style={{
      flexGrow: grow ? 100 : 1,
    }}
  />
);

function keys(count: number): React.ReactNode[] {
  return Array.from({ length: count }, (_, i) => <Key key={i} />);
}

export default Computer;
