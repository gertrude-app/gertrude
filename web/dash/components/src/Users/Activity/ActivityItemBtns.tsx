import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import ActivityItemTime from './ActivityItemTime';

interface Props {
  className?: string;
  flagged: boolean;
  date: Date;
  onApprove(): unknown;
  onFlag(): unknown;
}

const ActivityItemBtns: React.FC<Props> = ({
  className,
  onFlag,
  onApprove,
  flagged,
  date,
}) => (
  <div className={cx(`flex justify-between items-center`, className)}>
    <ActivityItemTime date={date} />
    <div className="flex gap-2">
      <div
        data-tooltip-id="flag-activity"
        data-tooltip-content={
          flagged
            ? `Flagged: won’t be deleted until unflagged`
            : `Flag to prevent deletion for 60 days`
        }
      >
        <Button color={flagged ? `warning` : `tertiary`} type="button" onClick={onFlag}>
          <i className="fas fa-flag" />
        </Button>
      </div>
      <Button disabled={flagged} color="tertiary" type="button" onClick={onApprove}>
        <span className="hidden sm-inline"> Delete</span>
        <span className="sm-hidden">
          <i className="fas fa-trash" />
        </span>
      </Button>
    </div>
  </div>
);

export default ActivityItemBtns;
