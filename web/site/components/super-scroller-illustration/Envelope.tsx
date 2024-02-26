import React from 'react';
import cx from 'classnames';

interface Props {
  className: string;
}

const Envelope: React.FC<Props> = ({ className }) => (
  <div
    className={cx(
      `absolute w-48 h-24 bg-slate-50 border-[0.5px] border-slate-200 shadow-md rounded-lg shadow-slate-300/40 overflow-hidden`,
      className,
    )}
  >
    <div className="w-28 h-1 bg-slate-200 absolute rotate-[20deg] top-[24px] -left-[12px]" />
    <div className="w-28 h-1 bg-slate-200 absolute -rotate-[20deg] top-[24px] -right-[12px]" />
  </div>
);

export default Envelope;
