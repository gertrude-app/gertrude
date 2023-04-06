import { Button, SelectMenu } from '@shared/components';
import React from 'react';

interface Props {
  filterStatus: 'on' | 'off' | 'suspended';
}

const FilterStatusBlock: React.FC<Props> = ({ filterStatus }) => {
  let filterIndicatorColor = `bg-green-500`;
  let setFilterButtonColor: 'warning' | 'primary' | 'secondary' = `warning`;
  let setFilterButtonText = `Stop`;
  switch (filterStatus) {
    case `off`:
      filterIndicatorColor = `bg-red-500`;
      setFilterButtonColor = `primary`;
      setFilterButtonText = `Start`;
      break;
    case `suspended`:
      filterIndicatorColor = `bg-yellow-500`;
      setFilterButtonColor = `primary`;
      setFilterButtonText = `Resume`;
      break;
  }

  return (
    <div className="bg-white dark:bg-slate-800/50 rounded-xl shadow border-slate-200 dark:border-slate-700 border-[0.5px] flex-grow">
      <div className="p-4 flex justify-between items-center">
        <div className="flex items-center space-x-2">
          <div className={`${filterIndicatorColor} w-3 h-3 rounded-full`} />
          <h3 className="text-slate-800 dark:text-slate-100 font-bold text-xl">
            Filter is {filterStatus}
          </h3>
        </div>
        <Button
          type="button"
          onClick={() => {}}
          color={setFilterButtonColor}
          size="small"
        >
          {setFilterButtonText} filter
        </Button>
      </div>
      <div className="p-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-xl flex space-x-4 items-center">
        <Button
          type="button"
          onClick={() => {}}
          color="tertiary"
          size="small"
          disabled={filterStatus !== `on`}
        >
          Suspend filter
        </Button>
        <SelectMenu
          size="small"
          options={[
            { value: `5`, display: `for 5 minutes` },
            { value: `10`, display: `for 10 minutes` },
            { value: `30`, display: `for 30 minutes` },
            { value: `60`, display: `for 1 hour` },
          ]}
          selectedOption={``}
          setSelected={() => {}}
        />
      </div>
    </div>
  );
};

export default FilterStatusBlock;
