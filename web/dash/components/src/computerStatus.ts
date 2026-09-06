import type { ChildComputerStatus } from '@dash/types';

const priority: Record<ChildComputerStatus[`case`], number> = {
  filterOff: 6,
  unfiltered: 5,
  filterSuspended: 4,
  downtimePaused: 3,
  downtime: 2,
  filterOn: 1,
  offline: 0,
};

export function consolidatedComputerStatus(
  statuses: ChildComputerStatus[],
): ChildComputerStatus {
  return statuses.reduce<ChildComputerStatus>(
    (selected, status) => {
      if (priority[status.case] !== priority[selected.case]) {
        return priority[status.case] > priority[selected.case] ? status : selected;
      }
      return statusEnd(status) > statusEnd(selected) ? status : selected;
    },
    { case: `offline` },
  );
}

function statusEnd(status: ChildComputerStatus): string {
  switch (status.case) {
    case `filterSuspended`:
    case `downtimePaused`:
      return status.resuming ?? ``;
    case `downtime`:
      return status.ending ?? ``;
    default:
      return ``;
  }
}
