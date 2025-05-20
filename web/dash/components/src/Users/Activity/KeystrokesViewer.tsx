import React from 'react';
import cx from 'classnames';
import ActivityItemBtns from './ActivityItemBtns';

type Props = {
  className?: string;
  strokes: string;
  flagged: boolean;
  date: Date;
  onApprove(): unknown;
  onFlag(): unknown;
  application: string;
  duringSuspension: boolean;
};

const KeystrokesViewer: React.FC<Props> = ({
  className,
  strokes,
  date,
  application,
  flagged,
  onApprove,
  onFlag,
  duringSuspension,
}) => (
  <div
    className={cx(
      `border-y-[0.5px] border-x-[0.5px] rounded-2xl md:shadow-lg md:shadow-slate-300/50 bg-white max-w-7xl border-slate-200`,
      !duringSuspension && `!border-x-0 md:!border-x-[0.5px]`,
      className,
    )}
  >
    <h2 className="text-slate-600 font-medium -ml-0.5 pt-2 px-5">
      Application: <span className="font-bold text-violet-700">{application}</span>
    </h2>
    <div className="bg-gradient-to-b from-slate-900 to-slate-800 text-slate-400 p-4 xs:p-6 mt-2 sm:mt-3 mb-4 mx-2 md:mx-4 rounded-xl font-mono overflow-x-auto">
      {strokes.split(`\n`).map((line, idx) => (
        <p key={`line-${idx}`}>{line}</p>
      ))}
    </div>
    <ActivityItemBtns
      className="p-4 pt-0"
      flagged={flagged}
      date={date}
      onApprove={onApprove}
      onFlag={onFlag}
    />
  </div>
);

export default KeystrokesViewer;
