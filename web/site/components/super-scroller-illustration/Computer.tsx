import React from 'react';
import cx from 'classnames';

const Computer: React.FC<{ children: React.ReactNode; className: string }> = ({
  children,
  className,
}) => (
  <div className={cx(`[perspective:1200px]`, className)}>
    <div className="w-128 h-96 border-8 border-black rounded-t-3xl bg-black overflow-hidden">
      {children}
    </div>
    <div className="w-[592px] h-96 bg-gradient-to-b from-slate-700 to-slate-600 [transform:rotateX(80deg)] absolute -left-[40px] top-[255px] flex flex-col p-8 pb-4 gap-1">
      <div className="flex justify-center gap-1">
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        <Key grow />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key grow />
      </div>
      <div className="flex justify-center gap-1">
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key grow />
        <Key />
        <Key />
        <Key />
        <Key />
        <Key />
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

export default Computer;
