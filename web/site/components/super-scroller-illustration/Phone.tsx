import React from 'react';
import cx from 'classnames';

const Phone: React.FC<{ children: React.ReactNode; className: string }> = ({
  children,
  className,
}) => (
  <div
    className={cx(`border-8 border-black rounded-[36px] w-80 h-152 relative`, className)}
  >
    <div className="w-1 h-12 bg-black rounded-r absolute -right-3 top-36" />
    <div className="w-1 h-12 bg-black rounded-l absolute -left-3 top-36" />
    <div className="w-1 h-12 bg-black rounded-l absolute -left-3 top-52" />
    <div className="w-24 h-7 rounded-full bg-black absolute left-[calc(50%-44px)] top-2 z-50" />
    <div className="w-24 h-1.5 rounded-full bg-black/60 absolute left-[calc(50%-44px)] bottom-2 z-30" />
    <div className="w-full h-full overflow-hidden rounded-[28px] bg-black">
      {children}
    </div>
  </div>
);

export default Phone;
