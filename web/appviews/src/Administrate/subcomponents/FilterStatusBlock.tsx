import { Button, SelectMenu } from '@shared/components';
import React from 'react';
import type { FilterState } from '../../MenuBar/menubar-store';
import type { AppEvent, ViewAction } from '../administrate-store';

interface Props {
  filterState: FilterState;
  filterSuspensionDurationInSeconds: string;
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
}

const FilterStatusBlock: React.FC<Props> = ({
  filterState,
  emit,
  dispatch,
  filterSuspensionDurationInSeconds,
}) => {
  const filter = filterProps(filterState);
  return (
    <div className="bg-white dark:bg-slate-800/50 rounded-xl shadow border-slate-200 dark:border-slate-700 border-[0.5px] flex-grow">
      <div className="p-4 flex justify-between items-center">
        <div className="flex items-center space-x-2">
          <div className={`${filter.currentStatusBgColor} w-3 h-3 rounded-full`} />
          <h3 className="text-slate-800 dark:text-slate-100 font-bold text-xl">
            Filter is {filterState.case}
          </h3>
        </div>
        <Button
          type="button"
          onClick={() => emit(filter.action)}
          color={filter.actionButtonColor}
          size="small"
        >
          {filter.actionButtonText} filter
        </Button>
      </div>
      <div className="p-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-xl flex space-x-4 items-center">
        <Button
          type="button"
          onClick={() =>
            emit({
              case: `suspendFilterClicked`,
              durationInSeconds: Number(filterSuspensionDurationInSeconds),
            })
          }
          color="tertiary"
          size="small"
          disabled={filterState.case !== `on`}
        >
          Suspend filter
        </Button>
        <SelectMenu
          disabled={filterState.case !== `on`}
          size="small"
          options={[
            { value: String(5 * 60), display: `for 5 minutes` },
            { value: String(10 * 60), display: `for 10 minutes` },
            { value: String(30 * 60), display: `for 30 minutes` },
            { value: String(60 * 60), display: `for 1 hour` },
            { value: String(60 * 60 * 3), display: `for 3 hours` },
          ]}
          selectedOption={filterSuspensionDurationInSeconds}
          setSelected={(value) =>
            dispatch({
              type: `filterSuspensionDurationInSecondsChanged`,
              value,
            })
          }
        />
      </div>
    </div>
  );
};

export default FilterStatusBlock;

function filterProps(state: FilterState): {
  currentStatusBgColor: string;
  actionButtonColor: 'warning' | 'primary' | 'secondary';
  actionButtonText: 'Start' | 'Stop' | 'Resume';
  action: AppEvent;
} {
  switch (state.case) {
    case `off`:
      return {
        currentStatusBgColor: `bg-red-500`,
        actionButtonColor: `primary`,
        actionButtonText: `Start`,
        action: { case: `startFilterClicked` },
      };
    case `on`:
      return {
        currentStatusBgColor: `bg-green-500`,
        actionButtonColor: `warning`,
        actionButtonText: `Stop`,
        action: { case: `stopFilterClicked` },
      };
    case `suspended`:
      return {
        currentStatusBgColor: `bg-yellow-500`,
        actionButtonColor: `primary`,
        actionButtonText: `Resume`,
        action: { case: `resumeFilterClicked` },
      };
  }
}
