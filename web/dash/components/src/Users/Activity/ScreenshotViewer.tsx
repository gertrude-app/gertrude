import { isScreenshotTest } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import ActivityItemBtns from './ActivityItemBtns';

type Props = {
  className?: string;
  url: string;
  width: number;
  height: number;
  flagged: boolean;
  onApprove(): unknown;
  onFlag(): unknown;
  date: Date;
  duringSuspension: boolean;
};

const ScreenshotViewer: React.FC<Props> = ({
  url,
  className,
  date,
  width,
  height,
  flagged,
  onFlag,
  onApprove,
  duringSuspension,
}) => (
  <div
    className={cx(
      `md:shadow-lg md:shadow-slate-300/50 max-w-7xl bg-white border-slate-200 rounded-2xl border-[0.5px]`,
      !duringSuspension && `!border-x-0 md:!border-x-[0.5px]`,
      className,
    )}
  >
    <div className={cx(`md:mx-4 mb-3 sm:mb-0 md:mt-4 flex justify-center rounded-xl`)}>
      <img
        className="rounded-t-2xl md:rounded-b-2xl shadow-inner w-full md:w-auto"
        src={url}
        width={width}
        height={height}
        loading={isScreenshotTest() ? `eager` : `lazy`}
        alt="child screenshot"
      />
    </div>
    <ActivityItemBtns
      className="px-4 py-3 sm:py-4 pt-0"
      flagged={flagged}
      date={date}
      onApprove={onApprove}
      onFlag={onFlag}
    />
  </div>
);

export default ScreenshotViewer;
